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
 # Samba-side identity only (no chown -- ownership lives with the volume):
 # a guest share maps everyone to nobody (the volume must allow "Others");
 # a group-owned volume limits access to its group members.
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

# Write (or overwrite) a share from the submitted form params: append the
# smb.conf section, drop a share marker and reload samba. Shared by add and
# change (edit).
#
# Ownership model: the VOLUME is the single source of truth for on-disk
# ownership (set in volume settings). The share only FOLLOWS it: a volume
# owned by a real group becomes a group-restricted share (force group /
# valid users derived from the directory's group); a root-owned volume is a
# plain share. Samba never chowns anything -- to change who owns the data,
# change the volume's owner and re-save the share.
sub apply_share {
 my ($self,$config,$mount_dir,$service)=@_;
 my $share=$self->param("name");
 my $vol=$self->param("vol");
 my $readonly=($self->param("readonly") // "") eq "yes" ? "yes" : "no";
 my $guest=($self->param("guest") // "") eq "yes" ? "yes" : "no";
 my $browsable=($self->param("browsable") // "") eq "yes" ? "yes" : "no";
 my $recycle=($self->param("recycle") // "") eq "yes" ? 1 : 0;
 my $path="$mount_dir/$vol";
 my $owner_group=`/usr/bin/stat -c '%G' "$path" 2>/dev/null`;
 chomp $owner_group;
 my $has_group=($guest ne "yes"
                && $owner_group ne "" && $owner_group ne "root" && $owner_group ne "nobody"
                && `/usr/bin/getent group $owner_group 2>/dev/null` ne "");
 my $section=share_section($share,$path,$browsable,$guest,$readonly,$recycle,
                           $has_group ? $owner_group : "");
 open(my $fh,'|-',"/usr/bin/sudo /usr/bin/tee -a $config > /dev/null");
 print $fh $section;
 close($fh);
 write_share_marker($path,"smb",$section);
 if (get_service_status($service)) {
  system("/usr/bin/sudo /usr/bin/systemctl restart $service > /dev/null");
 }
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
  $self->stash(volumes => \%vol, edit => 0,
               sname => "", svol => "",
               sbrowsable => "yes", sguest => "no", sreadonly => "no", srecycle => 0);
  $self->render(template => 'easynas/samba_create');
  return;
 }

##### edit menu (load an existing share into the form) #####
 if (defined($action) && $action eq "editmenu") {
  my $share=$self->param("share");
  if (defined($share) && $share =~ /^[A-Za-z0-9._-]+$/) {
   my %vol = vol_info();
   my @sec=`/usr/bin/sudo /bin/sed -n '/#### $share ####/,/comment = $share/p' $config 2>/dev/null`;
   my ($spath,$sbrowsable,$sguest,$sreadonly,$srecycle)=("","yes","no","no",0);
   foreach (@sec) {
    if    (/^\s*path\s*=\s*(\S+)/)         { $spath=$1; }
    elsif (/^\s*browsable\s*=\s*(\S+)/)    { $sbrowsable=$1; }
    elsif (/^\s*guest ok\s*=\s*(\S+)/)     { $sguest=$1; }
    elsif (/^\s*read only\s*=\s*(\S+)/)    { $sreadonly=$1; }
    elsif (/^\s*vfs object\s*=\s*recycle/) { $srecycle=1; }
   }
   my $svol=$spath; $svol =~ s|^\Q$mount_dir\E/||;
   $self->stash(volumes => \%vol, edit => 1,
                sname => $share, svol => $svol,
                sbrowsable => $sbrowsable, sguest => $sguest,
                sreadonly => $sreadonly, srecycle => $srecycle);
   $self->render(template => 'easynas/samba_create');
   return;
  }
 }

##### add share #####
 if (defined($action) && $action eq "add") {
  my $share=$self->param("name");
  if (!defined($share) || $share eq "") {
   $result="fail";
   $msg=$TEXT{'samba_missing_name'};
  }
  elsif (`/usr/bin/sudo /usr/bin/grep "#### $share ####" $config 2>/dev/null`) {
   $result="fail";
   $msg=$TEXT{'samba_share_exists'};
  }
  else {
   apply_share($self,$config,$mount_dir,$service);
   write_log($addon->{"name"},"INFO","Samba share was added");
  }
 }

##### change share (edit an existing share in place) #####
# Rename isn't supported inline (that's delete + add), so the section header
# name is fixed; everything else is rewritten by dropping the old section and
# writing the new one from the form.
 if (defined($action) && $action eq "change") {
  my $share=$self->param("name");
  if (!defined($share) || $share !~ /^[A-Za-z0-9._-]+$/) {
   $result="fail";
   $msg=$TEXT{'samba_missing_name'};
  }
  else {
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/#### $share ####/,/comment = $share/d' $config");
   apply_share($self,$config,$mount_dir,$service);
   $result="success";
   $msg=$TEXT{'samba_share_edited'} || "Share updated.";
   write_log($addon->{"name"},"INFO","Samba share $share was edited");
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



##### menu ######
  my $service_active=get_service_status($service);
  my @shares;
  my ($cur,$cpath);
  my @conf=`/usr/bin/sudo /bin/cat $config 2>/dev/null`;
  my $push_share=sub {
   return unless (defined $cur && defined $cpath);
   my $vol=$cpath;
   $vol =~ s|^$mount_dir/||;
   # On-disk ownership, read-only context: it belongs to the volume.
   my $owner=`/usr/bin/stat -c "%U:%G" "$cpath" 2>/dev/null`;
   chomp $owner;
   push(@shares,{name=>$cur,path=>$cpath,vol=>$vol,owner=>$owner});
  };
  foreach (@conf)
  {
   if (/^#### (.+) ####/) { $push_share->(); $cur=$1; $cpath=undef; }
   elsif (defined($cur) && /^\s*path\s*=\s*(\S+)/)        { $cpath=$1; }
  }
  $push_share->();
  $self->stash(service_active => $service_active,
	       shares => \@shares,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/samba');

}


1;
