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

##### menu ######
  my $hostname=`/bin/hostname`;
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
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/settings');

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
