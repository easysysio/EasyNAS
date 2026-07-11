package EasyNAS::Controller::Dlna;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("dlna");
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

##### dlnaon #####
 if (defined($action) && $action eq "dlnaon") {
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  write_log($addon->{"name"},"INFO","DLNA Service started");
 }

#### dlnaoff #####
 if (defined($action) && $action eq "dlnaoff") {
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  write_log($addon->{"name"},"INFO","DLNA Service stopped");
 }

##### media dir #####
 if (defined($action) && $action eq "update") {
  my $sel=$self->param("radio_sel") // "";
  my $vol=$self->param("vol") // "";
  my $fs=$self->param("fs") // "";
  my $dir="";
  if    ($sel eq "nas")                                        { $dir=$mount_dir; }
  elsif ($sel eq "fs"  && $fs  =~ m{^[A-Za-z0-9_-]+$})         { $dir="$mount_dir/$fs"; }
  elsif ($sel eq "vol" && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$}) { $dir="$mount_dir/$vol"; }
  if ($dir ne "") {
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '\\%^media_dir=%cmedia_dir=$dir' $addon->{config}");
   if (get_service_status($service)) {
    `/usr/bin/sudo /usr/bin/systemctl restart $service`;
   }
   write_log($addon->{"name"},"INFO","DLNA media directory set to $dir");
  }
  else {
   $result="fail";
   $msg=$TEXT{'dlna_bad_input'} || "Select what to serve.";
  }
 }

##### settings #####
 if (defined($action) && $action eq "change") {
  my $port=$self->param("port") // "";
  my $host=$self->param("host") // "";
  my $scan=$self->param("rescan") // "";
  my $max=$self->param("max") // "";
  if ($port !~ /^\d+$/ || $port < 1 || $port > 65535
      || $host !~ /^[A-Za-z0-9_. -]{1,64}$/
      || $scan !~ /^\d+$/ || $scan < 1 || $scan > 9999
      || $max !~ /^\d+$/) {
   $result="fail";
   $msg=$TEXT{'dlna_bad_input'} || "Invalid settings.";
  }
  else {
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/^port=/cport=$port' $addon->{config}");
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/^friendly_name=/cfriendly_name=$host' $addon->{config}");
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/^notify_interval=/cnotify_interval=$scan' $addon->{config}");
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '/^max_connections=/cmax_connections=$max' $addon->{config}");
   if (get_service_status($service)) {
    `/usr/bin/sudo /usr/bin/systemctl restart $service`;
   }
   write_log($addon->{"name"},"INFO","DLNA settings updated");
  }
 }

##### menu ######
  # Current config values for the form.
  my %cfg=(media_dir=>"",port=>"",friendly_name=>"",notify_interval=>"",max_connections=>"");
  foreach (`/usr/bin/sudo /bin/cat $addon->{config} 2>/dev/null`) {
   if (/^(media_dir|port|friendly_name|notify_interval|max_connections)=(.*)$/) { $cfg{$1}=$2; }
  }
  # Which radio matches the current media_dir: whole NAS, one fs, or one volume.
  my $rel=$cfg{media_dir}; $rel =~ s{^\Q$mount_dir\E/?}{};
  my ($sel_nas,$sel_fs,$sel_vol)=("","","");
  if    ($rel eq "")      { $sel_nas="checked"; }
  elsif ($rel =~ m{/})    { $sel_vol="checked"; }
  else                    { $sel_fs="checked";  }
  my %fs = fs_info();
  my %vol = vol_info();
  $self->stash(service_active => get_service_status($service),
	       cfg => \%cfg, cur => $rel,
	       sel_nas => $sel_nas, sel_fs => $sel_fs, sel_vol => $sel_vol,
	       filesystems => \%fs, volumes => \%vol,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/dlna');
}

1;
