package EasyNAS::Controller::Filesystem;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;

my $conf_cron=get_conf_cron();
my $msg;
my $result;
my $addon = get_addon_info("filesystem");
my %TEXT=get_lang_text($addon->{'name'});


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
      # Current RAID profile, canonicalised to the radio values (single/raidN),
      # so the RAID tab pre-selects the level the filesystem is actually on.
      my $current_raid = lc(raid_status($fs) // "");
      $current_raid = "single" if ($current_raid eq "jbod" || $current_raid eq "");
      # Current live mount options, so the Settings tab reflects the real state
      # (compression, read-only, ssd, autodefrag) instead of hardcoded defaults.
      my $mount_dir = get_mount_dir();
      my $sdir = ($fs eq "ROOT") ? "/" : "$mount_dir/$fs";
      my $opts = "";
      foreach (`/usr/bin/sudo /bin/cat /proc/mounts 2>/dev/null`) {
        my ($dev,$mp,$type,$o) = split(' ',$_);
        if (defined $mp && $mp eq $sdir && defined $type && $type eq "btrfs") { $opts=$o; last; }
      }
      my %mopt = map { $_ => 1 } split(/,/,$opts);
      my $cur_compress = ($opts =~ /compress(?:-force)?=(\w+)/) ? $1 : "none";
      my $cur_ro     = $mopt{ro} ? 1 : 0;
      my $cur_ssd    = $mopt{ssd} ? 1 : 0;
      my $cur_defrag = $mopt{autodefrag} ? 1 : 0;
      my @disks = `/usr/bin/sudo /sbin/btrfs filesystem show $uuid | /usr/bin/grep devid`;
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


#------- Menu --------    
   my %fs=fs_info();
   $self->stash(filesystems =>\%fs);
   $self->stash(result => $result);
   $self->stash(msg => $msg);
   $self->render(template => 'easynas/filesystem');
}



#--------- deletefs ---------
sub deletefs($self) {
    my $mount_dir=get_mount_dir();
    my $fs         = $self->param("fs");
    my $uuid       = $self->param("uuid");
    my $auto_mount = `/usr/bin/sudo /usr/bin/grep $uuid /etc/fstab`;
    my @disks      = `/usr/bin/sudo /sbin/btrfs filesystem show $uuid | /usr/bin/grep devid`;
    my @volumes    = `/usr/bin/sudo /sbin/btrfs subvolume list $mount_dir/$fs`;
    my $disk;
    my $id;
    my $vol;
    my $rc;

    if (@volumes)
    {
	$result="fail";
	$msg=$TEXT{'fs_filesystem_contain_vol'};	
	return;
    }
    if ($auto_mount)
    {
	`/usr/bin/sudo /usr/bin/sed -i '$mount_dir.$fs /d' /etc/fstab`;
	$rc = system("/usr/bin/sudo /usr/bin/umount -l $mount_dir/$fs > /dev/null ");
	if ($rc ne 0)
	{
	    $result="fail";
	    $msg=$TEXT{'fs_failed_unmounting_fs'};
	    return;
	}
    }
    foreach (@disks)
    {
	(undef,undef,undef,undef,undef,undef,undef,$disk) = split(" ",$_);
	$rc = system("/usr/bin/sudo /usr/sbin/wipefs -f -o 0x10040 $disk >/dev/null");
	if ($rc ne 0)
	{
           $result="fail";
	   $msg=$TEXT{'fs_failed_formating_disk'};
	   return;

	}
    }
    `/usr/bin/sudo /usr/bin/rm -fr $mount_dir/$fs`;
    `/usr/bin/sudo /usr/bin/sed -i '$mount_dir.$fs /d' $conf_cron`;
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
 my @devs   = `/usr/bin/sudo /sbin/btrfs filesystem show $fs | /usr/bin/grep devid`;
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
 system("/usr/bin/nohup /usr/bin/sudo /sbin/btrfs balance start "
       ."-dconvert=$raid -mconvert=$raid $mount "
       .">/var/log/easynas/balance.log 2>&1 &");
 $result="success";
 $msg=$TEXT{'raid_converting'}
      || "Converting the filesystem to $raid in the background. This can take a while.";
 return;
}


####### disk-action helpers #######
# Mount point for a filesystem name (ROOT lives at /).
sub fs_mount { my $fs=shift; return ($fs eq "ROOT") ? "/" : get_mount_dir()."/".$fs; }

# Guard: the device operations below all need the filesystem mounted.
sub require_mounted {
 my $fs=shift;
 return 1 if mounted($fs) eq "Mounted";
 $result="fail";
 $msg=$TEXT{'fs_not_mounted'} || "The filesystem must be mounted for this action.";
 return 0;
}


####### balance #######
# Rebalance the filesystem's block groups across its devices. Long-running on a
# full array, so run detached; 'btrfs balance status <mount>' shows progress.
sub balance($self) {
 my $fs=$self->param("fs");
 return unless require_mounted($fs);
 my $mount=fs_mount($fs);
 system("/usr/bin/nohup /usr/bin/sudo /sbin/btrfs balance start $mount >/var/log/easynas/balance.log 2>&1 &");
 $result="success";
 $msg=$TEXT{'fs_balancing'} || "Balancing the filesystem in the background.";
}


####### scrub #######
# Verify (and repair from redundancy) every block. 'scrub start' returns at once
# and runs as a background kernel task; 'btrfs scrub status' shows progress.
sub scrub($self) {
 my $fs=$self->param("fs");
 return unless require_mounted($fs);
 my $mount=fs_mount($fs);
 system("/usr/bin/sudo /sbin/btrfs scrub start $mount >/dev/null 2>&1");
 $result="success";
 $msg=$TEXT{'fs_scrubbing'} || "Scrub started; the filesystem is being verified.";
}


####### repairhd #######
# btrfs has no per-disk repair -- a scrub rewrites any corrupted block from a
# good copy on the redundant devices, which is the repair path for a bad disk.
sub repairhd($self) {
 my $fs=$self->param("fs");
 return unless require_mounted($fs);
 my $mount=fs_mount($fs);
 system("/usr/bin/sudo /sbin/btrfs scrub start $mount >/dev/null 2>&1");
 $result="success";
 $msg=$TEXT{'fs_repairing'} || "Repair started: a scrub rebuilds bad blocks from redundancy.";
}


####### removehd #######
# Remove a device from the pool. btrfs migrates its data onto the remaining
# devices first, so this is long-running -- run detached.
sub removehd($self) {
 my $fs=$self->param("fs");
 my $disk=$self->param("disk");
 unless (defined $disk && $disk =~ m{^/dev/[\w]+$}) { $result="fail"; $msg="Invalid disk."; return; }
 return unless require_mounted($fs);
 my $mount=fs_mount($fs);
 system("/usr/bin/nohup /usr/bin/sudo /sbin/btrfs device remove $disk $mount >/var/log/easynas/balance.log 2>&1 &");
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
 my $mount=fs_mount($fs);
 my $rc=system("/usr/bin/sudo /sbin/btrfs device add -f /dev/$disk $mount >/dev/null 2>&1");
 if ($rc ne 0) { $result="fail"; $msg=$TEXT{'fs_failed_adding_disk'} || "Failed to add the disk."; return; }
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
 unless (defined $olddisk && $olddisk =~ m{^/dev/[\w]+$}) { $result="fail"; $msg="Invalid disk."; return; }
 unless (defined $newdisk && $newdisk =~ /^[A-Za-z0-9]+$/) { $result="fail"; $msg="Invalid disk."; return; }
 return unless require_mounted($fs);
 my $mount=fs_mount($fs);
 system("/usr/bin/nohup /usr/bin/sudo /sbin/btrfs replace start -f $olddisk /dev/$newdisk $mount >/var/log/easynas/balance.log 2>&1 &");
 $result="success";
 $msg=$TEXT{'fs_replacing_disk'} || "Replacing the disk in the background.";
}


####### createfs #######
sub createfs($self) {

    my $disks      = $self->every_param("disks");
    my $fs         = $self->param("name");
    my $raid       = $self->param("raid");
    my $options    = $self->param("options");
    my $mount      = $self->param("mount");
    my $ssd        = $self->param("ssd");
    my $defrag     = $self->param("defrag");
    my $compress   = $self->param("compress"); 
    my $mount_dir=get_mount_dir();
    my $device     = "";
    my $raid_disks = "";
    my $number     = 0;
    my $uuid;
    my $btrfs;
    my $disk;
    my $rc;
    if ($ssd)
    {
	$ssd = "ssd,discard,noatime";
    }
    else
    {
	$ssd = "";
    }
    if ($defrag)
    {
	$defrag = "autodefrag";
    }
    else
    {
	$defrag = "";
    }
    foreach (@{$disks})
    {
	($disk,undef) = split(" ", $_);
	$raid_disks   = $raid_disks." "."/dev/".$disk;
	$device       = $device."device="."/dev/".$disk.",";
	$number++;
    }

    if ($number eq 0)
    {

	$result="fail";
        $msg=$TEXT{'no_disks_were_selected'};
	return;
    }
    if ($fs eq '')
    {
	$result="fail";    
	$msg=$TEXT{'no_fs_name_was_entered'};
	return;
    }
    if ($fs eq "ROOT" || $fs eq "BOOT")
    {
	$result="fail";    
        $msg=$TEXT{'reserved_fs'};
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

    if ( !-d "$mount_dir/$fs") { 
      $rc = system("/usr/bin/sudo /bin/mkdir $mount_dir/$fs");
      if ($rc ne 0)
      {
	$result="fail";    
        $msg=$TEXT{'failed_creating_directory'};
	return;
      }
    }
    $rc = system("/usr/bin/sudo /sbin/mkfs.btrfs -f -L $fs -d $raid -m $raid $raid_disks > /dev/null");
    if ($rc ne 0)
    {
	$result="fail";    
	$msg=$TEXT{'failed_creating_fs'};
	return;
    }

    $btrfs=`/usr/bin/sudo /usr/sbin/btrfs filesystem show $fs | /usr/bin/grep uuid`;
    (undef,undef,undef,$uuid)=split(" ",$btrfs);

    if ($mount)
    {
	`/bin/echo "UUID=$uuid $mount_dir/$fs btrfs $options,compress=$compress,$ssd,$defrag 0 0" | /usr/bin/sudo /usr/bin/tee -a /etc/fstab`;
	$rc = system("/usr/bin/sudo /usr/bin/mount -t btrfs -o $options,compress=$compress,$ssd,$defrag $mount_dir/$fs > /dev/null");
    }
    if ($rc ne 0)
    {
	$result="fail";    
        $msg=$TEXT{'failed_mounting_fs'};
	return;
    }

    $result="success";    
    $msg=$TEXT{'fs_created'};
    return;
}

##### unmount #####
sub unmount($self) {

    my $fs = $self->param("fs");
    my $mount_dir=get_mount_dir();
    my $rc;

    if ($fs eq "ROOT" || $fs eq "BOOT")
    {
      $result="fail";
      $msg=$TEXT{'fs_failed_unmounting_fs'};
      return;
    }
    $rc = system("/usr/bin/sudo /usr/bin/umount -l $mount_dir/$fs > /dev/null");
    if ($rc ne 0) {
      $result="fail";
      $msg=$TEXT{'fs_failed_unmounting_fs'};
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

 # The mountpoint may not exist (fresh /mnt after an OS reinstall).
 if ( !-d "$mount_dir/$fs") {
  system("/usr/bin/sudo /bin/mkdir -p $mount_dir/$fs > /dev/null");
 }

 # `mount <mountpoint>` needs an /etc/fstab entry to know the device. After a
 # reinstall (system disk wiped) -- or for a pool imported from another box --
 # there is none, so add one by btrfs label (the label equals the filesystem
 # name; see mkfs.btrfs -L in createfs) so it mounts now and at every boot.
 my $in_fstab = `/usr/bin/sudo /usr/bin/grep " $mount_dir/$fs " /etc/fstab 2>/dev/null`;
 if (!$in_fstab) {
  `/bin/echo "LABEL=$fs $mount_dir/$fs btrfs defaults 0 0" | /usr/bin/sudo /usr/bin/tee -a /etc/fstab > /dev/null`;
 }

 $rc = system("/usr/bin/sudo /usr/bin/mount  $mount_dir/$fs > /dev/null");
    if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{"fs_failed_mounting"};
     return;
    }
 # Re-apply any NFS/Samba shares recorded inside the volumes of this pool
 # (their in-volume markers survive a reinstall; see rediscover_shares).
 rediscover_shares();
 $result="success";
 $msg=$TEXT{'fs_mounted'};
}


######## changesettings ########
sub changesettings($self) {
 my $fs = $self->param("fs");
 my $uuid = $self->param("uuid");
 my $compress = $self->param("compress");
 my $options = $self->param("options");
 my $ssd = $self->param("ssd");
 my $defrag = $self->param("defrag");
 my $mount_dir = get_mount_dir; 
 my $rc;

 if ($ssd)
 {
  $ssd = "ssd,discard,noatime";
 }
 else 
 {
  $ssd="";
 }
 if ($defrag)
 {
  $defrag = "autodefrag";
 }
  else
 {
  $defrag = "";
 }
 if (!(-e $mount_dir/$fs))
    {
     $rc = system("/usr/bin/sudo /bin/mkdir $mount_dir/$fs");
     if ($rc ne 0)
     {
      $result="fail";
      $msg=$TEXT{'fs_failed_creating_dir'};
     }
    }
    $rc = system("/bin/echo \"UUID=$uuid $mount_dir/$fs btrfs $options,compress=$compress,$ssd,$defrag 0 0\" | /usr/bin/sudo /usr/bin/tee -a /etc/fstab > /dev/null");
    $rc = system("/usr/bin/sudo /usr/bin/mount -t btrfs -o $options,compress=$compress,,$ssd,$defrag $mount_dir/$fs > /dev/null");
    if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{"fs_failed_mounting"};
     $rc = system("/usr/bin/sudo /bin/sed -i '$mount_dir.$fs /d' /etc/fstab > /dev/null");
     return;
    }
 $result="success";
 $msg=$TEXT{'fs_mounted'};
}


##### changename #######
sub changename($self) {
  my %fs_info=fs_info();
  my $fs    = $self->param("fs");
  my $newfs = $self->param("newfs");
  my $path=$fs_info{$fs}[7];
  my $mounted=mounted($fs);
  my $mount_dir=get_mount_dir();
  my $rc;
  print $path;

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

  $rc = system("/usr/bin/sudo /sbin/btrfs filesystem label $path $newfs >/dev/null");
  if ($rc ne 0)
  {
   $msg=$TEXT{'fs_failed_changing_label'};
   $result="fail";
   return;
  }

  `/usr/bin/sudo /usr/bin/mv $mount_dir/$fs $mount_dir/$newfs`;
  `/usr/bin/sudo /usr/bin/sed -i 's%$mount_dir/$fs%$mount_dir/$newfs%g' /etc/fstab`;
   $msg=$TEXT{'fs_name_changed'};
   $result="success";
   return;
}


1;

