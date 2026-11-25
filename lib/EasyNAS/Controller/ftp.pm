package EasyNAS::Controller::Ftp;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("ftp");
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

##### ftpon #####
 if (defined($action) && $action eq "ftpon") {
  service_ctl('start',$service);
  service_ctl('enable',$service);
  write_log($addon->{"name"},"INFO","FTP Service started");
 }

#### ftpoff #####
 if (defined($action) && $action eq "ftpoff") {
  service_ctl('stop',$service);
  service_ctl('disable',$service);
  write_log($addon->{"name"},"INFO","FTP Service stopped");
 }

##### menu ######
  $self->stash(service_active => get_service_status($service),
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/ftp');
}

1;
