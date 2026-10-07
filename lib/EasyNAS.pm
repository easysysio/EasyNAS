package EasyNAS;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious', -signatures;
use easynas;

my $secret_file = '/etc/easynas/session.secret';

# The secret that signs session cookies. Whoever knows it can mint a cookie
# saying "is_auth", so it has to be unique to this appliance and never leave
# it: generated from the kernel RNG on first start and kept on the config
# layer (0600, owned by the service user), which persists across OS updates.
# It used to be a fixed value in easy_n_a_s.yml -- the same on every appliance
# and published with the source.
sub session_secret {
  if (open(my $fh, '<', $secret_file)) {
    my $s = <$fh>;
    close $fh;
    if (defined $s) { chomp $s; return $s if length($s) >= 32; }
  }
  open(my $rnd, '<:raw', '/dev/urandom') or die "session secret: /dev/urandom: $!";
  my $n = read($rnd, my $bytes, 32);
  close $rnd;
  die "session secret: short read from /dev/urandom" unless defined $n && $n == 32;
  my $s = unpack('H*', $bytes);
  # If the config layer can't be written the secret still works, for this
  # process only: sessions end at the next restart instead of surviving it.
  my $old = umask 0077;
  if (open(my $out, '>', $secret_file)) { print $out "$s\n"; close $out; }
  umask $old;
  return $s;
}

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets([session_secret()]);

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

  # A session is either the administrator's or a NAS user's (role "user", set
  # by login.pm when the file manager addon lets NAS accounts sign in). A NAS
  # user reaches only the routes of addons that declare <access>user</access>;
  # everything else sits behind this second gate. A session without a role
  # predates roles and can only be the administrator's.
  my @user_home;
  my $admin = $auth->under(sub ($c) {
    return 1 if ($c->session('role') // 'admin') eq 'admin';
    if (@user_home) { $c->redirect_to($user_home[0]); }
    else            { $c->render(text => 'Forbidden', status => 403); }
    return undef;
  });

  $admin->get('/')->to('dashboard#view');
  $admin->get('/easynas')->to('dashboard#view');
  $admin->get('/easynas/firmware.pl')->to('dashboard#view');
  $admin->get('/firmware')->to('firmware#view');
  $admin->get('/language')->to('language#view');
  foreach my $item (sort keys %addons) {
    my $program = $addons{$item}{'program'};
    if (($addons{$item}{'access'} // '') eq 'user') {
      # Open to every signed-in account, and POST as well as GET: these pages
      # change things through POST requests carrying a CSRF token.
      $auth->any([qw(GET POST)] => "/$program")->to("$program#view");
      push @user_home, "/$program";
    }
    else {
      $admin->get("/$program")->to("$program#view");
    }
  }
  # Cert upload is a multipart POST (a GET can't carry a file).
  $admin->post('/settings')->to('settings#view');
}

1;
