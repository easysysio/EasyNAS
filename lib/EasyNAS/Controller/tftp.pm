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
  `/usr/bin/sudo /usr/bin/systemctl start easynas-tftp.socket`;
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable easynas-tftp.socket`;
  write_log($addon->{"name"},"INFO","TFTP Service started");
 }

#### tftpoff #####
 if (defined($action) && $action eq "tftpoff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl stop easynas-tftp.socket`;
  `/usr/bin/sudo /usr/bin/systemctl disable easynas-tftp.socket`;
  write_log($addon->{"name"},"INFO","TFTP Service stopped");
 }

##### set the served directory #####
 if (defined($action) && $action eq "add") {
  my $vol=$self->param("vol");
  my $dirname="$mount_dir/$vol";
  if (defined $vol && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$} && -d $dirname) {
   my $uid=(stat($dirname))[4];
   my $user=(getpwuid $uid)[0] // "root";
   `/bin/echo "############ EasyNAS TFTP Config File ###########" | /usr/bin/sudo /usr/bin/tee $addon->{config} >/dev/null`;
   `/bin/echo "TFTP_USER=$user" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "TFTP_OPTIONS=" | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   `/bin/echo "TFTP_DIRECTORY=$dirname " | /usr/bin/sudo /usr/bin/tee -a $addon->{config} >/dev/null`;
   if (get_service_status($service)) {
    $rc=system("/usr/bin/sudo /usr/bin/systemctl restart $service >/dev/null");
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
  $rc=system("/usr/bin/sudo /usr/bin/sed -i '/TFTP_DIRECTORY/d' $addon->{config}");
  if (get_service_status($service)) {
   `/usr/bin/sudo /usr/bin/systemctl restart $service`;
  }
  write_log($addon->{"name"},"INFO","TFTP share was removed");
 }

##### menu ######
  # TFTP serves a single directory; show the one currently configured.
  my $current="";
  foreach (`/usr/bin/sudo /bin/cat $addon->{config} 2>/dev/null`) {
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
