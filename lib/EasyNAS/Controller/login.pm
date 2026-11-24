package EasyNAS::Controller::Login;
use lib "/easynas/lib/EasyNAS/Controller";
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;

my $msg;
my $result;
my %TEXT=get_lang_text('login');

# The web administrator is authenticated against a single hashed credential in
# the config layer -- NOT a local system account. See docs/identity-design.md.
my $admin_conf = "/etc/easynas/admin.conf";

# Sign-in throttling, per client address. The $FREE_TRIES-th wrong password in
# a row locks the address out for a minute, and each further one doubles that,
# up to $MAX_LOCK. An address left quiet for $WINDOW (counted from the end of
# any lockout) starts afresh, and a successful sign-in clears it. That leaves
# a guesser a handful of tries per quarter hour instead of thousands a minute,
# while a user who mistypes a few times is never stopped. Per address rather than per
# account, so nobody can lock the administrator out by failing as "admin".
# Kept in memory: the app is a single process, and a restart forgetting the
# counts costs a guesser more time than it saves.
my %throttle;                   # address -> { fails, last, until }
my $FREE_TRIES = 5;
my $WINDOW     = 15 * 60;
my $MAX_LOCK   = 15 * 60;

sub view ($self) {
   
    if ($self->session('is_auth')) {
        $self->redirect_to('/');
    }

    my $action = $self->param('action');
    $msg="";
    $result="";

#-------- Login ---------
    if (defined $action && $action eq "login") {
	login($self);
    }

#-------- Logout --------     
    if (defined $action && $action eq "logout") {
	logout($self);
    }

#-------- Menu ----------    
    $self->stash(result => $result,
                 msg => $msg,
		 username => '',
                 title => 'EasyNAS',
		 TEXT => \%TEXT,
                 url => '/login');
    $self->render(template => 'easynas/login');
    
}


sub login ($self) {
  my $user = $self->param('user') // '';
  my $pass = $self->param('pass') // '';
  my $ip   = $self->tx->remote_address // '?';

  # Locked out: refuse without looking at the password, so a guess made
  # during the lockout tells nothing even when it is right.
  if (my $left = locked_for($ip)) {
    $result="failed";
    my $min = int(($left + 59) / 60);
    $msg = sprintf($TEXT{'login_locked'} // "Too many failed sign-in attempts. Try again in %d minute(s).", $min);
    return;
  }

  # admin.conf holds one line, "<user>:<$6$ crypt hash>". Absent until the
  # first-boot console prompt seeds it.
  my ($auth_user, $stored) = read_admin_credential();
  if (!defined $stored || $stored eq '') {
    $result="failed";
    $msg="Admin account is not configured yet. Complete first-boot setup on the console.";
    return;
  }

  if ( admin_ok($user, $pass) ) {
    $result="success";
    $self->session(is_auth => 1);
    $self->session(user => $user);
    clear_failures($ip);
    $self->session(role => 'admin');
    # A new appliance: start with the setup wizard.
    $self->redirect_to(setup_needed() ? '/wizard' : '/');
  }
  # Not the administrator: a NAS account may sign in when it was made an
  # administrator on the Users page -- then it gets the same session as admin,
  # marked nas_admin so the router re-checks the flag on every request (see
  # EasyNAS.pm) -- or when an installed addon is open to NAS users (the
  # file manager). That session carries role "user", which the router confines
  # to such addons -- see EasyNAS.pm.
  elsif ( ($user ne $auth_user) && (is_nas_admin($user) || user_home()) && nas_user_ok($user, $pass) ) {
    $result="success";
    $self->session(is_auth => 1);
    $self->session(user => $user);
    clear_failures($ip);
    if (is_nas_admin($user)) {
      $self->session(role => 'admin', nas_admin => 1);
      write_log("login","INFO","NAS user $user signed in as an administrator");
      $self->redirect_to(setup_needed() ? '/wizard' : '/');
    }
    else {
      $self->session(role => 'user');
      write_log("login","INFO","NAS user $user signed in");
      $self->redirect_to(user_home());
    }
  }
  else {
    $result="failed";
    $msg="Bad Username or Password";
    note_failure($ip, $user);
  }
  return;
}

# Seconds $ip is still locked out for; 0 when it may try.
sub locked_for ($ip, $now = time) {
  my $t = $throttle{$ip} or return 0;
  my $left = ($t->{until} // 0) - $now;
  return $left > 0 ? $left : 0;
}

# Count a wrong password from $ip, and lock it out once it is past its free
# tries. $user is only for the log line.
sub note_failure ($ip, $user, $now = time) {
  if (keys %throttle > 10000) {          # bound the memory a scan could use
    delete @throttle{ grep { $now - ($throttle{$_}{until} // $throttle{$_}{last}) > $WINDOW
                                && $now - $throttle{$_}{last} > $WINDOW } keys %throttle };
  }
  my $t = $throttle{$ip};
  my $quiet_since = $t ? (($t->{until} // 0) > $t->{last} ? $t->{until} : $t->{last}) : 0;
  $t = $throttle{$ip} = { fails => 0 } if !$t || $now - $quiet_since > $WINDOW;
  $t->{fails}++;
  $t->{last} = $now;
  return if $t->{fails} < $FREE_TRIES;
  my $lock = 60 * 2 ** ($t->{fails} - $FREE_TRIES);
  $lock = $MAX_LOCK if $lock > $MAX_LOCK;
  $t->{until} = $now + $lock;
  (my $who = substr($user // '', 0, 32)) =~ s/[^A-Za-z0-9_.\@-]/?/g;
  write_log("login", "WARNING", "$t->{fails} failed sign-ins from $ip (last as \"$who\"); locked out for $lock seconds");
}

sub clear_failures ($ip) { delete $throttle{$ip}; }

# The page a NAS user lands on: the first enabled addon that declares
# <access>user</access>. Empty when there is none, and then no NAS account can
# sign in at all.
sub user_home {
  my %addons = get_addons();
  foreach my $name (sort keys %addons) {
    next unless ($addons{$name}{access} // '') eq 'user';
    next if ($addons{$name}{enable} // '') eq 'false';
    return '/'.$addons{$name}{program};
  }
  return '';
}

# Check a NAS account's password against its /etc/shadow hash, the same way
# the admin's is checked against admin.conf. Only ordinary accounts -- the uid
# range the Users page manages -- and only ones with a real password: a locked
# ("!", "*") or empty entry never matches.
sub nas_user_ok ($user, $pass) {
  return 0 unless defined $user && $user =~ /^[A-Za-z_][A-Za-z0-9_.-]{0,31}$/;
  return 0 unless defined $pass && $pass ne '';
  return 0 if $user eq 'easynas' || $user eq 'nobody';
  my @pw = getpwnam($user);
  return 0 unless @pw && $pw[2] >= 1000 && $pw[2] < 65000;
  # List form, no shell; the name was validated above.
  open(my $sh, '-|', '/usr/bin/sudo', '-n', '/usr/bin/getent', 'shadow', $user) or return 0;
  my $line = <$sh>;
  close($sh);
  return 0 unless defined $line;
  chomp $line;
  my ($name, $stored) = split(/:/, $line);
  return 0 unless defined $name && $name eq $user && defined $stored && $stored =~ /^\$/;
  my $hash = crypt($pass, $stored);
  return (defined $hash && ct_eq($hash, $stored)) ? 1 : 0;
}

# 1 when $user/$pass are the web administrator's (admin.conf). crypt() with
# the stored hash as salt re-derives it from the entered password; compare in
# constant time so a wrong guess leaks no timing.
sub admin_ok ($user, $pass) {
  my ($auth_user, $stored) = read_admin_credential();
  return 0 unless defined $stored && $stored ne '' && defined $user && defined $pass;
  return 0 unless $user eq $auth_user;
  my $hash = crypt($pass, $stored);
  return (defined $hash && ct_eq($hash, $stored)) ? 1 : 0;
}

# The web administrator's account name ("admin"), or undef before first boot.
sub admin_name { my ($u) = read_admin_credential(); return $u; }

# Read "<user>:<hash>" from admin.conf; returns (undef,undef) if unreadable.
sub read_admin_credential {
  open(my $fh, '<', $admin_conf) or return (undef, undef);
  my $line = <$fh>;
  close($fh);
  return (undef, undef) unless defined $line;
  chomp $line;
  my ($u, $h) = split(/:/, $line, 2);
  return ($u, $h);
}

# Constant-time string comparison: no early exit on the first differing byte.
sub ct_eq {
  my ($a, $b) = @_;
  return 0 if !defined($a) || !defined($b) || length($a) != length($b);
  my $r = 0;
  $r |= ord(substr($a, $_, 1)) ^ ord(substr($b, $_, 1)) for 0 .. length($a) - 1;
  return $r == 0;
}

sub logout ($self) {
  $self->session(expires => 1);
  $self->session(is_auth => 0);
  $self->redirect_to('login');
}

1;
