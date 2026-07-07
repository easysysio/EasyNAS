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

  # Login/logout are reachable without a session.
  $r->any('/login')->to('login#view');
  $r->get('/logout')->to('login#logout');

  # Everything else requires an authenticated session. This 'under' gate stops
  # dispatch for unauthenticated requests -- previously each controller called
  # redirect_to('login') but did NOT return, so the requested action still ran.
  my $auth = $r->under(sub ($c) {
    return 1 if $c->session('is_auth');
    $c->redirect_to('login');
    return undef;
  });

  $auth->get('/')->to('dashboard#view');
  $auth->get('/easynas')->to('dashboard#view');
  $auth->get('/easynas/firmware.pl')->to('dashboard#view');
  $auth->get('/firmware')->to('firmware#view');
  $auth->get('/language')->to('language#view');
  foreach my $item (keys %addons) {
	  $auth->get('/'.$addons{$item}{'program'})->to($addons{$item}{'program'}.'#view');

  }
}

1;
