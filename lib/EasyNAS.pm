package EasyNAS;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious', -signatures;
use easynas;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;
  
  my %addons=get_addons();

  # Normal route to controller
  $r->get('/')->to('dashboard#view');
  $r->get('/easynas')->to('dashboard#view');
  $r->get('/easynas/firmware.pl')->to('dashboard#view');
  $r->any('/login')->to('login#view');
  $r->get('/logout')->to('login#logout');
  $r->get('/firmware')->to('firmware#view');
  foreach my $item (keys %addons) {
	  $r->get('/'.$addons{$item}{'program'})->to($addons{$item}{'program'}.'#view');

  }
}

1;
