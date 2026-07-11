package EasyNAS::Controller::Radius;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("radius");
my $service = ($addon->{service});
my $clients = ($addon->{clients});
my %TEXT=get_lang_text($addon->{'name'});

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action');
  my $rc;
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

##### radiuson #####
 if (defined($action) && $action eq "radiuson") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  write_log($addon->{"name"},"INFO","Radius Service started");
 }

#### radiusoff #####
 if (defined($action) && $action eq "radiusoff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  write_log($addon->{"name"},"INFO","Radius Service stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "create") {
  $self->render(template => 'easynas/radius_create');
  return;
 }

##### add client #####
 if (defined($action) && $action eq "add") {
  my $client=$self->param("client");
  my $ip=$self->param("ip");
  my $secret=$self->param("secret");
  # Client name/IP become config blocks and sed patterns; the secret is
  # written into a root-only config file.
  if (!defined $client || $client !~ /^[A-Za-z0-9_.-]{1,64}$/
      || !defined $ip || $ip !~ /^[0-9a-fA-F.:\/]{3,45}$/
      || !defined $secret || $secret =~ /["'\\\$`]/ || $secret eq "") {
   $result="fail";
   $msg=$TEXT{'radius_bad_input'} || "Invalid client, IP, or secret.";
  }
  elsif (`/usr/bin/sudo /usr/bin/grep -w "$client" $clients 2>/dev/null`
      || `/usr/bin/sudo /usr/bin/grep -w "$ip" $clients 2>/dev/null`) {
   $result="fail";
   $msg=$TEXT{'radius_client_exists'};
  }
  else {
   `/bin/echo "#### $client ####" | /usr/bin/sudo /usr/bin/tee -a $clients >/dev/null`;
   `/bin/echo "client $client {" | /usr/bin/sudo /usr/bin/tee -a $clients >/dev/null`;
   `/bin/echo "ipaddr = $ip" | /usr/bin/sudo /usr/bin/tee -a $clients >/dev/null`;
   `/bin/echo "secret = $secret" | /usr/bin/sudo /usr/bin/tee -a $clients >/dev/null`;
   `/bin/echo "}" | /usr/bin/sudo /usr/bin/tee -a $clients >/dev/null`;
   if (get_service_status($service)) {
    $rc=system("/usr/bin/sudo /usr/bin/systemctl restart $service >/dev/null");
   }
   write_log($addon->{"name"},"INFO","Radius client $client added");
  }
 }

##### delete client #####
 if (defined($action) && $action eq "delete") {
  my $client=$self->param("client");
  if (defined $client && $client =~ /^[A-Za-z0-9_.-]{1,64}$/) {
   $rc=system("/usr/bin/sudo /bin/sed -i '/#### $client ####/,/}/d' $clients");
   if (get_service_status($service)) {
    `/usr/bin/sudo /usr/bin/systemctl reload $service`;
   }
   write_log($addon->{"name"},"INFO","Radius client $client deleted");
  }
 }

##### menu ######
  # Clients from the config: "#### name ####" then "ipaddr = <ip>".
  my @radius_clients;
  my $name="";
  foreach (`/usr/bin/sudo /bin/cat $clients 2>/dev/null`) {
   if    (/^#### (\S+) ####/)        { $name=$1; }
   elsif (/^ipaddr\s*=\s*(\S+)/ && $name ne "") {
    push(@radius_clients,{name=>$name,ip=>$1});
    $name="";
   }
  }
  $self->stash(service_active => get_service_status($service),
	       clients => \@radius_clients,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/radius');
}

1;
