package EasyNAS::Controller::Plex;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("plex");
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

##### plexon #####
 if (defined($action) && $action eq "plexon") {
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  write_log($addon->{"name"},"INFO","Plex Service started");
 }

#### plexoff #####
 if (defined($action) && $action eq "plexoff") {
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  write_log($addon->{"name"},"INFO","Plex Service stopped");
 }

##### media home #####
 if (defined($action) && $action eq "update") {
  my $sel=$self->param("radio_sel") // "";
  my $vol=$self->param("vol") // "";
  my $fs=$self->param("fs") // "";
  my $dir="";
  if    ($sel eq "nas")                                        { $dir=$mount_dir; }
  elsif ($sel eq "fs"  && $fs  =~ m{^[A-Za-z0-9_-]+$})         { $dir="$mount_dir/$fs"; }
  elsif ($sel eq "vol" && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$}) { $dir="$mount_dir/$vol"; }
  if ($dir ne "") {
   $rc=system("/usr/bin/sudo /usr/bin/sed -i '\\%^Environment=%cEnvironment=PLEX_MEDIA_SERVER_HOME=$dir' $addon->{config}");
   `/usr/bin/sudo /usr/bin/systemctl daemon-reload`;
   if (get_service_status($service)) {
    `/usr/bin/sudo /usr/bin/systemctl restart $service`;
   }
   write_log($addon->{"name"},"INFO","Plex media home set to $dir");
  }
  else {
   $result="fail";
   $msg=$TEXT{'plex_bad_input'} || "Select what to serve.";
  }
 }

##### menu ######
  # Current media home from the systemd override.
  my $media_dir="";
  foreach (`/usr/bin/sudo /bin/cat $addon->{config} 2>/dev/null`) {
   if (/PLEX_MEDIA_SERVER_HOME=(\S+)/) { $media_dir=$1; last; }
  }
  my $rel=$media_dir; $rel =~ s{^\Q$mount_dir\E/?}{};
  my ($sel_nas,$sel_fs,$sel_vol)=("","","");
  if    ($rel eq "")      { $sel_nas="checked"; }
  elsif ($rel =~ m{/})    { $sel_vol="checked"; }
  else                    { $sel_fs="checked";  }
  my %fs = fs_info();
  my %vol = vol_info();
  $self->stash(service_active => get_service_status($service),
	       media_dir => $media_dir,
	       sel_nas => $sel_nas, sel_fs => $sel_fs, sel_vol => $sel_vol,
	       filesystems => \%fs, volumes => \%vol,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/plex');
}

1;
