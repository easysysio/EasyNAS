package EasyNAS::Controller::Language;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


# Set the UI language from the flag dropdown, then return to the dashboard.
# set_current_lang validates the code, so a bad/absent value is a no-op.
sub view ($self) {
  set_current_lang($self->param('lang'));
  $self->redirect_to('/');
}


1;
