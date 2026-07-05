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
 my ($share,$path,$browsable,$guest,$readonly,$recycle)=@_;
 my $s = "#### $share ####\n";
 $s .= "[$share]\n";
 $s .= "path = $path\n";
 $s .= "browsable = $browsable\n";
 $s .= "guest ok = $guest\n";
 $s .= "read only = $readonly\n";
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
  $self->stash(volumes => \%vol);
  $self->render(template => 'easynas/samba_create');
  return;
 }

##### add share #####
 if (defined($action) && $action eq "add") {
  my $share=$self->param("name");
  my $vol=$self->param("vol");
  my $readonly=($self->param("readonly") // "") eq "yes" ? "yes" : "no";
  my $guest=($self->param("guest") // "") eq "yes" ? "yes" : "no";
  my $browsable=($self->param("browsable") // "") eq "yes" ? "yes" : "no";
  my $recycle=($self->param("recycle") // "") eq "yes" ? 1 : 0;
  if (!defined($share) || $share eq "") {
   $result="fail";
   $msg=$TEXT{'samba_missing_name'};
  }
  elsif (`/usr/bin/sudo /usr/bin/grep "#### $share ####" $config 2>/dev/null`) {
   $result="fail";
   $msg=$TEXT{'samba_share_exists'};
  }
  else {
   my $section=share_section($share,"$mount_dir/$vol",$browsable,$guest,$readonly,$recycle);
   open(my $fh,'|-',"/usr/bin/sudo /usr/bin/tee -a $config > /dev/null");
   print $fh $section;
   close($fh);
   write_share_marker("$mount_dir/$vol","smb",$section);
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

##### menu ######
  my $service_active=get_service_status($service);
  my @shares;
  my $cur;
  my @conf=`/usr/bin/sudo /bin/cat $config 2>/dev/null`;
  foreach (@conf)
  {
   if (/^#### (.+) ####/) {
    $cur=$1;
   }
   elsif (defined($cur) && /^\s*path\s*=\s*(\S+)/) {
    my $path=$1;
    my $vol=$path;
    $vol =~ s|^$mount_dir/||;
    push(@shares,{name=>$cur,path=>$path,vol=>$vol});
    $cur=undef;
   }
  }
  $self->stash(service_active => $service_active,
	       shares => \@shares,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/samba');

}


1;
