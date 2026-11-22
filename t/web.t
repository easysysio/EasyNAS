#!/usr/bin/perl
# Tests for the Settings page's Repository tab and the sign-in throttle.
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
                 get_conf_hosts get_addons);
our \@LOG;
our \$UPDATE_STATE = '';
sub get_addon_info { return { name => \$_[0], program => \$_[0] } }
sub get_lang_text  { our %TEXT; do '$root/lang/en-en/lang_english_easynas.pl' or die \$@ if !%TEXT; return %TEXT }
sub write_log      { push \@LOG, [\@_] }
sub get_update_state { \$UPDATE_STATE }
sub get_conf_hosts { '/dev/null' }
sub get_addons     { () }
1;
EOF
$stub->child('layouts')->make_path;
put_file($stub->child('layouts', $_), '<%= content %>') for qw(default.html.ep login.html.ep);

unshift @INC, "$stub";
BEGIN {
  *CORE::GLOBAL::system = sub { push our @SYS, [@_]; my $rc = shift(our @RC) // 0; $? = $rc; return $rc };
}
require "$root/lib/EasyNAS/Controller/settings.pm";
require "$root/lib/EasyNAS/Controller/login.pm";

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
     ->status_is(302, 'another address signs in');
}

done_testing;
