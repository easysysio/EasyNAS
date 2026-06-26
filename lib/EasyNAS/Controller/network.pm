package EasyNAS::Controller::Network;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon   = get_addon_info("network");
my %TEXT=get_lang_text($addon->{'name'});
my $service = ($addon->{service});

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action'); 
  $msg="";
  $result=""; 
  $self->stash(addon => $addon, 
	       TEXT =>\%TEXT);

  ### activate ###
  if (defined $action && $action eq "activate") {
   `/usr/bin/sudo /usr/bin/systemctl start $service`;
   `/usr/bin/sudo /usr/bin/systemctl enable $service`;
   write_log($addon->{"name"},"INFO","$addon->{\"description\"} Service started");
  }


  #### save #####
  if (defined $action && $action eq "save") {
  save($self);
  }

   ##### edit #####
  if (defined $action && $action eq "edit") {
   my $interface=$self->param("interface");
   my %networks=networks_info();
   $self->stash(networks => \%networks,
	        interface => $interface);
   $self->render(template => 'easynas/network_edit');
   return;
  }

  ##### menu ######
  
  my $service_active=get_service_status($service);
  my %networks=networks_info();
  $self->stash(service_active => $service_active,
	       networks => \%networks,
	       result => $result,
      	       msg => $msg );
  $self->render(template => 'easynas/network'); 
}

##### save ######
sub save($self) {
  my $interface=$self->param("interface");
  my $network=$self->param("network");
  my $ip=$self->param("ip");
  my $subnet=$self->param("subnet");
  my $gateway=$self->param("gateway");
  my $dns1=$self->param("dns1");
  my $dns2=$self->param("dns2");
  my $domain=$self->param("domain");
  my $rc;

  if ($network eq "auto") {
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.method auto");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.gateway \"\" ");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.address \"\" ");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.dns \"\" ");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con up $interface");
   if ($rc) {
    $result="failed";
    $msg=$TEXT{'network_failed_to_save'};
   }
   else {
    $result="success";
    $msg=$TEXT{'network_saved'};
   }
  }
  else {
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.method manual");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.addresses $ip/$subnet");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.gateway $gateway");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con mod $interface ipv4.dns $dns1 $dns2");
   $rc=system("/usr/bin/sudo /usr/bin/nmcli con up $interface");
   if ($rc) {
    $result="failed";
    $msg=$TEXT{'network_failed_to_save'};
   }
   else {
    $result="success";
    $msg=$TEXT{'network_saved'};
   }
  }
  return;
}

1;
