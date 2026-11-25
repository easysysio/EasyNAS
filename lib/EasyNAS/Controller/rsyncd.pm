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
  service_ctl('start',$service);
  service_ctl('enable',$service);
  write_log($addon->{"name"},"INFO","RSync Service started");
 }

#### rsyncdoff #####
 if (defined($action) && $action eq "rsyncdoff") {
  service_ctl('stop',$service);
  service_ctl('disable',$service);
  write_log($addon->{"name"},"INFO","RSync Service stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "createmenu") {
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
      || !defined $vol || $vol !~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$} || $vol =~ /\.\./) {
   $result="fail";
   $msg=$TEXT{'rsyncd_missing_name'};
  }
  elsif ((root_read($addon->{config}) // "") =~ /^#### \Q$name\E ####\s*$/m) {
   $result="fail";
   $msg=$TEXT{'rsyncd_exists'};
  }
  elsif (!root_append($addon->{config},
                      "#### $name ####\n[$name]\npath = $mount_dir/$vol\nread only = $readonly\ncomment = $name\n")) {
   $result="fail";
   $msg=$TEXT{'rsyncd_failed'} || "The share could not be saved.";
  }
  else {
   my $path="$mount_dir/$vol";
   write_share_marker($path,"rsyncd","$name");
   if (get_service_status($service)) {
    $rc=service_ctl('reload',$service) ? 0 : 1;
   }
   write_log($addon->{"name"},"INFO","RSync share was added");
  }
 }

##### delete share #####
 if (defined($action) && $action eq "delete") {
  my $name=$self->param("share");
  my $vol=$self->param("vol") // "";
  my $conf=(defined $name && $name =~ /^[A-Za-z0-9_-]{1,64}$/) ? root_read($addon->{config}) : undef;
  if (defined $conf
      && root_write($addon->{config}, drop_block($conf, qr/^#### \Q$name\E ####\s*$/, qr/^comment = \Q$name\E\s*$/))) {
   remove_share_marker("$mount_dir/$vol","rsyncd") if ($vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9._-]+$} && $vol !~ /\.\./);
   if (get_service_status($service)) {
    service_ctl('restart',$service);
   }
   write_log($addon->{"name"},"INFO","RSync share was deleted");
  }
 }

##### menu ######
  # Modules from the config: "#### name ####" headers followed by "path ="
  # and "read only =" lines.
  my @shares;
  my ($name,$path)=("","");
  foreach (root_lines($addon->{config})) {
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
