package EasyNAS::Controller::Ssh;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("ssh");
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

##### sshon #####
 if (defined($action) && $action eq "sshon") {
  service_ctl('start',$service);
  service_ctl('enable',$service);
 }

#### sshoff #####
 if (defined($action) && $action eq "sshoff") {
  service_ctl('stop',$service);
  service_ctl('disable',$service);
 }

##### menu ######
  my $service_active=get_service_status($service);
  $self->stash(service_active => $service_active,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/ssh'); 

}


1;
