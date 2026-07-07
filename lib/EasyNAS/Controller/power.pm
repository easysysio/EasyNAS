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

  # Unlike the v1 power.pl, we do NOT stop services or unmount filesystems by
  # hand: systemd does both cleanly as part of reboot/poweroff. Run the command
  # detached after a short delay so this HTTP response returns first.

##### reboot #####
 if (defined($action) && $action eq "reboot") {
  write_log("power","INFO","restart requested from the web UI");
  system("/bin/sh -c '/bin/sleep 2; /usr/bin/sudo /usr/bin/systemctl reboot' >/dev/null 2>&1 &");
  $result="success";
  $msg=$TEXT{'power_restarting'} || "The appliance is restarting...";
 }

##### shutdown #####
 if (defined($action) && $action eq "shutdown") {
  write_log("power","INFO","shutdown requested from the web UI");
  system("/bin/sh -c '/bin/sleep 2; /usr/bin/sudo /usr/bin/systemctl poweroff' >/dev/null 2>&1 &");
  $result="success";
  $msg=$TEXT{'power_shuttingdown'} || "The appliance is shutting down...";
 }

##### menu ######
  $self->stash(result => $result,
               msg => $msg);
  $self->render(template => 'easynas/power');
}


1;
