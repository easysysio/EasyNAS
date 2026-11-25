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
   service_ctl('start',$service);
   service_ctl('enable',$service);
   write_log($addon->{"name"},"INFO","$addon->{\"description\"} Service started");
  }


  #### save #####
  if (defined $action && $action eq "save") {
  save($self);
  }

   ##### edit #####
  if (defined $action && $action eq "editmenu") {
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

  # The root helper checks every value (an interface that exists, IPv4
  # addresses, a prefix length) before NetworkManager sees it.
  my ($ok,$out);
  if (($network // "") eq "auto") {
   ($ok,$out)=root_do('net',$interface // "",'auto');
   write_log("network","ERROR","$interface: DHCP not set: $out") unless $ok;
   if (!$ok) {
    $result="failed";
    $msg=$TEXT{'network_failed_to_save'};
   }
   else {
    $result="success";
    $msg=$TEXT{'network_saved'};
   }
  }
  else {
   my @v=map { (defined $_ && $_ ne "") ? $_ : "-" } ($gateway,$dns1,$dns2);
   ($ok,$out)=root_do('net',$interface // "",'manual',$ip // "",$subnet // "",@v);
   write_log("network","ERROR","$interface: address not set: $out") unless $ok;
   if (!$ok) {
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
