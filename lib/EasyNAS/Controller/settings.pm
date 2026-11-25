package EasyNAS::Controller::Settings;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::DOM;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("settings");
my %TEXT=get_lang_text($addon->{'name'});

# The two EasyNAS update channels. Exactly one is configured at a time, under
# these aliases: addons.pm, check_update.pl and addon-worker.sh
# all pick the active channel by looking for the EasyNAS_Beta alias, and the
# image (KIWI) bakes in the same ones.
my %CHANNEL = (
  stable  => { alias => 'EasyNAS',      url => 'https://repo.easysys.io/easynas/stable/RPMS/' },
  testing => { alias => 'EasyNAS_Beta', url => 'https://repo.easysys.io/easynas/testing/RPMS/' },
);

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

######### setchannel #########
  # POST only: the session cookie is SameSite=Lax, so another site can make a
  # browser GET this page signed in, but not POST to it.
  if (defined $action && $action eq "setchannel" && $self->req->method eq "POST") {
   setchannel($self);
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
  my @repos=repo_list();
  $self->stash(hostname => $hostname,
	       repos => \@repos,
	       channel => active_channel(@repos),
	       channels => \%CHANNEL,
	       port => $port,
	       snapshots => $snapshots,
	       today => $today,
	       now => $now,
	       cert_info => $cert_info,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/settings');

}

######## repositories ########
# Every configured zypper repository, as { alias, name, url, enabled }, from
# zypper's XML so nothing depends on its column layout or language.
sub repo_list {
 return parse_repos(scalar `/usr/bin/sudo /usr/bin/zypper --quiet --xmlout repos 2>/dev/null`);
}

sub parse_repos {
 my ($xml)=@_;
 my @repos;
 Mojo::DOM->new->xml(1)->parse($xml // '')->find('repo')->each(sub {
  my $r=shift;
  push @repos, { alias   => $r->attr('alias') // '',
                 name    => $r->attr('name')  // $r->attr('alias') // '',
                 url     => $r->at('url') ? $r->at('url')->text : '',
                 enabled => ($r->attr('enabled') // '') eq '1' ? 1 : 0 };
 });
 return @repos;
}

# "testing" when the testing channel's repo is enabled, else "stable" (the
# same rule the update code uses).
sub active_channel {
 my @repos=@_;
 foreach my $r (@repos) {
  return 'testing' if $r->{enabled} && $r->{alias} eq $CHANNEL{testing}{alias};
 }
 return 'stable';
}

######## setchannel ########
# Switch the appliance between the stable and testing channels. The new
# channel's repo is added and refreshed FIRST and the old one removed only once
# that worked, so an unreachable repo leaves the appliance on its old channel
# instead of on none. Installed packages are not touched: moving from testing
# to stable keeps the (newer) testing versions until stable catches up.
sub setchannel($self) {
 my $want=$self->param("channel") // '';
 unless (exists $CHANNEL{$want}) {
  $result="fail";
  $msg=$TEXT{'settings_channel_bad'} || "Unknown update channel.";
  return;
 }
 my $have=active_channel(repo_list());
 if ($want eq $have) {
  $result="success";
  $msg=$TEXT{'settings_channel_same'} || "The appliance is already on this channel.";
  return;
 }
 if (get_update_state() eq "updating") {
  $result="fail";
  $msg=$TEXT{'settings_channel_busy'} || "An update is running; change the channel when it has finished.";
  return;
 }
 my $new=$CHANNEL{$want};
 my $old=$CHANNEL{$have};
 my $rc;

 my $out;
 # zypper's own words, logged in full and shown with the message.
 my $why = sub ($step, $out) {
  write_log("settings","ERROR","update channel $have -> $want: zypper $step failed: ".($out =~ s/\s+/ /gr));
  my $r = zypper_reason($out);
  return $r ne '' ? " (zypper: $r)" : '';
 };

 # A stale repo under the new alias (e.g. disabled by hand) would make addrepo
 # fail; clear it first. Fails harmlessly when there is none.
 zypper_run("--quiet","removerepo",$new->{alias});
 ($rc,$out)=zypper_run("--quiet","addrepo","--refresh",$new->{url},$new->{alias});
 if ($rc != 0) {
  $result="fail";
  # zypper exits 7 when another zypper (an add-on install, an update) holds
  # its lock.
  $msg=(($rc >> 8) == 7)
     ? ($TEXT{'settings_channel_locked'} || "The package manager is busy (an add-on install or update is running). Try again when it has finished.")
     : ($TEXT{'settings_channel_failed'} || "Could not change the update channel.").$why->("addrepo",$out);
  return;
 }
 ($rc,$out)=zypper_run("--quiet","--gpg-auto-import-keys","refresh",$new->{alias});
 if ($rc != 0) {
  zypper_run("--quiet","removerepo",$new->{alias});
  $result="fail";
  $msg=($TEXT{'settings_channel_unreachable'} || "The channel's repository could not be reached; the update channel was not changed.").$why->("refresh",$out);
  return;
 }
 zypper_run("--quiet","removerepo",$old->{alias});

 # Rebuild the add-on catalog, the pending-update list and the core-image
 # manifest for the new channel. Several network round trips, so in its own
 # transient unit rather than holding up this page.
 system("/usr/bin/sudo","/usr/bin/systemd-run","--collect","--quiet","/easynas/startup/check_update.pl");
 write_log("settings","INFO","update channel changed from $have to $want");
 $result="success";
 $msg=$TEXT{'settings_channel_changed'} || "Update channel changed. Checking it for updates in the background.";
 return;
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
 service_ctl('restart-later','easynas.service');
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
 unless (defined $port && $port =~ /^\d{4,5}$/ && $port >= 1025 && $port <= 65535) {
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
 # Persist the port to the config layer. systemd holds the listening socket
 # (easynas.socket), so web-port.sh copies the port into its drop-in and
 # restarts the web interface: only the app on the same port (connections
 # wait meanwhile), the socket too on a new one. In its own transient unit so
 # it outlives this process, which it restarts.
 $rc=system("/bin/echo \"EASYNAS_PORT=$port\" | /usr/bin/sudo /usr/bin/tee /etc/easynas/easynas.conf > /dev/null");
 $rc=system("/usr/bin/sudo","/usr/bin/systemd-run","--collect","--quiet","/easynas/startup/web-port.sh","--apply");
 $result="success";
 $msg=$TEXT{'settings_saved'};
 return;
}
  

1;
