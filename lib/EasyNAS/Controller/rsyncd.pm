package EasyNAS::Controller::Rsyncd;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("rsyncd");
my $service = ($addon->{service});
my %TEXT=get_lang_text($addon->{'name'});

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action');
  my $mount_dir=get_mount_dir();
  my $rc;
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

##### rsyncdon #####
 if (defined($action) && $action eq "rsyncdon") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  write_log($addon->{"name"},"INFO","RSync Service started");
 }

#### rsyncdoff #####
 if (defined($action) && $action eq "rsyncdoff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  write_log($addon->{"name"},"INFO","RSync Service stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "create") {
  my %vol = vol_info();
  $self->stash(volumes => \%vol);
  $self->render(template => 'easynas/rsyncd_create');
  return;
 }

##### add share #####
 if (defined($action) && $action eq "add") {
  my $name=$self->param("name");
  my $vol=$self->param("vol");
  my $readonly=($self->param("readonly") // "") eq "yes" ? "yes" : "no";
  # The module name becomes a config section header and a sed pattern on
  # delete -- keep it to safe characters.
  if (!defined $name || $name !~ /^[A-Za-z0-9_-]{1,64}$/
      || !defined $vol || $vol !~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$}) {
   $result="fail";
   $msg=$TEXT{'rsyncd_missing_name'};
  }
  elsif (`/usr/bin/sudo /usr/bin/grep "#### $name ####" $addon->{config} 2>/dev/null`) {
   $result="fail";
   $msg=$TEXT{'rsyncd_exists'};
  }
  else {
   my $path="$mount_dir/$vol";
   `/bin/echo "#### $name ####" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "[$name]" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "path = $path" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "read only = $readonly" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "comment = $name" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   write_share_marker($path,"rsyncd","$name");
   if (get_service_status($service)) {
    $rc=system("/usr/bin/sudo /usr/bin/systemctl reload $service >/dev/null");
   }
   write_log($addon->{"name"},"INFO","RSync share was added");
  }
 }

##### delete share #####
 if (defined($action) && $action eq "delete") {
  my $name=$self->param("share");
  my $vol=$self->param("vol") // "";
  if (defined $name && $name =~ /^[A-Za-z0-9_-]{1,64}$/) {
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/#### $name ####/,/comment = $name/d' $addon->{config}");
   remove_share_marker("$mount_dir/$vol","rsyncd") if ($vol ne "");
   if (get_service_status($service)) {
    `/usr/bin/sudo /usr/bin/systemctl restart $service`;
   }
   write_log($addon->{"name"},"INFO","RSync share was deleted");
  }
 }

##### menu ######
  # Modules from the config: "#### name ####" headers followed by "path ="
  # and "read only =" lines.
  my @shares;
  my ($name,$path)=("","");
  foreach (`/usr/bin/sudo /bin/cat $addon->{config} 2>/dev/null`) {
   if    (/^#### (\S+) ####/)          { $name=$1; $path=""; }
   elsif (/^path\s*=\s*(\S+)/)         { $path=$1; }
   elsif (/^read only\s*=\s*(\S+)/ && $name ne "") {
    my $ro=$1;
    my (undef,undef,$fs,$vol)=split("/",$path);
    push(@shares,{name=>$name,path=>$path,readonly=>$ro,
                  vol=>(defined $vol ? "$fs/$vol" : ($fs//""))});
    $name="";
   }
  }
  $self->stash(service_active => get_service_status($service),
	       shares => \@shares,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/rsyncd');
}

1;
