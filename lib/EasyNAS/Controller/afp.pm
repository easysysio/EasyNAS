package EasyNAS::Controller::Afp;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("afp");
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

##### afpon #####
 if (defined($action) && $action eq "afpon") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  write_log($addon->{"name"},"INFO","AFP Service started");
 }

#### afpoff #####
 if (defined($action) && $action eq "afpoff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  write_log($addon->{"name"},"INFO","AFP Service stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "create") {
  my %vol = vol_info();
  $self->stash(volumes => \%vol);
  $self->render(template => 'easynas/afp_create');
  return;
 }

##### add share #####
 if (defined($action) && $action eq "add") {
  my $name=$self->param("name");
  my $vol=$self->param("vol");
  # The share name becomes a config section header and a sed pattern on
  # delete -- keep it to safe characters.
  if (!defined $name || $name !~ /^[A-Za-z0-9_-]{1,64}$/
      || !defined $vol || $vol !~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$}) {
   $result="fail";
   $msg=$TEXT{'afp_missing_name'};
  }
  elsif (`/usr/bin/sudo /usr/bin/grep "#### $name ####" $addon->{config} 2>/dev/null`) {
   $result="fail";
   $msg=$TEXT{'afp_exists'};
  }
  else {
   my $path="$mount_dir/$vol";
   `/bin/echo ";#### $name ####" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "[$name]" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "path = $path" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo ";comment = $name" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   write_share_marker($path,"afp","$name");
   if (get_service_status($service)) {
    $rc=system("/usr/bin/sudo /usr/bin/systemctl reload $service >/dev/null");
   }
   write_log($addon->{"name"},"INFO","AFP share was added");
  }
 }

##### delete share #####
 if (defined($action) && $action eq "delete") {
  my $name=$self->param("name");
  my $vol=$self->param("vol") // "";
  if (defined $name && $name =~ /^[A-Za-z0-9_-]{1,64}$/) {
   # Each share is written as ";#### name ####" .. ";comment = name".
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/#### $name ####/,/comment = $name/d' $addon->{config}");
   remove_share_marker("$mount_dir/$vol","afp") if ($vol ne "");
   if (get_service_status($service)) {
    `/usr/bin/sudo /usr/bin/systemctl restart $service`;
   }
   write_log($addon->{"name"},"INFO","AFP share was deleted");
  }
 }

##### menu ######
  # Shares from the config: ";#### name ####" section headers, each followed
  # by a "path = <dir>" line.
  my @shares;
  my $name="";
  foreach (`/usr/bin/sudo /bin/cat $addon->{config} 2>/dev/null`) {
   if (/^;?#### (\S+) ####/)      { $name=$1; }
   elsif (/^path\s*=\s*(\S+)/ && $name ne "") {
    my $path=$1;
    my (undef,undef,$fs,$vol)=split("/",$path);
    push(@shares,{name=>$name,path=>$path,vol=>(defined $vol ? "$fs/$vol" : ($fs//""))});
    $name="";
   }
  }
  $self->stash(service_active => get_service_status($service),
	       shares => \@shares,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/afp');
}

1;
