package EasyNAS::Controller::Mariadb;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("mariadb");
my $service = ($addon->{service});
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

##### mariadbon #####
 if (defined($action) && $action eq "mariadbon") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  write_log($addon->{"name"},"INFO","MariaDB Service started");
 }

#### mariadboff #####
 if (defined($action) && $action eq "mariadboff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  write_log($addon->{"name"},"INFO","MariaDB Service stopped");
 }

##### menu ######
  # Server version straight from the client package (present via the mariadb
  # dependency); empty when the query fails so the template can hide the line.
  my $dbver=`/usr/bin/mysql --version 2>/dev/null`;
  chomp $dbver;
  $dbver = ($dbver =~ /Distrib ([0-9.]+)/i || $dbver =~ /\b([0-9]+\.[0-9]+\.[0-9]+)-MariaDB/i) ? $1 : "";
  $self->stash(service_active => get_service_status($service),
	       dbver => $dbver,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/mariadb');
}

1;
