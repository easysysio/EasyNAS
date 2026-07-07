package EasyNAS::Controller::Power;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("power");
my %TEXT=get_lang_text($addon->{'name'});

sub view ($self) {
  my $action=$self->param('action');
  $msg="";
  $result="";
  $self->stash(addon => $addon,
               TEXT =>\%TEXT);

  # Delegate to startup/power.sh (shared with the console menu): it stops every
  # installed service, then reboots or powers off. Run detached so this response
  # returns before the box goes down. $action is matched against fixed strings
  # below, so the value reaching the shell is always "reboot" or "shutdown".
 if (defined($action) && ($action eq "reboot" || $action eq "shutdown")) {
  write_log("power","INFO","$action requested from the web UI");
  system("/usr/bin/nohup /easynas/startup/power.sh $action >/dev/null 2>&1 &");
  $result="success";
  $msg=($action eq "reboot")
       ? ($TEXT{'power_restarting'}   || "The appliance is restarting...")
       : ($TEXT{'power_shuttingdown'} || "The appliance is shutting down...");
 }

##### menu ######
  $self->stash(result => $result,
               msg => $msg);
  $self->render(template => 'easynas/power');
}


1;
