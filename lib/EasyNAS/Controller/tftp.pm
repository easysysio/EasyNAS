package EasyNAS::Controller::Tftp;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("tftp");
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

##### tftpon #####
 if (defined($action) && $action eq "tftpon") {
  service_ctl('start','easynas-tftp.socket');
  service_ctl('start',$service);
  service_ctl('enable','easynas-tftp.socket');
  write_log($addon->{"name"},"INFO","TFTP Service started");
 }

#### tftpoff #####
 if (defined($action) && $action eq "tftpoff") {
  service_ctl('stop',$service);
  service_ctl('stop','easynas-tftp.socket');
  service_ctl('disable','easynas-tftp.socket');
  write_log($addon->{"name"},"INFO","TFTP Service stopped");
 }

##### set the served directory #####
 if (defined($action) && $action eq "add") {
  my $vol=$self->param("vol");
  my $dirname="$mount_dir/$vol";
  my $valid=(defined $vol && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$} && $vol !~ /\.\./ && -d $dirname);
  my $user=$valid ? ((getpwuid((stat($dirname))[4]))[0] // "root") : "";
  if ($valid && !root_write($addon->{config},
        "############ EasyNAS TFTP Config File ###########\nTFTP_USER=$user\nTFTP_OPTIONS=\nTFTP_DIRECTORY=$dirname \n")) {
   $result="fail";
   $msg=$TEXT{'tftp_failed'} || "The settings could not be saved.";
  }
  elsif ($valid) {
   if (get_service_status($service)) {
    $rc=service_ctl('restart',$service) ? 0 : 1;
   }
   write_log($addon->{"name"},"INFO","TFTP share was set to $dirname");
  }
  else {
   $result="fail";
   $msg=$TEXT{'tftp_no_vol'} || "Select a volume.";
  }
 }

##### clear the served directory #####
 if (defined($action) && $action eq "delete") {
  my $conf=root_read($addon->{config});
  if (defined $conf && root_write($addon->{config}, join('', grep { !/TFTP_DIRECTORY/ } split /^/, $conf))) {
   if (get_service_status($service)) {
    service_ctl('restart',$service);
   }
   write_log($addon->{"name"},"INFO","TFTP share was removed");
  }
  else {
   $result="fail";
   $msg=$TEXT{'tftp_failed'} || "The settings could not be saved.";
  }
 }

##### menu ######
  # TFTP serves a single directory; show the one currently configured.
  my $current="";
  foreach (root_lines($addon->{config})) {
   if (/^TFTP_DIRECTORY=(\S+)/) { $current=$1; last; }
  }
  my %vol = vol_info();
  $self->stash(service_active => get_service_status($service),
	       current => $current,
	       volumes => \%vol,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/tftp');
}

1;
