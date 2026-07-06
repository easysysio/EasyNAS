package EasyNAS::Controller::Samba;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("samba");
my $service = ($addon->{service});
my %TEXT=get_lang_text($addon->{'name'});

# Build a samba share section in the v1 format:
#   #### name #### / [name] / path / browsable / guest ok / read only /
#   [recycle vfs] / comment = name   (delete keys on the #### .. comment range)
sub share_section {
 my ($share,$path,$browsable,$guest,$readonly,$recycle,$group)=@_;
 my $s = "#### $share ####\n";
 $s .= "[$share]\n";
 $s .= "path = $path\n";
 $s .= "browsable = $browsable\n";
 $s .= "guest ok = $guest\n";
 $s .= "read only = $readonly\n";
 # Ownership model (docs/identity-design.md sec 4): a guest share maps everyone
 # to nobody; a group-owned share forces the directory group and limits access
 # to its members; a share with no group is left as-is (pre-realm storage).
 if ($guest eq "yes") {
  $s .= "force user = nobody\n";
  $s .= "force group = nobody\n";
 }
 elsif (defined($group) && $group ne "") {
  $s .= "force group = $group\n";
  $s .= "valid users = \@$group\n";
  $s .= "write list = \@$group\n" if ($readonly ne "yes");
 }
 if ($recycle) {
  $s .= "vfs object = recycle\n";
  $s .= "recycle:repository = recycle\n";
  $s .= "recycle:touch = Yes\n";
  $s .= "recycle:keeptree = Yes\n";
  $s .= "recycle:exclude_dir = recycle\n";
 }
 $s .= "comment = $share\n";
 return $s;
}

# Rewrite a share's ownership directives to $group (or strip them when $group is
# ""). Used by the re-ACL after a backend switch: reads the config, drops the
# old force group/valid users/write list lines in the share's section, re-adds
# them after the [share] header, and writes the file back.
sub reassign_group {
 my ($config,$share,$group,$readonly)=@_;
 my @in=`/usr/bin/sudo /bin/cat $config 2>/dev/null`;
 my @out;
 my $in=0;
 foreach my $line (@in) {
  if ($line =~ /^#### \Q$share\E ####/) { $in=1; push @out,$line; next; }
  if ($in) {
   next if $line =~ /^\s*(force group|valid users|write list)\s*=/;   # drop old
   push @out,$line;
   if ($line =~ /^\[\Q$share\E\]/ && $group ne "") {
    push @out,"force group = $group\n";
    push @out,"valid users = \@$group\n";
    push @out,"write list = \@$group\n" if ($readonly ne "yes");
   }
   $in=0 if ($line =~ /^comment\s*=\s*\Q$share\E/);                    # section end
  } else {
   push @out,$line;
  }
 }
 open(my $fh,'|-',"/usr/bin/sudo /usr/bin/tee $config > /dev/null");
 print $fh @out;
 close($fh);
}

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action');
  my $mount_dir=get_mount_dir();
  my $config=$addon->{config};
  my $rc;
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

##### sambaon #####
 if (defined($action) && $action eq "sambaon") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  `/usr/bin/sudo /usr/bin/systemctl start nmb.service`;
  `/usr/bin/sudo /usr/bin/systemctl enable nmb.service`;
  write_log($addon->{"name"},"INFO","Samba Service started");
 }

#### sambaoff #####
 if (defined($action) && $action eq "sambaoff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  `/usr/bin/sudo /usr/bin/systemctl stop nmb.service`;
  `/usr/bin/sudo /usr/bin/systemctl disable nmb.service`;
  write_log($addon->{"name"},"INFO","Samba Service stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "create") {
  my %vol = vol_info();
  my %groups = groups_info();
  $self->stash(volumes => \%vol, groups => \%groups);
  $self->render(template => 'easynas/samba_create');
  return;
 }

##### add share #####
 if (defined($action) && $action eq "add") {
  my $share=$self->param("name");
  my $vol=$self->param("vol");
  my $group=$self->param("group") // "";
  my $readonly=($self->param("readonly") // "") eq "yes" ? "yes" : "no";
  my $guest=($self->param("guest") // "") eq "yes" ? "yes" : "no";
  my $browsable=($self->param("browsable") // "") eq "yes" ? "yes" : "no";
  my $recycle=($self->param("recycle") // "") eq "yes" ? 1 : 0;
  # Only accept a group that actually resolves (via NSS); otherwise treat the
  # share as ungrouped (pre-realm) rather than write a broken force group.
  my $has_group=($guest ne "yes" && $group ne ""
                 && `/usr/bin/getent group $group 2>/dev/null` ne "");
  if (!defined($share) || $share eq "") {
   $result="fail";
   $msg=$TEXT{'samba_missing_name'};
  }
  elsif (`/usr/bin/sudo /usr/bin/grep "#### $share ####" $config 2>/dev/null`) {
   $result="fail";
   $msg=$TEXT{'samba_share_exists'};
  }
  else {
   my $path="$mount_dir/$vol";
   # Apply on-disk ownership to match the share model: guest -> nobody,
   # group-owned -> root:group + setgid (new files inherit the group).
   if ($guest eq "yes") {
    system("/usr/bin/sudo","/usr/bin/chown","nobody:nobody",$path);
    system("/usr/bin/sudo","/usr/bin/chmod","2775",$path);
   }
   elsif ($has_group) {
    system("/usr/bin/sudo","/usr/bin/chown","root:$group",$path);
    system("/usr/bin/sudo","/usr/bin/chmod","2770",$path);
   }
   my $section=share_section($share,$path,$browsable,$guest,$readonly,$recycle,
                             $has_group ? $group : "");
   open(my $fh,'|-',"/usr/bin/sudo /usr/bin/tee -a $config > /dev/null");
   print $fh $section;
   close($fh);
   write_share_marker($path,"smb",$section);
   if (get_service_status($service)) {
    $rc=system("/usr/bin/sudo /usr/bin/systemctl restart $service > /dev/null");
   }
   write_log($addon->{"name"},"INFO","Samba share was added");
  }
 }

##### delete share #####
 if (defined($action) && $action eq "delete") {
  my $share=$self->param("share");
  my $vol=$self->param("vol");
  $rc=system("/usr/bin/sudo /usr/bin/sed -i '/#### $share ####/,/comment = $share/d' $config");
  remove_share_marker("$mount_dir/$vol","smb") if (defined($vol) && $vol ne "");
  if (get_service_status($service)) {
   $rc=system("/usr/bin/sudo /usr/bin/systemctl restart $service > /dev/null");
  }
  write_log($addon->{"name"},"INFO","Samba share was deleted");
 }

##### resync ownership (re-ACL after a backend switch) #####
# Re-chown every group-owned share dir to its force group's *current* gid. Fixes
# stale on-disk ownership when a backend switch renumbered the gids but the
# group names stayed the same.
 if (defined($action) && $action eq "resync") {
  my @conf=`/usr/bin/sudo /bin/cat $config 2>/dev/null`;
  my ($s,$p,$g);
  my $flush=sub {
   if (defined $s && defined $p && defined $g
       && `/usr/bin/getent group $g 2>/dev/null` ne "") {
    system("/usr/bin/sudo","/usr/bin/chown","root:$g",$p);
    system("/usr/bin/sudo","/usr/bin/chmod","2770",$p);
   }
   $s=$p=$g=undef;
  };
  foreach (@conf) {
   if (/^#### (.+) ####/)                       { $flush->(); $s=$1; }
   elsif (defined $s && /^\s*path\s*=\s*(\S+)/) { $p=$1; }
   elsif (defined $s && /^\s*force group\s*=\s*(\S+)/) { $g=$1; }
  }
  $flush->();
  if (get_service_status($service)) {
   $rc=system("/usr/bin/sudo /usr/bin/systemctl restart $service > /dev/null");
  }
  $result="success";
  $msg=$TEXT{'samba_resynced'} || "Share ownership resynced to current groups.";
  write_log($addon->{"name"},"INFO","Samba share ownership resynced");
 }

##### chgroup (reassign one share's owner group) #####
 if (defined($action) && $action eq "chgroup") {
  my $share=$self->param("share");
  my $vol=$self->param("vol");
  my $group=$self->param("group") // "";
  my $path="$mount_dir/$vol";
  if (defined($share) && $share =~ /^[A-Za-z0-9._-]+$/
      && ($group eq "" || ($group =~ /^[A-Za-z0-9._-]+$/
                           && `/usr/bin/getent group $group 2>/dev/null` ne ""))) {
   my $ro=`/usr/bin/sudo /bin/grep -A20 "#### $share ####" $config 2>/dev/null | /usr/bin/grep -m1 "read only"`;
   $ro = ($ro =~ /yes/i) ? "yes" : "no";
   if ($group ne "") {
    system("/usr/bin/sudo","/usr/bin/chown","root:$group",$path);
    system("/usr/bin/sudo","/usr/bin/chmod","2770",$path);
   }
   reassign_group($config,$share,$group,$ro);
   if (get_service_status($service)) {
    $rc=system("/usr/bin/sudo /usr/bin/systemctl restart $service > /dev/null");
   }
   $result="success";
   $msg=$TEXT{'samba_group_changed'} || "Owner group updated.";
   write_log($addon->{"name"},"INFO","Samba share $share owner group set to '$group'");
  }
 }

##### menu ######
  my $service_active=get_service_status($service);
  my %groups=groups_info();
  my @shares;
  my ($cur,$cpath,$cgroup);
  my @conf=`/usr/bin/sudo /bin/cat $config 2>/dev/null`;
  my $push_share=sub {
   return unless (defined $cur && defined $cpath);
   my $vol=$cpath;
   $vol =~ s|^$mount_dir/||;
   # Resolve the on-disk owning group via NSS (stat %G). A share is "stale" if
   # it forces a group but the on-disk group differs -- the re-ACL signal.
   my $owner=`/usr/bin/stat -c '%G' "$cpath" 2>/dev/null`;
   chomp $owner;
   my $stale=(defined($cgroup) && $cgroup ne "" && $owner ne $cgroup) ? 1 : 0;
   push(@shares,{name=>$cur,path=>$cpath,vol=>$vol,owner=>$owner,
                 group=>($cgroup//""),stale=>$stale});
  };
  foreach (@conf)
  {
   if (/^#### (.+) ####/) { $push_share->(); $cur=$1; $cpath=undef; $cgroup=undef; }
   elsif (defined($cur) && /^\s*path\s*=\s*(\S+)/)        { $cpath=$1; }
   elsif (defined($cur) && /^\s*force group\s*=\s*(\S+)/) { $cgroup=$1; }
  }
  $push_share->();
  $self->stash(service_active => $service_active,
	       shares => \@shares,
	       groups => \%groups,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/samba');

}


1;
