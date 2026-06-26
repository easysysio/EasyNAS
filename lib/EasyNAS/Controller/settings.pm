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
  my $str=`/usr/bin/sudo grep ExecStart /usr/lib/systemd/system/easynas.service | cut -d" " -f6 `;
  (my $port) = $str =~ /(\d+)/;  
  $self->stash(hostname => $hostname,
	       port => $port,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/settings'); 

}

######## changesettings #######
sub changesettings($self) {
 my $port=$self->param("port");
 my $hostname=$self->param("hostname");
 my $old_port=$self->param("old_port");
 my $conf_hosts=get_conf_hosts();
 my $conf_webui=get_conf_webui();
 my $rc;
 if ($port > 65535 || $port < 1025) {
  $result="fail";
  $msg=$TEXT{'settings_bad_port'};
  return;
 }
 $rc=system("/bin/echo \"$hostname\" | /usr/bin/sudo /usr/bin/tee /etc/hostname > /dev/null"); 
 $rc=system("/usr/bin/sudo /bin/hostname $hostname > /dev/null");
 $rc=system("/bin/echo '############## EasyNAS hosts file ############' | /usr/bin/sudo /usr/bin/tee $conf_hosts > /dev/null");
 $rc=system("/bin/echo '127.0.0.1  localhost $hostname' | /usr/bin/sudo /usr/bin/tee -a $conf_hosts > /dev/null");
 $rc=system("/usr/bin/sudo /usr/bin/sed -i 's/$old_port/$port/g' $conf_webui > /dev/null");
 $rc=system("/usr/bin/sudo /usr/bin/systemctl restart easynas.service &"); 
 $result="success";
 $msg=$TEXT{'settings_saved'};
 return;
}
  

1;
