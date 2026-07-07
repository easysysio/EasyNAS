package EasyNAS::Controller::Settings;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("settings");
my %TEXT=get_lang_text($addon->{'name'});

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action'); 
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

######### changesettings #########
  if ($action eq "changesettings") {
   changesettings($self);
  }

######### setdate #########
  if (defined $action && $action eq "setdate") {
   setdate($self);
  }

######### upload_crt #########
  if (defined $action && $action eq "upload_crt") {
   upload_crt($self);
  }

##### menu ######
  my $hostname=`/bin/hostname`;
  # Current date/time to seed the Date/Time tab inputs.
  my $today=`/bin/date +%Y-%m-%d`; chomp $today;
  my $now=`/bin/date +%H:%M`;      chomp $now;
  # Active TLS cert summary (issuer + validity) for the Certificate tab.
  my $cert_info=`/usr/bin/sudo /usr/bin/openssl x509 -in /etc/easynas/easynas.cert -noout -issuer -dates 2>/dev/null`;
  # Port lives in the persistent config layer (/etc/easynas/easynas.conf),
  # not the read-only systemd unit. Fall back to the default if unset.
  my $str=`/usr/bin/grep '^EASYNAS_PORT=' /etc/easynas/easynas.conf 2>/dev/null`;
  (my $port) = $str =~ /(\d+)/;
  $port = 1443 unless $port;
  # Upgrade-snapshot retention = snapper's NUMBER_LIMIT on the root config
  # (how many pre/post upgrade snapshots to keep before old ones are cleaned).
  # Empty when snapper isn't present (e.g. an ext4 build).
  my $snapshots="";
  my $sc=`/usr/bin/sudo /usr/bin/snapper -c root get-config 2>/dev/null`;
  if ($sc =~ /^NUMBER_LIMIT\s*\|\s*(\S+)/m) { $snapshots=$1; }
  $self->stash(hostname => $hostname,
	       port => $port,
	       snapshots => $snapshots,
	       today => $today,
	       now => $now,
	       cert_info => $cert_info,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/settings');

}

######## upload_crt ########
# Replace the appliance's TLS certificate (and optionally its key) with an
# uploaded PEM, then restart so the daemon serves it. The daemon reads
# /etc/easynas/easynas.{cert,key} (see the service's -l https://...?cert=&key=).
sub upload_crt($self) {
 my $cert_dir="/etc/easynas";
 my $cert_up=$self->req->upload('cert');
 my $key_up =$self->req->upload('key');
 unless (defined $cert_up && $cert_up->size > 0) {
  $result="fail";
  $msg=$TEXT{'no_cert'} || "No certificate file was provided.";
  return;
 }
 # Land via /tmp then sudo-move, so ownership/permissions are correct regardless
 # of who owns the existing cert files.
 $cert_up->move_to("/tmp/easynas_upload.cert");
 system("/usr/bin/sudo /bin/mv -f /tmp/easynas_upload.cert $cert_dir/easynas.cert");
 system("/usr/bin/sudo /bin/chown easynas:easynas $cert_dir/easynas.cert");
 if (defined $key_up && $key_up->size > 0) {
  $key_up->move_to("/tmp/easynas_upload.key");
  system("/usr/bin/sudo /bin/mv -f /tmp/easynas_upload.key $cert_dir/easynas.key");
  system("/usr/bin/sudo /bin/chown easynas:easynas $cert_dir/easynas.key");
  system("/usr/bin/sudo /bin/chmod 600 $cert_dir/easynas.key");
 }
 write_log("settings","INFO","TLS certificate was uploaded");
 $result="success";
 $msg=$TEXT{'settings_cert_uploaded'} || "Certificate uploaded. Restarting to apply it...";
 # Restart so the daemon picks up the new cert/key.
 system("/usr/bin/sudo /usr/bin/systemctl restart easynas.service &");
 return;
}

######## setdate ########
# Manually set the system date/time (a fallback when NTP isn't in use). Inputs
# are strictly shape-validated before they reach the shell.
sub setdate($self) {
 my $date=$self->param("date");   # YYYY-MM-DD
 my $time=$self->param("time");   # HH:MM
 unless (defined $date && $date =~ /^\d{4}-\d{2}-\d{2}$/
      && defined $time && $time =~ /^\d{2}:\d{2}$/) {
  $result="fail";
  $msg=$TEXT{'error_updating_date'} || "Invalid date or time.";
  return;
 }
 my $rc=system("/usr/bin/sudo /usr/bin/date -s \"$date $time:00\" >/dev/null 2>&1");
 if ($rc ne 0) {
  $result="fail";
  $msg=$TEXT{'error_updating_date'} || "Failed to set the date/time.";
  return;
 }
 # Persist to the hardware clock so it survives a reboot.
 system("/usr/bin/sudo /sbin/hwclock --systohc >/dev/null 2>&1");
 write_log("settings","INFO","date/time was changed");
 $result="success";
 $msg=$TEXT{'settings_date_set'} || "Date and time updated.";
 return;
}

######## changesettings #######
sub changesettings($self) {
 my $port=$self->param("port");
 my $hostname=$self->param("hostname");
 my $conf_hosts=get_conf_hosts();
 my $rc;
 if ($port > 65535 || $port < 1025) {
  $result="fail";
  $msg=$TEXT{'settings_bad_port'};
  return;
 }
 # Upgrade-snapshot retention: set snapper's NUMBER_LIMIT (and make sure the
 # number-cleanup algorithm is on so old snapshots are actually removed).
 my $snapshots=$self->param("snapshots");
 if (defined $snapshots && $snapshots =~ /^\d+$/ && $snapshots >= 1 && $snapshots <= 100) {
  system("/usr/bin/sudo /usr/bin/snapper -c root set-config \"NUMBER_LIMIT=$snapshots\" \"NUMBER_CLEANUP=yes\" 2>/dev/null");
 }
 $rc=system("/bin/echo \"$hostname\" | /usr/bin/sudo /usr/bin/tee /etc/hostname > /dev/null");
 $rc=system("/usr/bin/sudo /bin/hostname $hostname > /dev/null");
 $rc=system("/bin/echo '############## EasyNAS hosts file ############' | /usr/bin/sudo /usr/bin/tee $conf_hosts > /dev/null");
 $rc=system("/bin/echo '127.0.0.1  localhost $hostname' | /usr/bin/sudo /usr/bin/tee -a $conf_hosts > /dev/null");
 # Persist the port to the config layer; systemd reads it via EnvironmentFile.
 $rc=system("/bin/echo \"EASYNAS_PORT=$port\" | /usr/bin/sudo /usr/bin/tee /etc/easynas/easynas.conf > /dev/null");
 $rc=system("/usr/bin/sudo /usr/bin/systemctl daemon-reload > /dev/null");
 $rc=system("/usr/bin/sudo /usr/bin/systemctl restart easynas.service &");
 $result="success";
 $msg=$TEXT{'settings_saved'};
 return;
}
  

1;
