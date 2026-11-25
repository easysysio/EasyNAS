package EasyNAS::Controller::Filesystem;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;

my $conf_cron=get_conf_cron();
# The outcome of the last action, also read by the setup wizard (wizard.pm),
# which runs the same create functions.
our $msg;
our $result;
my $addon = get_addon_info("filesystem");
my %TEXT=get_lang_text($addon->{'name'});

####### input validation #######
# Every action interpolates the fs name (and often the uuid) into sudo shell
# commands, mountpoint paths and sed patterns -- restrict them to safe shapes
# before anything runs. On failure these set the standard fail message.
sub valid_fs {
 my $fs=shift;
 return 1 if (defined $fs && $fs =~ /^[A-Za-z0-9_-]{1,64}$/);
 $result="fail";
 $msg=$TEXT{'fs_invalid_name'} || "Invalid file system name.";
 return 0;
}
sub valid_uuid {
 my $uuid=shift;
 return 1 if (defined $uuid && $uuid =~ /^[0-9a-fA-F-]{8,40}$/);
 $result="fail";
 $msg=$TEXT{'fs_invalid_name'} || "Invalid identifier.";
 return 0;
}

####### build_mount_opts #######
# One canonical mount-option builder for create + change-settings, from only
# the parts that are set: no empty ",," (mount rejects it) and no bogus
# "compress=none" (not a valid kernel option). Compression is whitelisted --
# the value reaches fstab and a shell command.
sub build_mount_opts {
 my ($access,$compress,$ssd,$defrag)=@_;
 my @opt;
 push @opt, (defined $access && $access eq "readonly") ? "ro" : "rw";
 push @opt, "compress=$compress"
   if (defined $compress && $compress =~ /^(?:lzo|zlib|zstd)$/);
 push @opt, "ssd", "discard", "noatime" if ($ssd);
 push @opt, "autodefrag"                if ($defrag);
 return join(",", @opt);
}

####### fstab_remove #######
# Remove the lines that name this mountpoint (" /mnt/<fs> ") from a file the
# root helper manages (/etc/fstab, easynas.cron). 1 when done.
sub fstab_remove {
 my ($fs,$file)=@_;
 my $mount_dir=get_mount_dir();
 my $text=root_read($file);
 return 0 unless defined $text;
 my $kept=join('', grep { !/ \Q$mount_dir\/$fs\E / } split /^/, $text);
 return 1 if $kept eq $text;
 return root_write($file,$kept);
}

####### fstab_add #######
# The pool's line in /etc/fstab, by label (it can't come out empty, and it
# survives device reshuffles). 1 when done.
sub fstab_add {
 my ($fs,$optstr)=@_;
 my $mount_dir=get_mount_dir();
 return root_append("/etc/fstab","LABEL=$fs $mount_dir/$fs btrfs $optstr 0 0\n");
}

####### fs_do #######
# A change through the root helper; on failure log what it said and set the
# page's fail message. 1 when done.
sub fs_do {
 my ($what,$fail,@args)=@_;
 my ($ok,$out)=root_do(@args);
 return 1 if $ok;
 $out =~ s/\s+/ /g;
 write_log("filesystem","ERROR","$what failed: $out");
 $result="fail";
 $msg=$fail;
 return 0;
}

####### fs_op_info #######
# The background operation on a filesystem, as (type, percent, paused):
# ("balance", 42, 0), ("scrub", 10, 0), ("replace", 55, 0), or () when idle.
# A paused balance still counts as an operation (the array is mid-rewrite).
sub fs_op_info {
 my $fs=shift;
 return () unless (mounted($fs) eq "Mounted");
 my $mount=fs_mount($fs);
 my $out=root_query('status','balance',$mount);
 if ($out =~ /running|paused/i) {
  my $pct=($out =~ /(\d+)% left/) ? (100-$1) : "";
  return ("balance",$pct,($out =~ /paused/i) ? 1 : 0);
 }
 $out=root_query('status','scrub',$mount);
 if ($out =~ /running/i) {
  my $pct=($out =~ /\(([\d.]+)%\)/) ? int($1) : "";
  return ("scrub",$pct,0);
 }
 $out=root_query('status','replace',$mount);
 if ($out =~ /([\d.]+)% done/ && $out !~ /finished|never started|canceled/i) {
  return ("replace",int($1),0);
 }
 return ();
}

####### fs_running_op #######
# Human-readable form of fs_op_info -- "balance 42%", "scrub (paused)" -- or
# "" when idle. Drives the in-progress badge and the deny_if_op lock.
sub fs_running_op {
 my $fs=shift;
 my ($type,$pct,$paused)=fs_op_info($fs);
 return "" unless (defined $type);
 my $s=$type;
 $s.=" $pct%" if ($pct ne "");
 $s.=" (paused)" if ($paused);
 return $s;
}

####### deny_if_op #######
# Refuse an action while a balance/scrub/replace runs on the filesystem --
# device operations rewrite the array and must not be stacked or reconfigured
# mid-flight. Sets the standard fail message; returns 1 when denied.
sub deny_if_op {
 my $fs=shift;
 my $op=fs_running_op($fs);
 return 0 if ($op eq "");
 $result="fail";
 $msg=($TEXT{'fs_op_running'} || "A background operation is running on this filesystem; settings are locked until it finishes")." ($op)";
 return 1;
}


sub view($self) {
    if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
    }
    my $action=$self->param('action'); 
    $msg="";
    $result="";
    $self->stash(addon => $addon,
                TEXT =>\%TEXT);


#--------- createfs ----------
    if (defined $action && $action eq "createfs") {
      &createfs($self);
    }


#---------deletefs ----------
    if (defined $action && $action eq "deletefs") {
      &deletefs($self);
    }       
        

#-------- Unmount ---------
    if (defined $action && $action eq "unmount") {
        &unmount($self);
    }

#-------- mount ---------
    if (defined $action && $action eq "mount") {
        &mount($self);
    }


#------- changesettings -------
   if (defined $action && $action eq "changesettings") {
        &changesettings($self);
    }

#-------ChangeName -------
   if (defined $action && $action eq "changename")  {
     &changename($self);
   }

#-------ChangeRaid -------
   if (defined $action && $action eq "changeraid")  {
     &changeraid($self);
   }

#------- Balance / Scrub (whole filesystem) -------
   if (defined $action && $action eq "Balance") { &balance($self); }
   if (defined $action && $action eq "Scrub")   { &scrub($self);   }

#------- Pause / Resume / Stop a running operation -------
   if (defined $action && $action =~ /^(pauseop|resumeop|stopop)$/) {
     &opcontrol($self,$action);
     # Pause/resume keep the operation alive -- land back on its progress
     # view; stop falls through to the filesystem list.
     my $opfs=$self->param("fs");
     if ($action ne "stopop" && defined $opfs
         && $opfs =~ /^[A-Za-z0-9_-]{1,64}$/ && fs_running_op($opfs) ne "") {
       $self->redirect_to("/filesystem?action=progress&fs=$opfs");
       return;
     }
   }

#------- Operation progress view -------
# Clicking a filesystem that has a balance/scrub/replace running lands here
# (instead of the locked settings page): a live progress bar with
# pause/resume/stop controls, auto-refreshing until the operation ends.
   if (defined $action && $action eq "progress") {
     my $fs=$self->param("fs");
     if (valid_fs($fs)) {
       my ($type,$pct,$paused)=fs_op_info($fs);
       if (defined $type) {
         $self->stash(fs_name => $fs, op_type => $type,
                      op_pct => $pct, op_paused => $paused,
                      result => $result, msg => $msg);
         $self->render(template => 'easynas/filesystem_progress');
         return;
       }
       # Operation finished -- fall through to the normal list.
     }
   }

#------- Per-disk actions -------
   if (defined $action && $action eq "removehd")  { &removehd($self);  }
   if (defined $action && $action eq "repairhd")  { &repairhd($self);  }
   if (defined $action && $action eq "addhd")     { &addhd($self);     }
   if (defined $action && $action eq "replacehd") { &replacehd($self); }

#------- Add / Replace disk selection menu -------
   if (defined $action && $action eq "display") {
     my $menu=$self->param("menu") // "";
     if ($menu eq "add_hd" || $menu eq "exchange") {
       my $fs=$self->param("fs");
       my $uuid=$self->param("uuid");
       my $olddisk=$self->param("disk");
       my %disks=disk_info();
       my @free_disks;
       foreach (sort(keys(%disks))) {
         push(@free_disks,$_." ".$disks{$_}[2]) if ($disks{$_}[3] eq "disk_free");
       }
       if (!@free_disks) {
         $result="fail";
         $msg=$TEXT{'no_free_disk'};
       }
       else {
         $self->stash(mode => ($menu eq "add_hd" ? "add" : "replace"),
                      fs_name => $fs, uuid => $uuid, olddisk => $olddisk,
                      freedisks => \@free_disks);
         $self->render(template => 'easynas/filesystem_disk');
         return;
       }
     }
   }



#--------- Create Menu ----------
    if (defined $action && $action eq "createfsmenu") {
      my %disks = disk_info();
      my $size;
      my $number_free = 0;  
      my @free_disks; 
      my %raid;

      foreach (sort(keys(%disks)))
      {
        if ($disks{$_}[3] eq "disk_free")
        {
            $size=$disks{$_}[2];
            push(@free_disks,$_." ".$size);
            $number_free++;
        }
      }
      if ($number_free eq 0)
      {
	$result="fail";     
	$msg=$TEXT{'no_free_disk'};
      }
      else 
      {
        $self->stash(freedisks => \@free_disks,
	             numberoffree => $number_free);
        $self->render(template => 'easynas/filesystem_create');
        return;
      }	
    }

#--------- settingsmenu ---------
    if (defined $action && $action eq "settingsmenu") {
      my $fs=$self->param("fs");
      my $uuid=$self->param("uuid");
      # Both feed shell commands below (raid_status, btrfs show) -- on a bad
      # value fall through to the main menu with the standard fail message.
      # While a balance/scrub/replace runs, settings are locked: show the
      # operation's progress view instead.
      if (valid_fs($fs) && fs_running_op($fs) ne "") {
        $self->redirect_to("/filesystem?action=progress&fs=$fs");
        return;
      }
      if (valid_fs($fs) && (!defined $uuid || $uuid eq "" || valid_uuid($uuid))) {
      # Current RAID profile, canonicalised to the radio values (single/raidN),
      # so the RAID tab pre-selects the level the filesystem is actually on.
      my $current_raid = lc(raid_status($fs) // "");
      $current_raid = "single" if ($current_raid eq "jbod" || $current_raid eq "");
      # Current live mount options, so the Settings tab reflects the real state
      # (compression, read-only, ssd, autodefrag) instead of hardcoded defaults.
      my $mount_dir = get_mount_dir();
      my $sdir = ($fs eq "ROOT") ? "/" : "$mount_dir/$fs";
      my $opts = "";
      foreach (mount_table()) {
        my ($dev,$mp,$type,$o) = @$_;
        if ($mp eq $sdir && $type eq "btrfs") { $opts=$o; last; }
      }
      my %mopt = map { $_ => 1 } split(/,/,$opts);
      my $cur_compress = ($opts =~ /compress(?:-force)?=(\w+)/) ? $1 : "none";
      my $cur_ro     = $mopt{ro} ? 1 : 0;
      my $cur_ssd    = $mopt{ssd} ? 1 : 0;
      my $cur_defrag = $mopt{autodefrag} ? 1 : 0;
      my @disks = grep { /devid/ } root_query('btrfs-show', (defined $uuid && $uuid ne "") ? $uuid : $fs);
      my %health = health_info();
      my $number_disks = 0;
      my @fsdisks;
      # Each 'devid' line: "devid N size <size> used <used> path /dev/sdX".
      # Build one entry per real device so the Disks tab lists them all, not a
      # single hardcoded row.
      foreach (@disks)
      {
	$number_disks++;
	my (undef,$number,undef,$size,undef,$used,undef,$disk) = split(' ',$_);
	my $status = exists $health{$disk}
	             ? ($health{$disk}[0] eq 'disk_good' ? 'OK' : 'Failed')
	             : 'Used';
	push @fsdisks, { number => $number, disk => $disk,
	                 size => $size, used => $used, status => $status };
      }
      $self->stash( fs_name => $fs,
		    uuid => $uuid,
		    number_disks => $number_disks,
		    current_raid => $current_raid,
		    cur_compress => $cur_compress,
		    cur_ro => $cur_ro,
		    cur_ssd => $cur_ssd,
		    cur_defrag => $cur_defrag,
		    fsdisks => \@fsdisks);
      $self->render(template => 'easynas/filesystem_settings');
      return;
      }
    }


#------- Menu --------
   my %fs=fs_info();
   # Running balance/scrub/replace per filesystem, for the in-progress badge
   # and the pause/resume/stop action set; the page auto-refreshes while any
   # operation is active.
   my %fs_ops;
   foreach my $f (keys %fs) {
     my ($type,$pct,$paused)=fs_op_info($f);
     next unless (defined $type);
     my $label=$type; $label.=" $pct%" if ($pct ne ""); $label.=" (paused)" if ($paused);
     $fs_ops{$f}={ type=>$type, pct=>$pct, paused=>$paused, label=>$label };
   }
   $self->stash(filesystems =>\%fs);
   $self->stash(fs_ops => \%fs_ops);
   $self->stash(result => $result);
   $self->stash(msg => $msg);
   $self->render(template => 'easynas/filesystem');
}



#--------- deletefs ---------
sub deletefs($self) {
    my $mount_dir=get_mount_dir();
    my $fs         = $self->param("fs");
    my $uuid       = $self->param("uuid");
    my $disk;

    # Both values reach sudo shell commands (grep/btrfs/wipefs/rm) -- and this
    # is the one action that destroys data, so validate hardest.
    return unless valid_fs($fs);
    return unless valid_uuid($uuid);
    if ($fs eq "ROOT" || $fs eq "BOOT")
    {
	$result="fail";
	$msg=$TEXT{'reserved_fs'};
	return;
    }

    my @volumes    = (mounted($fs) eq "Mounted") ? root_query('subvolumes',"$mount_dir/$fs") : ();

    if (@volumes)
    {
	$result="fail";
	$msg=$TEXT{'fs_filesystem_contain_vol'};
	return;
    }
    if (mounted($fs) eq "Mounted")
    {
	# Plain umount, NOT lazy: wiping member devices while open files keep
	# the super alive would corrupt a filesystem that is still in use.
	return unless fs_do("deletefs: umount $mount_dir/$fs",$TEXT{'fs_failed_unmounting_fs'},'fs','umount',$fs);
    }
    # Refuse while the super is still active in the kernel (lazy-unmount
    # zombie: clean mount table, devices still claimed) -- wipefs would fail
    # or, worse, tear signatures out from under a live filesystem.
    if (-e "/sys/fs/btrfs/".lc($uuid))
    {
	$result="fail";
	$msg=$TEXT{'fs_busy'};
	return;
    }
    # The helper wipes the btrfs signature off every member device.
    return unless fs_do("deletefs: wipe $uuid",$TEXT{'fs_failed_formating_disk'},'fs','wipe',$uuid);
    fstab_remove($fs,"/etc/fstab");
    root_do('fs','rmdir',$fs);
    fstab_remove($fs,$conf_cron);
     $result="success";
     $msg=$TEXT{'fs_deleted'};
     return;
}


####### changeraid #######
# Convert an existing filesystem to a different btrfs RAID profile with an
# online 'btrfs balance ... -dconvert/-mconvert'. This rewrites every block
# group, so it can run for a long time on a full array -- kick it off detached
# (logging to /var/log/easynas/balance.log) and just report that it started.
sub changeraid($self) {
 my $fs    = $self->param("fs");
 my $raid  = $self->param("raid");
 my $force = $self->param("force");

 return unless valid_fs($fs);
 # Whitelist the target profile: this value goes into a shell command below.
 unless (defined $raid && $raid =~ /^(?:single|raid0|raid1|raid5|raid6|raid10)$/) {
   $result="fail";
   $msg="Invalid raid level.";
   return;
 }

 # A balance/convert only works on a mounted filesystem.
 if (mounted($fs) ne "Mounted") {
   $result="fail";
   $msg=$TEXT{'fs_not_mounted'} || "The filesystem must be mounted to change its RAID level.";
   return;
 }

 return if deny_if_op($fs);

 # Current profile, canonicalised to the radio values (single/raidN).
 my $current = lc(raid_status($fs));
 $current = "single" if $current eq "jbod";
 if ($current eq $raid) {
   $result="fail";
   $msg=$TEXT{'raid_the_same'};
   return;
 }

 # Changing the RAID level changes redundancy, so require an explicit confirm.
 if (!$force) {
   $result="fail";
   $msg=$TEXT{'raid_require_force'};
   return;
 }

 # Enforce the device-count minimum for the target profile.
 my @devs   = grep { /devid/ } root_query('btrfs-show',$fs);
 my $number = scalar(@devs);
 my %req = ( raid0  => [2,'raid_0_require_two'],   raid1  => [2,'raid_1_require_two'],
            raid10 => [4,'raid_10_require_four'], raid5  => [3,'raid_5_require_three'],
            raid6  => [4,'raid_6_require_four'] );
 if (exists $req{$raid} && $number < $req{$raid}[0]) {
   $result="fail";
   $msg=$TEXT{$req{$raid}[1]};
   return;
 }

 my $mount = ($fs eq "ROOT") ? "/" : get_mount_dir()."/".$fs;
 # The user already confirmed via the force checkbox (required above), so pass
 # --force to btrfs too: conversions that reduce metadata redundancy (e.g.
 # raid1 -> single) are otherwise refused with "use --force if you want this".
 return unless fs_do("changeraid $fs to $raid",$TEXT{'fs_op_ctl_failed'} || "Could not start the conversion.",
                    'fs','convert',$mount,$raid);
 $result="success";
 $msg=$TEXT{'raid_converting'}
      || "Converting the filesystem to $raid in the background. This can take a while.";
 return;
}


####### disk-action helpers #######
# Mount point for a filesystem name (ROOT lives at /).
sub fs_mount { my $fs=shift; return ($fs eq "ROOT") ? "/" : get_mount_dir()."/".$fs; }

# Guard: the device operations below all need the filesystem mounted -- and a
# name that is safe to interpolate (fs_mount feeds shell commands).
sub require_mounted {
 my $fs=shift;
 return 0 unless valid_fs($fs);
 return 1 if mounted($fs) eq "Mounted";
 $result="fail";
 $msg=$TEXT{'fs_not_mounted'} || "The filesystem must be mounted for this action.";
 return 0;
}


####### opcontrol #######
# Pause / resume / stop the operation currently running on a filesystem.
# balance supports all three; scrub and replace support cancel (a canceled
# scrub checkpoints and a later Scrub start resumes from it).
sub opcontrol {
 my ($self,$what)=@_;
 my $fs=$self->param("fs");
 return unless valid_fs($fs);
 my ($type)=fs_op_info($fs);
 if (!defined $type) {
  $result="fail";
  $msg=$TEXT{'fs_no_op'} || "No operation is running on this filesystem.";
  return;
 }
 my $mount=fs_mount($fs);
 my @do;
 if ($type eq "balance") {
  my %cmd=(pauseop=>"pause", resumeop=>"resume", stopop=>"cancel");
  @do=('fs','balance',$cmd{$what},$mount);
 }
 elsif ($what eq "stopop" && $type eq "scrub") {
  @do=('fs','scrub','cancel',$mount);
 }
 elsif ($what eq "stopop" && $type eq "replace") {
  @do=('fs','replace-cancel',$mount);
 }
 else {
  $result="fail";
  $msg=$TEXT{'fs_op_no_pause'} || "This operation can only be stopped, not paused.";
  return;
 }
 return unless fs_do("opcontrol $what ($type) on $fs",$TEXT{'fs_op_ctl_failed'} || "Could not control the operation.",@do);
 write_log("filesystem","INFO","$type $what on $fs");
 $result="success";
 $msg=$TEXT{'fs_op_ctl_done'} || "Done.";
}


####### balance #######
# Rebalance the filesystem's block groups across its devices. Long-running on a
# full array, so run detached; 'btrfs balance status <mount>' shows progress.
sub balance($self) {
 my $fs=$self->param("fs");
 return unless require_mounted($fs);
 return if deny_if_op($fs);
 my $mount=fs_mount($fs);
 return unless fs_do("balance $fs",$TEXT{'fs_op_ctl_failed'} || "Could not start the balance.",'fs','balance','start',$mount);
 $result="success";
 $msg=$TEXT{'fs_balancing'} || "Balancing the filesystem in the background.";
}


####### scrub #######
# Verify (and repair from redundancy) every block. 'scrub start' returns at once
# and runs as a background kernel task; 'btrfs scrub status' shows progress.
sub scrub($self) {
 my $fs=$self->param("fs");
 return unless require_mounted($fs);
 return if deny_if_op($fs);
 my $mount=fs_mount($fs);
 return unless fs_do("scrub $fs",$TEXT{'fs_op_ctl_failed'} || "Could not start the scrub.",'fs','scrub','start',$mount);
 $result="success";
 $msg=$TEXT{'fs_scrubbing'} || "Scrub started; the filesystem is being verified.";
}


####### repairhd #######
# btrfs has no per-disk repair -- a scrub rewrites any corrupted block from a
# good copy on the redundant devices, which is the repair path for a bad disk.
sub repairhd($self) {
 my $fs=$self->param("fs");
 return unless require_mounted($fs);
 return if deny_if_op($fs);
 my $mount=fs_mount($fs);
 return unless fs_do("repair (scrub) $fs",$TEXT{'fs_op_ctl_failed'} || "Could not start the repair.",'fs','scrub','start',$mount);
 $result="success";
 $msg=$TEXT{'fs_repairing'} || "Repair started: a scrub rebuilds bad blocks from redundancy.";
}


####### removehd #######
# Remove a device from the pool. btrfs migrates its data onto the remaining
# devices first, so this is long-running -- run detached.
sub removehd($self) {
 my $fs=$self->param("fs");
 my $disk=$self->param("disk");
 unless (defined $disk && $disk =~ m{^/dev/[A-Za-z0-9]{2,32}$}) { $result="fail"; $msg="Invalid disk."; return; }
 return unless require_mounted($fs);
 return if deny_if_op($fs);
 my $mount=fs_mount($fs);
 return unless fs_do("remove $disk from $fs",$TEXT{'fs_op_ctl_failed'} || "Could not remove the disk.",'fs','device-remove',$mount,$disk);
 $result="success";
 $msg=$TEXT{'fs_removing_disk'} || "Removing the disk in the background; its data is being migrated.";
}


####### addhd #######
# Add a free device to the pool. Adding is quick (no data moves yet); the user
# runs Balance afterward to spread existing data across the new device. The
# form's disk value is "sdX <size>", so take the first field.
sub addhd($self) {
 my $fs=$self->param("fs");
 my ($disk)=split(" ",$self->param("disk") // "");
 unless (defined $disk && $disk =~ /^[A-Za-z0-9]+$/) { $result="fail"; $msg="Invalid disk."; return; }
 return unless require_mounted($fs);
 return if deny_if_op($fs);
 my $mount=fs_mount($fs);
 return unless fs_do("add /dev/$disk to $fs",$TEXT{'fs_failed_adding_disk'} || "Failed to add the disk.",'fs','device-add',$mount,"/dev/$disk");
 $result="success";
 $msg=$TEXT{'fs_disk_added'} || "Disk added. Run Balance to spread data across it.";
}


####### replacehd #######
# Replace an existing device with a free one; btrfs copies the old device's
# contents onto the new one -- long-running, so run detached. olddisk is a
# /dev path; the new disk comes from the form as "sdX <size>".
sub replacehd($self) {
 my $fs=$self->param("fs");
 my $olddisk=$self->param("olddisk");
 my ($newdisk)=split(" ",$self->param("disk") // "");
 unless (defined $olddisk && $olddisk =~ m{^/dev/[A-Za-z0-9]{2,32}$}) { $result="fail"; $msg="Invalid disk."; return; }
 unless (defined $newdisk && $newdisk =~ /^[A-Za-z0-9]+$/) { $result="fail"; $msg="Invalid disk."; return; }
 return unless require_mounted($fs);
 return if deny_if_op($fs);
 my $mount=fs_mount($fs);
 return unless fs_do("replace $olddisk with /dev/$newdisk in $fs",$TEXT{'fs_op_ctl_failed'} || "Could not replace the disk.",
                    'fs','replace',$mount,$olddisk,"/dev/$newdisk");
 $result="success";
 $msg=$TEXT{'fs_replacing_disk'} || "Replacing the disk in the background.";
}


####### createfs #######
sub createfs($self) {

    my $disks      = $self->every_param("disks");
    my $fs         = $self->param("name");
    my $raid       = $self->param("raid");
    my $access     = $self->param("mount");      # "readonly" | "read&write"
    my $automount  = $self->param("automount");
    my $ssd        = $self->param("ssd");
    my $defrag     = $self->param("defrag");
    my $compress   = $self->param("compress");
    my $mount_dir=get_mount_dir();
    my @raid_disks;
    my $number     = 0;
    my $uuid;
    my $btrfs;
    my $disk;
    my $rc;
    foreach (@{$disks})
    {
	($disk,undef) = split(" ", $_);
	# Form values are "sdX <size>"; the device part must be a bare name.
	next unless (defined $disk && $disk =~ /^[A-Za-z0-9]+$/);
	push @raid_disks, "/dev/".$disk;
	$number++;
    }

    if ($number == 0)
    {
	$result="fail";
        $msg=$TEXT{'no_disks_were_selected'};
	return;
    }
    if (!defined $fs || $fs eq '')
    {
	$result="fail";
	$msg=$TEXT{'no_fs_name_was_entered'};
	return;
    }
    # The name becomes the btrfs label, a mountpoint path, a shell argument
    # and an fstab line -- same restriction as changename.
    return unless valid_fs($fs);
    if ($fs eq "ROOT" || $fs eq "BOOT")
    {
	$result="fail";
        $msg=$TEXT{'reserved_fs'};
	return;
    }
    unless (defined $raid && $raid =~ /^(?:single|raid0|raid1|raid5|raid6|raid10)$/)
    {
	$result="fail";
	$msg="Invalid raid level.";
	return;
    }

    if (($raid eq "raid0") && ($number<2))
    {
	$result="fail";    
        $msg=$TEXT{'raid_0_require_two'};
	return;
    }
    if (($raid eq "raid1") && ($number<2))
    {
	$result="fail";    
        $msg=$TEXT{'raid_1_require_two'};
	return;
    }
    if (($raid eq "raid10") && ($number<4))
    {
	$result="fail";    
        $msg=$TEXT{'raid_10_require_four'};
	return;
    }
    if (($raid eq "raid5") && ($number<3))
    {
	$result="fail";    
        $msg=$TEXT{'raid_5_require_three'};
	return;
    }
    if (($raid eq "raid6") && ($number<4))
    {
	$result="fail";    
        $msg=$TEXT{'raid_6_require_four'};
	return;
    }

    return unless fs_do("mkdir $mount_dir/$fs",$TEXT{'failed_creating_directory'},'fs','mkdir',$fs);
    # The helper checks that no disk is in use (mounted, swap, a pool's).
    return unless fs_do("mkfs.btrfs -L $fs",$TEXT{'failed_creating_fs'},'fs','mkfs',$fs,$raid,@raid_disks);

    if ($automount)
    {
	my $optstr = build_mount_opts($access,$compress,$ssd,$defrag);
	# Mount by label rather than UUID: it always resolves (the label was
	# just written by mkfs).
	unless (fstab_add($fs,$optstr)) { $result="fail"; $msg=$TEXT{'failed_mounting_fs'}; return; }
	return unless fs_do("mount $mount_dir/$fs after create",$TEXT{'failed_mounting_fs'},'fs','mount',$fs);
    }

    $result="success";
    $msg=$TEXT{'fs_created'};
    return;
}

##### unmount #####
sub unmount($self) {

    my $fs = $self->param("fs");
    my $mount_dir=get_mount_dir();

    return unless valid_fs($fs);
    if ($fs eq "ROOT" || $fs eq "BOOT")
    {
      $result="fail";
      $msg=$TEXT{'fs_failed_unmounting_fs'};
      return;
    }
    # Plain umount, NOT lazy (-l): a lazy unmount "succeeds" while open files
    # keep the super active in the kernel with every member device claimed --
    # the mount table looks clean but label/raid changes then fail with
    # "device busy" and nothing explains why. Fail honestly instead, and name
    # the processes holding files open so the user can close them.
    my ($ok,$out) = root_do('fs','umount',$fs);
    if (!$ok) {
      my $holders=join('', map { chomp; " $_" } root_query('holders',"$mount_dir/$fs"));
      write_log("filesystem","ERROR","umount $mount_dir/$fs failed: $out; holders:".($holders||" none found"));
      $result="fail";
      $msg=$TEXT{'fs_failed_unmounting_fs'}.($holders ? ":".$holders : "");
      return;
    }
#    $rc = system("/usr/bin/sudo /usr/bin/sed -i '$mount_dir.$fs /d' /etc/fstab > /dev/null");
    $result="success";
    $msg="Filesystem was unmouted";
}


######## mount ########
sub mount($self)
{
 my $fs = $self->param("fs");
 my $rc;
 my $mount_dir=get_mount_dir();

 return unless valid_fs($fs);

 # The mountpoint may not exist (fresh /mnt after an OS reinstall).
 root_do('fs','mkdir',$fs);

 # `mount <mountpoint>` needs an /etc/fstab entry to know the device. After a
 # reinstall (system disk wiped) -- or for a pool imported from another box --
 # there is none, so add one by btrfs label (the label equals the filesystem
 # name; see mkfs.btrfs -L in createfs) so it mounts now and at every boot.
 if ((root_read("/etc/fstab") // "") !~ / \Q$mount_dir\/$fs\E /) {
  fstab_add($fs,"defaults");
 }

 return unless fs_do("mount $mount_dir/$fs",$TEXT{'fs_failed_mounting'},'fs','mount',$fs);
 # Re-apply any NFS/Samba shares recorded inside the volumes of this pool
 # (their in-volume markers survive a reinstall; see rediscover_shares).
 rediscover_shares();
 $result="success";
 $msg=$TEXT{'fs_mounted'};
}


######## changesettings ########
sub changesettings($self) {
 my $fs        = $self->param("fs");
 my $compress  = $self->param("compress");
 my $access    = $self->param("mount");       # "readonly" | "read&write"
 my $ssd       = $self->param("ssd");
 my $defrag    = $self->param("defrag");
 my $automount = $self->param("automount");
 my $mount_dir = get_mount_dir;
 my $dir       = "$mount_dir/$fs";
 my $rc;

 return unless valid_fs($fs);
 return if deny_if_op($fs);
 my $optstr = build_mount_opts($access,$compress,$ssd,$defrag);

 return unless fs_do("mkdir $dir",$TEXT{'fs_failed_creating_dir'},'fs','mkdir',$fs);

 # Drop any existing fstab entry for this mountpoint, then (when auto-mount is
 # on) write the new one -- appending blindly would pile up duplicate lines.
 # Mount by label: unlike a UUID parsed from btrfs output it cannot be empty,
 # and it survives device reshuffles.
 my $fstab=root_read("/etc/fstab");
 my $new=join('', grep { !/ \Q$dir\E / } split /^/, $fstab // "");
 $new.="LABEL=$fs $dir btrfs $optstr 0 0\n" if ($automount);
 if (!defined $fstab || ($new ne $fstab && !root_write("/etc/fstab",$new))) {
  $result="fail";
  $msg=$TEXT{'fs_failed_mounting'};
  return;
 }

 # Apply live: remount in place when already mounted (you can't plain-mount an
 # already-mounted fs), otherwise a fresh mount by label (independent of the
 # fstab entry, which is only written when auto-mount is on).
 return unless fs_do("changesettings: mount $dir ($optstr)",$TEXT{'fs_failed_mounting'},
                    'fs',(mounted($fs) eq "Mounted") ? 'remount' : 'mount-label',$fs,$optstr);
 $result="success";
 $msg=$TEXT{'fs_mounted'};
}


##### changename #######
sub changename($self) {
  my $fs    = $self->param("fs");
  my $newfs = $self->param("newfs");
  # Both names reach shell commands, paths and the fstab sed below.
  return unless valid_fs($fs);
  my %fs_info=fs_info();
  my $path=$fs_info{$fs}[7];
  my $uuid=$fs_info{$fs}[0];
  my $mounted=mounted($fs);
  my $mount_dir=get_mount_dir();

  # The new label becomes a mountpoint path, a shell argument and a sed
  # pattern for fstab -- restrict it to characters safe in all three.
  if (!defined $newfs || $newfs !~ /^[A-Za-z0-9_-]+$/)
  {
   $result="fail";
   $msg=$TEXT{'fs_invalid_name'};
   return;
  }

  if ($fs eq $newfs)
  {
   $result="fail";
   $msg=$TEXT{'filesystem_not_changed'};
   return;
  }

  if ($fs eq "ROOT" || $fs eq "BOOT")
  {
   $msg=$TEXT{'filesystem_not_changed'};
   $result="fail";
   return;
  }

  if ($mounted eq "Mounted")
  {
   $msg=$TEXT{'fs_umount_first'};
   $result="fail";
   return;
  }

  # The mount table can be clean while the fs is still ACTIVE in the kernel
  # (open files after a lazy unmount keep the super alive and every member
  # device claimed); relabeling would fail with "device busy". The super is
  # active exactly when /sys/fs/btrfs/<uuid> exists.
  if (defined $uuid && $uuid ne "" && -e "/sys/fs/btrfs/$uuid")
  {
   $result="fail";
   $msg=$TEXT{'fs_busy'};
   return;
  }

  if (!defined $path || $path eq "")
  {
   write_log("filesystem","ERROR","changename: no device path known for '$fs'");
   $result="fail";
   $msg=$TEXT{'fs_failed_changing_label'};
   return;
  }

  # Capture stderr (stdout is discarded): on failure the real btrfs error
  # lands in the easynas log instead of vanishing behind a generic message.
  # The helper relabels it and renames its /mnt directory.
  return unless fs_do("relabel $fs to $newfs",$TEXT{'fs_failed_changing_label'},'fs','label',$fs,$newfs);

  # Its fstab line: the new mountpoint, and the new label to mount by.
  my $fstab=root_read("/etc/fstab");
  if (defined $fstab) {
   my $new=join('', map {
     my $l=$_;
     if ($l =~ / \Q$mount_dir\/$fs\E /) {
      $l =~ s/ \Q$mount_dir\/$fs\E / $mount_dir\/$newfs /;
      $l =~ s/^LABEL=\Q$fs\E /LABEL=$newfs /;
     }
     $l } split /^/, $fstab);
   if ($new ne $fstab && !root_write("/etc/fstab",$new)) {
    write_log("filesystem","ERROR","changename: /etc/fstab not updated for $newfs");
   }
  }
   $msg=$TEXT{'fs_name_changed'};
   $result="success";
   return;
}


1;

