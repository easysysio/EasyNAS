#!/usr/bin/perl
# Tests for the Settings page's Repository tab, the sign-in throttle, NAS
# accounts made administrators, the Users page, and the router's rule that
# changes come by POST only.
#
# The controllers are loaded for real, against a stub of the easynas helper
# module (the real one reads the appliance's /etc and runs zypper), and pages
# are rendered from the real templates inside a bare stand-in layout.
#
# Run: prove -v t/web.t      (needs Mojolicious)
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile tempdir);
use Mojolicious::Lite -signatures;

my $root = curfile->dirname->dirname;
my $stub = tempdir;

# --- stub of lib/EasyNAS/Controller/easynas.pm ---------------------------
# (plain open, not Mojo::File::spew: that is newer than some distros' Mojolicious)
sub put_file { my ($f, $s) = @_; open my $fh, ">", $f or die "$f: $!"; print $fh $s; close $fh }
put_file($stub->child('easynas.pm'), <<"EOF");
package easynas;
use Exporter 'import';
our \@EXPORT = qw(get_addon_info get_lang_text write_log get_update_state
                 get_conf_hosts get_addons is_nas_admin get_admin_group
                 users_info groups_info get_group_default get_mount_dir setup_needed);
our \@LOG;
our \$UPDATE_STATE = '';
sub get_addon_info { return { name => \$_[0], program => \$_[0] } }
sub get_lang_text  { our %TEXT; do '$root/lang/en-en/lang_english_easynas.pl' or die \$@ if !%TEXT; return %TEXT }
sub write_log      { push \@LOG, [\@_] }
sub get_update_state { \$UPDATE_STATE }
sub get_conf_hosts { '/dev/null' }
our %ADDONS;
sub get_addons     { %ADDONS }
our %NAS_ADMIN;
sub is_nas_admin    { \$NAS_ADMIN{\$_[0] // ''} ? 1 : 0 }
sub get_admin_group { 'easynas-admins' }
sub users_info  { (alice => [1000, 'alice', 'Alice', 'users staff', is_nas_admin('alice')],
                   bob   => [1001, 'bob',   'Bob',   'users',       is_nas_admin('bob')]) }
sub groups_info { (users => [100, 'users'], staff => [1000, 'staff']) }
sub get_group_default { 'users' }
sub get_mount_dir { '/mnt' }
our \$SETUP = 0;
sub setup_needed { \$SETUP }
1;
EOF
$stub->child('layouts')->make_path;
put_file($stub->child('layouts', $_), '<%= content %>') for qw(default.html.ep login.html.ep);
put_file($stub->child('layouts', 'user.html.ep'), '<nav id="user-frame"><%= $username %></nav><%= content %>');

unshift @INC, "$stub";
BEGIN {
  *CORE::GLOBAL::system = sub { push our @SYS, [@_]; my $rc = shift(our @RC) // 0; $? = $rc; return $rc };
}
require "$root/lib/EasyNAS/Controller/settings.pm";
require "$root/lib/EasyNAS/Controller/login.pm";
require "$root/lib/EasyNAS/Controller/users.pm";
require "$root/lib/EasyNAS/Controller/profile.pm";

app->renderer->paths(["$stub", "$root/templates"]);
app->routes->namespaces(['EasyNAS::Controller']);

# ===================== Repository tab =====================
my $xml = <<'EOF';
<?xml version='1.0'?>
<stream>
<repo-list>
<repo alias="EasyNAS_Beta" name="EasyNAS_Beta" type="rpm-md" priority="99" enabled="1" autorefresh="1" gpgcheck="1" repo_gpgcheck="1" pkg_gpgcheck="0"><url>https://repo.easysys.io/easynas/testing/RPMS/</url></repo>
<repo alias="Tumbleweed" name="Tumbleweed OSS" type="rpm-md" priority="99" enabled="0" autorefresh="1" gpgcheck="1"><url>https://download.opensuse.org/tumbleweed/repo/oss</url></repo>
</repo-list>
</stream>
EOF

my @repos = EasyNAS::Controller::Settings::parse_repos($xml);
is scalar @repos, 2, 'zypper repo list parsed';
is_deeply $repos[0], { alias => 'EasyNAS_Beta', name => 'EasyNAS_Beta',
                       url => 'https://repo.easysys.io/easynas/testing/RPMS/', enabled => 1 },
  'repo fields';
is $repos[1]{enabled}, 0, 'disabled repo';
is_deeply [EasyNAS::Controller::Settings::parse_repos('')], [], 'no output, no repos';
is_deeply [EasyNAS::Controller::Settings::parse_repos(undef)], [], 'undef output, no repos';

is EasyNAS::Controller::Settings::active_channel(@repos), 'testing', 'testing repo enabled -> testing';
is EasyNAS::Controller::Settings::active_channel(), 'stable', 'no repos -> stable';
is EasyNAS::Controller::Settings::active_channel({ alias => 'EasyNAS_Beta', enabled => 0 }),
  'stable', 'disabled testing repo does not count';
is EasyNAS::Controller::Settings::active_channel({ alias => 'EasyNAS', enabled => 1 }),
  'stable', 'stable repo -> stable';

# The template, rendered as the controller stashes it.
get '/settings_page' => sub {
  my $c = shift;
  our %TEXT;
  $c->stash(addon => {}, TEXT => \%TEXT, hostname => 'nas', port => 1443, snapshots => '',
            today => '2026-11-22', now => '10:00', cert_info => '', result => '', msg => '',
            repos => [@repos], channel => $c->param('ch'), channels => {});
  $c->render(template => 'easynas/settings');
};

my $t = Test::Mojo->new;
$t->get_ok('/settings_page?ch=testing')->status_is(200)
  ->element_exists('#tabs-4 form[method=post] input[name=action][value=setchannel]')
  ->element_exists('#tabs-4 input[name=channel][value=testing][checked]')
  ->element_exists_not('#tabs-4 input[name=channel][value=stable][checked]')
  ->text_is('#tabs-4 tbody tr:nth-child(1) td:nth-child(1)' => 'EasyNAS_Beta')
  ->element_exists('#tabs-4 tbody tr:nth-child(1) .fa-check')
  ->element_exists('#tabs-4 tbody tr:nth-child(2) .fa-xmark')
  ->element_exists_not('#tabs-5', 'placeholder tab gone');
like $t->tx->res->dom->at('#tabs-4 form')->attr('onsubmit'),
  qr/confirm\("Testing builds are previews[^"]*"\)/, 'testing confirm is a JS string';
$t->get_ok('/settings_page?ch=stable')
  ->element_exists('#tabs-4 input[name=channel][value=stable][checked]');

# --- switching channels, through the page, with zypper mocked -------------
# Every system() the controller makes is recorded, and answered from @RC
# (exit status, shifted like system() returns it; 0 when @RC runs out).
our (@SYS, @RC);
my $on = 'testing';                      # what repo_list reports
{
  no warnings qw(redefine once);
  *EasyNAS::Controller::Settings::repo_list = sub {
    return ({ alias => ($on eq 'testing' ? 'EasyNAS_Beta' : 'EasyNAS'), url => 'u', enabled => 1 });
  };
}
any '/settings' => sub { EasyNAS::Controller::Settings::view(shift) };
get '/signin' => sub { my $c = shift; $c->session(is_auth => 1); $c->render(text => 'ok') };

my $ts = Test::Mojo->new;
$ts->get_ok('/signin');
my $switch = sub ($method, $channel) {
  @SYS = ();
  $method eq 'GET'
    ? $ts->get_ok("/settings?action=setchannel&channel=$channel")
    : $ts->post_ok('/settings' => form => { action => 'setchannel', channel => $channel });
  return $ts;
};
my $zyp = sub { [grep { $_->[1] eq '/usr/bin/zypper' } @SYS] };

$switch->(GET => 'stable')->status_is(200);
is_deeply $zyp->(), [], 'GET never switches the channel';

$switch->(POST => 'bogus')->content_like(qr/Unknown update channel/);
is_deeply $zyp->(), [], 'unknown channel: nothing run';

$switch->(POST => 'testing')->content_like(qr/already on this channel/);
is_deeply $zyp->(), [], 'same channel: nothing run';

$easynas::UPDATE_STATE = 'updating';
$switch->(POST => 'stable')->content_like(qr/An update is running/);
is_deeply $zyp->(), [], 'update running: nothing run';
$easynas::UPDATE_STATE = '';

@easynas::LOG = ();
$switch->(POST => 'stable')->content_like(qr/Update channel changed/);
is_deeply [map { [@$_[2 .. $#$_]] } @{ $zyp->() }], [
  ['--quiet', 'removerepo', 'EasyNAS'],
  ['--quiet', 'addrepo', '--refresh', 'https://repo.easysys.io/easynas/stable/RPMS/', 'EasyNAS'],
  ['--quiet', '--non-interactive', '--gpg-auto-import-keys', 'refresh', 'EasyNAS'],
  ['--quiet', 'removerepo', 'EasyNAS_Beta'],
], 'testing -> stable: add and refresh the new repo, then drop the old one';
ok((grep { "@$_" =~ m{systemd-run .*check_update\.pl} } @SYS), 'update check started');
is $easynas::LOG[0][2], 'update channel changed from testing to stable', 'logged';

# The new repo can't be reached: it is removed again and the old one kept.
@RC = (0, 0, 1 << 8);
$switch->(POST => 'stable')->content_like(qr/could not be reached/);
is_deeply [map { "$_->[3] $_->[-1]" } @{ $zyp->() }],
  ['removerepo EasyNAS', 'addrepo EasyNAS', '--non-interactive EasyNAS', 'removerepo EasyNAS'],
  'unreachable: new repo removed, old one untouched';

# zypper locked by an add-on install.
@RC = (0, 7 << 8);
$switch->(POST => 'stable')->content_like(qr/package manager is busy/);
is scalar @{ $zyp->() }, 2, 'locked: stops after addrepo';

$on = 'stable';
$switch->(POST => 'testing')->content_like(qr/Update channel changed/);
is_deeply [map { $_->[-1] } @{ $zyp->() }], [qw(EasyNAS_Beta EasyNAS_Beta EasyNAS_Beta EasyNAS)],
  'stable -> testing';

# ===================== sign-in throttle =====================
my $L = 'EasyNAS::Controller::Login';
{
  no strict 'refs';
  my ($locked, $fail, $clear) = map { \&{"${L}::$_"} } qw(locked_for note_failure clear_failures);
  my $T = 1_000_000;

  is $locked->('10.0.0.1', $T), 0, 'fresh address is not locked';
  $fail->('10.0.0.1', 'admin', $T + $_) for 0 .. 3;
  is $locked->('10.0.0.1', $T + 4), 0, 'four failures: still free';
  $fail->('10.0.0.1', 'admin', $T + 4);
  is $locked->('10.0.0.1', $T + 4), 60, 'fifth failure locks for a minute';
  is $locked->('10.0.0.1', $T + 64), 0, '... and only a minute';
  $fail->('10.0.0.1', 'admin', $T + 70);
  is $locked->('10.0.0.1', $T + 70), 120, 'next failure doubles it';
  $fail->('10.0.0.1', 'admin', $T + 200 + $_ * 1000) for 0 .. 5;
  my $now = $T + 5200;
  is $locked->('10.0.0.1', $now), 900, 'capped at 15 minutes';
  is $locked->('10.0.0.2', $now), 0, 'other addresses unaffected';

  # Quiet for the window, counted from the END of the lockout: at the cap the
  # lockout is as long as the window, so the count must not reset the moment
  # the lockout ends.
  $fail->('10.0.0.1', 'admin', $now + 900);
  is $locked->('10.0.0.1', $now + 900), 900, 'right after a lockout: locked again';
  $fail->('10.0.0.1', 'admin', $now + 900 + 900 + 901);
  is $locked->('10.0.0.1', $now + 2701), 0, 'after the window: fresh tries';

  $fail->('10.0.0.3', 'x', $T + $_) for 0 .. 4;
  ok $locked->('10.0.0.3', $T + 5), 'locked';
  $clear->('10.0.0.3');
  is $locked->('10.0.0.3', $T + 5), 0, 'a successful sign-in clears it';

  @easynas::LOG = ();
  $fail->('10.0.0.4', "a\nb\"c" . ('x' x 50), $T + $_) for 0 .. 4;
  is scalar @easynas::LOG, 1, 'one log line, at the lockout';
  like $easynas::LOG[0][2], qr/^5 failed sign-ins from 10\.0\.0\.4 \(last as "a\?b\?cx{27}"\); locked out for 60 seconds$/,
    'log line: name sanitised and truncated';
}

# End to end through the login page: wrong passwords until locked out, after
# which even the right one is turned away.
{
  no warnings 'redefine';
  my $hash = crypt('secret', '$6$testsalt$');
  local *EasyNAS::Controller::Login::read_admin_credential = sub { ('admin', $hash) };
  any '/login' => sub { EasyNAS::Controller::Login::view(shift) };
  my $tl = Test::Mojo->new;
  $tl->post_ok('/login' => form => { action => 'login', user => 'admin', pass => 'wrong' })
     ->content_like(qr/Bad Username or Password/) for 1 .. 5;
  $tl->post_ok('/login' => form => { action => 'login', user => 'admin', pass => 'secret' })
     ->content_like(qr/Too many failed sign-in attempts\. Try again in 1 minute\(s\)\./,
                    'locked out even with the right password');
}
{
  no warnings 'redefine';
  my $hash = crypt('secret', '$6$testsalt$');
  local *EasyNAS::Controller::Login::read_admin_credential = sub { ('admin', $hash) };
  # A different client address is not affected.
  my $orig = \&Mojo::Transaction::remote_address;
  local *Mojo::Transaction::remote_address = sub { my $tx = shift; @_ ? $tx->$orig(@_) : '192.0.2.9' };
  my $tl = Test::Mojo->new;
  $tl->post_ok('/login' => form => { action => 'login', user => 'admin', pass => 'secret' })
     ->status_is(302, 'another address signs in')->header_is(Location => '/');
  local $easynas::SETUP = 1;
  Test::Mojo->new->post_ok('/login' => form => { action => 'login', user => 'admin', pass => 'secret' })
     ->status_is(302)->header_is(Location => '/wizard', 'a new appliance: the admin starts with the setup wizard');
}

# ===================== port change =====================
# systemd holds the socket: a port change goes through web-port.sh, which
# copies the port into the socket's drop-in and restarts the right units.
{
  @SYS = ();
  my $tp = Test::Mojo->new;
  $tp->get_ok('/signin');
  $tp->post_ok('/settings' => form => { action => 'changesettings', port => '8443', hostname => 'nas' });
  my ($conf) = grep { ($_->[0] // '') =~ m{tee /etc/easynas/easynas.conf} } @SYS;
  like $conf->[0], qr/^\/bin\/echo "EASYNAS_PORT=8443" \|/, 'port written to the conf';
  ok((grep { "@$_" eq '/usr/bin/sudo /usr/bin/systemd-run --collect --quiet /easynas/startup/web-port.sh --apply' } @SYS),
     'applied by web-port.sh, in its own unit');
  ok(!(grep { "@$_" =~ /systemctl (restart|daemon-reload)/ } @SYS), 'no restart of its own');

  @SYS = ();
  $tp->post_ok('/settings' => form => { action => 'changesettings', port => '8443x; reboot', hostname => 'nas' });
  is scalar @SYS, 0, 'a port that is not a number changes nothing';
}

# ===================== NAS accounts as administrators =====================
{
  no warnings 'redefine';
  my $hash = crypt('secret', '$6$testsalt$');
  local *EasyNAS::Controller::Login::read_admin_credential = sub { ('admin', $hash) };
  no warnings 'once';
  local *EasyNAS::Controller::Login::nas_user_ok = sub ($u, $p) { $p eq 'pw' ? 1 : 0 };
  my $orig = \&Mojo::Transaction::remote_address;
  local *Mojo::Transaction::remote_address = sub { my $tx = shift; @_ ? $tx->$orig(@_) : '192.0.2.20' };
  get '/whoami' => sub ($c) { $c->render(json => { role => $c->session('role'), nas_admin => $c->session('nas_admin'),
                                                    user => $c->session('user') }) };
  local %easynas::NAS_ADMIN = (alice => 1);

  my $tl = Test::Mojo->new;
  $tl->post_ok('/login' => form => { action => 'login', user => 'alice', pass => 'pw' })
     ->status_is(302)->header_is(Location => '/', 'an administrator lands on the dashboard');
  $tl->get_ok('/whoami')->json_is('/role' => 'admin')->json_is('/nas_admin' => 1)->json_is('/user' => 'alice');
  ok((grep { $_->[2] eq 'NAS user alice signed in as an administrator' } @easynas::LOG), 'logged');
  {
    local $easynas::SETUP = 1;
    Test::Mojo->new->post_ok('/login' => form => { action => 'login', user => 'alice', pass => 'pw' })
      ->status_is(302)->header_is(Location => '/wizard', '...or on the setup wizard while the appliance is new');
  }

  $tl = Test::Mojo->new;
  $tl->post_ok('/login' => form => { action => 'login', user => 'alice', pass => 'nope' })
     ->content_like(qr/Bad Username or Password/, 'an administrator still needs the right password');
  $tl = Test::Mojo->new;
  $tl->post_ok('/login' => form => { action => 'login', user => 'bob', pass => 'pw' })
     ->content_like(qr/Bad Username or Password/,
                    'not an administrator, and no add-on open to NAS users: no sign-in');
  $tl->get_ok('/whoami')->json_is('/role' => undef);
}

# ===================== Users page =====================
{
  no warnings qw(redefine once);
  my @pw;
  local *EasyNAS::Controller::Users::set_passwords = sub { push @pw, [@_]; '' };
  any '/users' => sub ($c) { EasyNAS::Controller::Users::view($c) };
  my $tu = Test::Mojo->new;
  $tu->get_ok('/signin');
  my $cmd = sub ($tool) { [grep { ($_->[1] // '') eq $tool } @SYS] };
  local %easynas::NAS_ADMIN = (alice => 1);

  # The form and the list
  $tu->get_ok('/users?action=createusermenu')->status_is(200)
     ->element_exists('form[method="post"][action="/users"] input[name="admin"][type="checkbox"]')
     ->content_like(qr/Administrator/);
  $tu->get_ok('/users')->status_is(200)
     ->element_exists('form[method="post"] input[name="action"][value="deleteuser"]', 'delete is a POST')
     ->content_like(qr{alice\s*<span class="label label-primary"[^>]*>Administrator</span>}, 'administrators are marked');
  unlike $tu->tx->res->body, qr{bob\s*<span class="label}, '...others are not';
  $tu->get_ok('/users?action=settingsmenu&username=alice')
     ->element_exists('input[name="admin"][checked]', 'settings: Administrator ticked for an administrator')
     ->element_exists('input[name="groups"][value="staff"][checked]', '...and the groups the user is in');
  $tu->get_ok('/users?action=settingsmenu&username=bob')
     ->element_exists_not('input[name="admin"][checked]')
     ->element_exists_not('input[name="groups"][value="staff"][checked]');

  # Changes only by POST: a link can't create an administrator.
  @SYS = ();
  $tu->get_ok('/users?action=createuser&name=evil&password1=x&password2=x&admin=1');
  is scalar @SYS, 0, 'GET changes nothing';
  $tu->get_ok('/users?action=deleteuser&username=bob');
  is scalar @SYS, 0, '...not even a delete';

  # Create an administrator
  @SYS = (); @pw = ();
  $tu->post_ok('/users' => form => { action => 'createuser', name => 'carol', desc => "Carol: IT\n",
                                     password1 => 'p w$', password2 => 'p w$', groups => ['staff', 'nosuch'], admin => 1 })
     ->content_like(qr/User created successfully/);
  is_deeply $cmd->('/usr/sbin/groupadd')->[0], ['/usr/bin/sudo', '/usr/sbin/groupadd', '--system', 'easynas-admins'],
    'the admin group is created when missing' if !getgrnam('easynas-admins');
  is_deeply $cmd->('/usr/sbin/useradd')->[0],
    ['/usr/bin/sudo', '/usr/sbin/useradd', '-g', 'users', '-d', '/mnt', '-c', 'Carol IT',
     '-G', 'staff,easynas-admins', '--', 'carol'],
    'useradd: no shell, unknown groups dropped, admin group added, description cleaned';
  is_deeply \@pw, [['carol', 'p w$']], 'password set, handed over as data';

  @SYS = ();
  $tu->post_ok('/users' => form => { action => 'createuser', name => 'dave', password1 => 'a', password2 => 'a' })
     ->content_like(qr/User created successfully/);
  is_deeply [grep { $_ eq '-G' } @{$cmd->('/usr/sbin/useradd')->[0]}], [], 'no groups ticked: no -G';
  is scalar @{$cmd->('/usr/sbin/groupadd')}, 0, 'not an administrator: no admin group';

  @SYS = ();
  $tu->post_ok('/users' => form => { action => 'createuser', name => 'x;reboot', password1 => 'a', password2 => 'a' })
     ->content_like(qr/A user name starts with a letter/);
  is scalar @SYS, 0, 'a bad name runs nothing';

  # Take the flag away / give it
  @SYS = (); @easynas::LOG = ();
  $tu->post_ok('/users' => form => { action => 'changesettings', username => 'alice', desc => 'Alice', groups => ['staff'] })
     ->content_like(qr/Settings Saved/);
  is_deeply $cmd->('/usr/sbin/usermod')->[0],
    ['/usr/bin/sudo', '/usr/sbin/usermod', '-g', 'users', '-G', 'staff', '-d', '/mnt', '-c', 'Alice', '--', 'alice'],
    'unticked: the admin group is dropped from the list';
  ok((grep { $_->[2] eq 'user alice is no longer an administrator' } @easynas::LOG), 'logged');

  @SYS = (); @easynas::LOG = ();
  $tu->post_ok('/users' => form => { action => 'changesettings', username => 'bob', desc => 'Bob', admin => 1 });
  is $cmd->('/usr/sbin/usermod')->[0][5], 'easynas-admins', 'ticked: the admin group is added';
  ok((grep { $_->[2] eq 'user bob made an administrator' } @easynas::LOG), 'logged');

  @SYS = ();
  $tu->post_ok('/users' => form => { action => 'changesettings', username => 'root', admin => 1 })
     ->content_like(qr/Settings failed to be saved/);
  $tu->post_ok('/users' => form => { action => 'deleteuser', username => 'root' })
     ->content_like(qr/Failed to delete user/);
  $tu->post_ok('/users' => form => { action => 'changepassword', username => 'root', password1 => 'a', password2 => 'a' })
     ->content_like(qr/Failed to change the password/);
  is scalar @SYS, 0, 'accounts the page does not list are left alone';

  @SYS = ();
  $tu->post_ok('/users' => form => { action => 'deleteuser', username => 'bob' })->content_like(qr/User deleted/);
  is_deeply $cmd->('/usr/sbin/userdel')->[0], ['/usr/bin/sudo', '/usr/sbin/userdel', '-f', 'bob'], 'userdel, no shell';
}

# ===================== profile: change your own password =====================
{
  no warnings qw(redefine once);
  my (@set, @admin_set);
  local *EasyNAS::Controller::Users::set_passwords      = sub { push @set, [@_]; '' };
  local *EasyNAS::Controller::Users::set_admin_password = sub { push @admin_set, [@_]; '' };
  local *EasyNAS::Controller::Login::nas_user_ok = sub ($u, $p) { $p eq 'old' ? 1 : 0 };
  local *EasyNAS::Controller::Login::admin_ok    = sub ($u, $p) { $u eq 'admin' && $p eq 'adminpw' ? 1 : 0 };
  my $orig = \&Mojo::Transaction::remote_address;
  my $ip = '192.0.2.30';
  local *Mojo::Transaction::remote_address = sub { my $tx = shift; @_ ? $tx->$orig(@_) : $ip };
  any '/profile' => sub ($c) { EasyNAS::Controller::Profile::view($c) };
  get '/signin_as' => sub ($c) {
    $c->session(is_auth => 1, role => $c->param('role'), user => $c->param('user'),
                nas_admin => $c->param('nas_admin') ? 1 : undef);
    $c->render(text => 'ok');
  };
  my $change = sub ($t, %f) { $t->post_ok('/profile' => form => { action => 'changepassword', %f }) };

  # A NAS user, signed in for the file manager
  my $tp = Test::Mojo->new;
  $tp->get_ok('/signin_as?role=user&user=bob');
  $tp->get_ok('/profile')->status_is(200)
     ->element_exists('nav#user-frame', 'a NAS user gets the bare frame')
     ->element_exists('form[method="post"][action="/profile"] input[name="current"][type="password"]')
     ->element_exists('input[name="password1"]')->element_exists('input[name="password2"]')
     ->content_like(qr/also your password for the file shares/);

  @set = ();
  $change->($tp, current => 'nope', password1 => 'new1', password2 => 'new1')
     ->content_like(qr/The current password is not right/);
  is scalar @set, 0, 'wrong current password: nothing changed';
  $change->($tp, current => 'old', password1 => 'new1', password2 => 'new2')
     ->content_like(qr/The new passwords don&#39;t match/);
  $change->($tp, current => 'old', password1 => '', password2 => '')
     ->content_like(qr/Enter a new password/);
  is scalar @set, 0, '...nor with a mismatch or an empty one';

  $tp->get_ok('/profile?action=changepassword&current=old&password1=x&password2=x');
  is scalar @set, 0, 'a GET changes nothing';

  @easynas::LOG = ();
  $change->($tp, current => 'old', password1 => 'n3w pw', password2 => 'n3w pw')
     ->content_like(qr/Your password has been changed\. It is your password for the file shares/);
  is_deeply \@set, [['bob', 'n3w pw']], 'system and Samba passwords set for that account';
  ok((grep { $_->[2] eq 'bob changed their own password' } @easynas::LOG), 'logged');
  $change->($tp, username => 'alice', current => 'old', password1 => 'x', password2 => 'x');
  is $set[-1][0], 'bob', 'always the signed-in account, whatever the form says';

  # Wrong current passwords count towards the sign-in lockout
  $ip = '192.0.2.31';
  $change->($tp, current => 'nope', password1 => 'x', password2 => 'x') for 1 .. 5;
  @set = ();
  $change->($tp, current => 'old', password1 => 'x', password2 => 'x')
     ->content_like(qr/Too many failed sign-in attempts/);
  is scalar @set, 0, 'locked out: not even the right one';
  $ip = '192.0.2.30';

  # The web administrator: admin.conf
  @set = (); @admin_set = ();
  my $ta = Test::Mojo->new;
  $ta->get_ok('/signin_as?role=admin&user=admin');
  $ta->get_ok('/profile')->element_exists_not('nav#user-frame', 'administrators get the normal layout')
     ->content_unlike(qr/file shares/);
  $change->($ta, current => 'old', password1 => 'a', password2 => 'a')->content_like(qr/not right/,
     'the admin is checked against admin.conf, not the NAS accounts');
  $change->($ta, current => 'adminpw', password1 => 'a2', password2 => 'a2')
     ->content_like(qr/Your password has been changed\.\s*</);
  is_deeply \@admin_set, [['a2']], 'admin.conf rewritten';
  is scalar @set, 0, '...and no system account touched';

  # A NAS account made an administrator: its own system password
  @set = (); @admin_set = ();
  my $tn = Test::Mojo->new;
  $tn->get_ok('/signin_as?role=admin&user=alice&nas_admin=1');
  $change->($tn, current => 'old', password1 => 'b', password2 => 'b');
  is_deeply \@set, [['alice', 'b']], 'a NAS administrator changes their system password';
  is scalar @admin_set, 0, '...not the admin one';
}

# ===================== the router's re-check =====================
# The real app: a NAS administrator's session ends once the flag is gone.
{
  unshift @INC, "$root/lib";
  require EasyNAS;
  # Mojolicious loads every file under EasyNAS/Controller at start; here that
  # would load the real helper module over its stand-in.
  { no warnings 'once'; *EasyNAS::warmup = sub {}; }
  # One add-on page, standing in for every admin page; it records what reached it.
  no warnings 'once';
  local %easynas::ADDONS = (nfs => { program => 'nfs' }, user_profile => { program => 'profile', access => 'all' });
  eval q{ package EasyNAS::Controller::Profile; no warnings 'redefine';
          sub view { shift->render(text => 'profile page') } 1 } or die $@;
  eval q{ package EasyNAS::Controller::Nfs; use Mojo::Base 'Mojolicious::Controller';
          sub view { my $c = shift; push @main::seen, [$c->req->method, $c->param('action') // '']; $c->render(text => 'nfs page') } 1 }
    or die $@;
  # A stand-in for the page behind the gate, so the real one isn't loaded.
  eval q{ package EasyNAS::Controller::Dashboard; use Mojo::Base 'Mojolicious::Controller';
          sub view { shift->render(text => 'dashboard') } 1 } or die $@;
  my $ta = Test::Mojo->new('EasyNAS');
  $ta->app->log->level('fatal');
  $ta->app->routes->get('/t_signin_user/:user' => sub ($c) {
    $c->session(is_auth => 1, role => 'user', nas_admin => undef, user => $c->param('user'));
    $c->render(text => 'ok');
  });
  $ta->app->routes->get('/t_signin/:user' => sub ($c) {
    $c->session(is_auth => 1, role => 'admin', nas_admin => 1, user => $c->param('user'));
    $c->render(text => 'ok');
  });
  local %easynas::NAS_ADMIN = (alice => 1);
  $ta->get_ok('/t_signin/alice');
  $ta->get_ok('/')->status_is(200)->content_is('dashboard', 'still an administrator: let through');
  delete $easynas::NAS_ADMIN{alice};
  @easynas::LOG = ();
  $ta->get_ok('/')->status_is(302)->header_like(Location => qr{/login$}, 'flag taken away: sent to sign in');
  ok((grep { $_->[2] eq 'signed alice out: no longer an administrator' } @easynas::LOG), 'logged');
  $easynas::NAS_ADMIN{alice} = 1;
  $ta->get_ok('/')->status_is(302, '...and the session is over, even if the flag comes back');

  # ---- changes by POST only
  $ta->get_ok('/t_signin/alice');
  @main::seen = (); @easynas::LOG = ();
  $ta->get_ok('/nfs?action=delete&share=pool/vol')->status_is(302)
     ->header_like(Location => qr{/nfs$}, 'a GET asking for a change: sent back to the bare page');
  is_deeply \@main::seen, [], '...and the page never ran';
  ok((grep { $_->[1] eq 'WARNING' && $_->[2] =~ m{refused a GET of /nfs asking for action "delete"} } @easynas::LOG), 'logged');
  $ta->get_ok('/?action=reboot')->status_is(302, 'same for the dashboard');
  $ta->get_ok('/firmware')->status_is(302)->header_like(Location => qr{/addons$}, 'the old Firmware page leads to Add-ons');
  @easynas::LOG = ();
  $ta->get_ok('/nfs?action=x%22%0A%3Cb%3E');
  like $easynas::LOG[0][2], qr/action "x\?\?\?b\?"/, 'the logged action is made harmless';

  @main::seen = ();
  $ta->get_ok('/nfs')->status_is(200)->content_is('nfs page');
  $ta->get_ok('/nfs?action=createmenu')->status_is(200, 'a "...menu" action is a GET');
  $ta->get_ok('/?action=progress')->status_is(200, 'so are the polled read-only ones');
  $ta->post_ok('/nfs' => form => { action => 'delete', share => 'pool/vol' })->status_is(200);
  $ta->post_ok('/nfs?action=delete')->status_is(200, 'a POST may carry the action in its URL');
  is_deeply \@main::seen, [['GET', ''], ['GET', 'createmenu'], ['POST', 'delete'], ['POST', 'delete']],
    'what reached the page';

  # <access>all</access>: every signed-in account reaches it, a NAS user too
  $ta->get_ok('/t_signin_user/bob');
  $ta->get_ok('/profile')->status_is(200)->content_is('profile page', 'a NAS user reaches an "all" page');
  $ta->get_ok('/nfs')->status_is(403, '...but not an administrator\'s page');

  ok EasyNAS::view_action($_), "view action: $_" for qw(createmenu settingsmenu stats status progress display);
  ok !EasyNAS::view_action($_), "a change: $_" for qw(delete reboot nfson update refresh terminal menus);
}

done_testing;
