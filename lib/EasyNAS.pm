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

# Actions a GET may ask for (see the admin gate in startup): the ones that
# only show something. Every page names its forms and dialogs "...menu";
# these are the read-only ones that don't, polled by the pages' scripts.
my %view_action = map { $_ => 1 } qw(stats status progress display);
sub view_action ($action) { return ($action =~ /menu$/ || $view_action{$action}) ? 1 : 0; }

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
  # A NAS account signed in as an administrator (nas_admin, see login.pm)
  # stays one only while it still is: once the flag is taken away on the Users
  # page or the account is deleted, its session ends on its next request
  # instead of keeping full access until the cookie expires.
  my $auth = $r->under(sub ($c) {
    if ($c->session('is_auth') && $c->session('nas_admin') && !is_nas_admin($c->session('user'))) {
      write_log("login","INFO","signed ".($c->session('user') // '?')." out: no longer an administrator");
      $c->session(expires => 1);
    }
    elsif ($c->session('is_auth')) { return 1; }
    $c->redirect_to('login');
    return undef;
  });

  # A session is either the administrator's or a NAS user's (role "user", set
  # by login.pm when the file manager addon lets NAS accounts sign in). A NAS
  # user reaches only the routes of addons that declare <access>user</access>;
  # everything else sits behind this second gate. A session without a role
  # predates roles and can only be the administrator's.
  #
  # The administrator's pages change things only through POST. The session
  # cookie is SameSite=Lax, which a browser still sends when a page on another
  # site sends it here with a plain link or redirect (a GET), never with a
  # cross-site POST. So a GET may carry only an action that just shows
  # something -- a name ending in "menu", or one of %view_action -- and a GET
  # asking for any other action is sent back to the bare page, having done
  # nothing. Pages carry their changes in POST forms (or links marked
  # data-post, which the layout turns into one).
  my @user_home;
  my $admin = $auth->under(sub ($c) {
    if (($c->session('role') // 'admin') ne 'admin') {
      if (@user_home) { $c->redirect_to($user_home[0]); }
      else            { $c->render(text => 'Forbidden', status => 403); }
      return undef;
    }
    return 1 unless $c->req->method eq 'GET';
    my $action = $c->req->query_params->param('action');
    return 1 if !defined $action || $action eq '' || view_action($action);
    write_log("easynas","WARNING","refused a GET of ".$c->req->url->path." asking for action \"".
              substr($action =~ s/[^A-Za-z0-9_-]/?/gr, 0, 32)."\": changes are made by POST only");
    $c->redirect_to($c->req->url->path->to_string);
    return undef;
  });

  $admin->get('/')->to('dashboard#view');
  $admin->get('/easynas')->to('dashboard#view');
  $admin->get('/easynas/firmware.pl')->to('dashboard#view');
  # The Firmware page is gone -- the Add-ons page updates EasyNAS and its
  # add-ons -- so an old bookmark lands there.
  $admin->get('/firmware' => sub ($c) { $c->redirect_to('/addons') });
  $admin->get('/language')->to('language#view');
  foreach my $item (sort keys %addons) {
    my $program = $addons{$item}{'program'};
    my $access = $addons{$item}{'access'} // '';
    if ($access eq 'user' || $access eq 'all') {
      # Open to every signed-in account, and POST as well as GET: these pages
      # make their changes by POST only. "user" pages (the file manager) are
      # also what NAS accounts sign in for and land on; "all" ones (the
      # profile page) are only reachable once signed in.
      $auth->any([qw(GET POST)] => "/$program")->to("$program#view");
      push @user_home, "/$program" if $access eq 'user';
    }
    else {
      $admin->any([qw(GET POST)] => "/$program")->to("$program#view");
      # A page's live connection (the LXC terminal), for the ones that have
      # one (a ws action); admin only, like the page.
      $admin->websocket("/$program/ws")->to("$program#ws");
    }
  }
}

1;
