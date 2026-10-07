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

  # admin.conf holds one line, "<user>:<$6$ crypt hash>". Absent until the
  # first-boot console prompt seeds it.
  my ($auth_user, $stored) = read_admin_credential();
  if (!defined $stored || $stored eq '') {
    $result="failed";
    $msg="Admin account is not configured yet. Complete first-boot setup on the console.";
    return;
  }

  # crypt() with the stored hash as salt re-derives it from the entered
  # password; compare in constant time so a wrong guess leaks no timing.
  my $hash = crypt($pass, $stored);
  if ( ($user eq $auth_user) && defined($hash) && ct_eq($hash, $stored) ) {
    $result="success";
    $self->session(is_auth => 1);
    $self->session(user => $user);
    $self->session(role => 'admin');
    $self->redirect_to('/');
  }
  # Not the administrator: a NAS account may sign in when an installed addon
  # is open to NAS users (the file manager). Its session carries role "user",
  # which the router confines to that addon -- see EasyNAS.pm.
  elsif ( ($user ne $auth_user) && (my $home = user_home()) && nas_user_ok($user, $pass) ) {
    $result="success";
    $self->session(is_auth => 1);
    $self->session(user => $user);
    $self->session(role => 'user');
    write_log("login","INFO","NAS user $user signed in");
    $self->redirect_to($home);
  }
  else {
    $result="failed";
    $msg="Bad Username or Password";
  }
  return;
}

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
