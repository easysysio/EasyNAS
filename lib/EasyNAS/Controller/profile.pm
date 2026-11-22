package EasyNAS::Controller::Profile;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;

# The signed-in account's own page: change its password. Open to every
# signed-in account (<access>all</access>): the web administrator, a NAS
# account made an administrator, and a NAS user signed in for the file
# manager. Unlike <access>user</access> it is not a reason for NAS accounts to
# be able to sign in at all -- see login.pm's user_home.
#
# The password is checked and set the same way sign-in checks it and the
# Users page sets it: admin.conf for the web administrator, the system and
# Samba passwords for a NAS account. Wrong current passwords count towards
# the sign-in lockout of the client's address, so this page can't be used to
# guess one either.

my $addon = get_addon_info("user_profile");
my %TEXT  = get_lang_text($addon->{'name'});

sub view ($self) {
  my $user     = $self->session('user') // '';
  my $is_admin = ($self->session('role') // 'admin') eq 'admin';
  # The web administrator: an admin session that isn't a NAS account's.
  my $web_admin = ($is_admin && !$self->session('nas_admin')) ? 1 : 0;
  my ($result, $msg) = ('', '');

  # Changes by POST only: the session cookie is SameSite=Lax, which another
  # site can't make a browser send with a POST.
  if ($self->req->method eq 'POST' && ($self->param('action') // '') eq 'changepassword') {
    ($result, $msg) = change_password($self, $user, $web_admin);
  }

  $self->stash(addon     => $addon,
               TEXT      => \%TEXT,
               username  => $user,
               is_admin  => $is_admin ? 1 : 0,
               web_admin => $web_admin,
               home      => ($is_admin ? '/' : (EasyNAS::Controller::Login::user_home() || '/profile')),
               result    => $result,
               msg       => $msg);
  $self->render(template => 'easynas/profile');
}

# ('success'|'fail', message)
sub change_password ($self, $user, $web_admin) {
  my $current = $self->param('current')   // '';
  my $new     = $self->param('password1') // '';
  my $again   = $self->param('password2') // '';
  my $ip      = $self->tx->remote_address // '?';

  if (my $left = EasyNAS::Controller::Login::locked_for($ip)) {
    return ('fail', sprintf($TEXT{'login_locked'} // "Too many failed sign-in attempts. Try again in %d minute(s).",
                            int(($left + 59) / 60)));
  }
  return ('fail', $TEXT{'profile_empty'}    || 'Enter a new password.') if $new eq '';
  return ('fail', $TEXT{'profile_mismatch'} || "The new passwords don't match.") if $new ne $again;

  my $ok = $web_admin ? EasyNAS::Controller::Login::admin_ok($user, $current)
                      : EasyNAS::Controller::Login::nas_user_ok($user, $current);
  if (!$ok) {
    EasyNAS::Controller::Login::note_failure($ip, $user);
    return ('fail', $TEXT{'profile_wrong_current'} || 'The current password is not right.');
  }
  EasyNAS::Controller::Login::clear_failures($ip);

  my $err = $web_admin ? EasyNAS::Controller::Users::set_admin_password($new)
                       : EasyNAS::Controller::Users::set_passwords($user, $new);
  return ('fail', $TEXT{'profile_failed'} || 'The password could not be changed.') if $err;

  write_log("profile", "INFO", "$user changed their own password");
  return ('success', $web_admin
    ? ($TEXT{'profile_changed'} || 'Your password has been changed.')
    : ($TEXT{'profile_changed_shares'} || 'Your password has been changed. It is your password for the file shares (Samba, SSH, FTP) too.'));
}

1;
