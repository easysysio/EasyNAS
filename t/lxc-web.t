#!/usr/bin/perl
# Tests for the LXC add-on's page: the container list, the Create form and
# what it hands lxc-helper.sh, delete/autostart/storage/terminal, and that it
# changes nothing on a GET.
#
# The controller and templates are the real ones, against a stub of the
# easynas helper module; system() and backticks are recorded instead of run.
#
# Run: prove -v t/lxc-web.t      (needs Mojolicious)
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile tempdir);
use Mojolicious::Lite -signatures;

my $root = curfile->dirname->dirname;
my $stub = tempdir;
sub put_file { my ($f, $s) = @_; open my $fh, ">", $f or die "$f: $!"; print $fh $s; close $fh }
put_file($stub->child('easynas.pm'), <<"EOF2");
package easynas;
use Exporter 'import';
our \@EXPORT = qw(get_addon_info get_lang_text write_log get_mount_dir vol_info);
our \@LOG;
sub get_addon_info { return { name => \$_[0], program => \$_[0] } }
sub get_lang_text  { our %TEXT; if (!%TEXT) { do '$root/lang/en-en/lang_english_easynas.pl'; do '$root/lang/en-en/lang_english_lxc.pl' } return %TEXT }
sub write_log      { push \@LOG, [\@_] }
sub get_mount_dir  { '/mnt' }
sub vol_info       { ('pool/data' => [256, 'data', 'pool', '1G']) }
1;
EOF2
$stub->child('layouts')->make_path;
put_file($stub->child('layouts', 'default.html.ep'), '<%= content %>');
unshift @INC, "$stub";

our (@SYS, @RC, %PIPE);
BEGIN {
  *CORE::GLOBAL::system   = sub { push @SYS, [@_]; my $rc = shift(@RC) // 0; $? = $rc; return $rc };
  *CORE::GLOBAL::readpipe = sub { my ($cmd) = @_; for (sort keys %PIPE) { return wantarray ? (map {"$_\n"} split /\n/, $PIPE{$_}) : $PIPE{$_} if index($cmd, $_) >= 0 } return wantarray ? () : '' };
}
require "$root/lib/EasyNAS/Controller/lxc.pm";

my $state = $stub->child('state')->make_path;
$EasyNAS::Controller::Lxc::STATE  = "$state";
$EasyNAS::Controller::Lxc::IMAGES = $stub->child('images').'';
put_file($EasyNAS::Controller::Lxc::IMAGES, join '', map { "$_\n" }
  'debian;trixie;arm64;default;20260101_05:24;/images/debian/trixie/arm64/default/20260101_05:24/',
  'debian;trixie;amd64;default;20260101_05:24;/images/debian/trixie/amd64/default/20260101_05:24/',
  'debian;trixie;arm64;cloud;20260101_05:24;/images/debian/trixie/arm64/cloud/20260101_05:24/',
  'alpine;3.23;arm64;default;20260101_05:24;/images/alpine/3.23/arm64/default/20260101_05:24/',
  'ubuntu;noble;amd64;default;20260101_05:24;/images/ubuntu/noble/amd64/default/20260101_05:24/');

$PIPE{'uname -m'} = 'aarch64';
$PIPE{'lxc-ls'} = join "\n",
  'NAME  STATE   AUTOSTART IPV4',
  'web   RUNNING 1         10.0.3.17, 172.17.0.1 ',
  'db    STOPPED 0         -';

app->renderer->paths(["$stub", "$root/templates"]);
any '/lxc' => sub ($c) { EasyNAS::Controller::Lxc::view($c) };
my $t = Test::Mojo->new;
my $helper = sub { [map { [@$_[2..$#$_]] } grep { ($_->[1] // '') eq '/easynas/startup/lxc-helper.sh' } @SYS] };

# ---- the list
$t->get_ok('/lxc')->status_is(200)
  ->content_like(qr{<td>web</td>\s*<td>RUNNING</td>\s*<td>10\.0\.3\.17, 172\.17\.0\.1</td>}, 'running, with its addresses')
  ->content_like(qr{<td>db</td>\s*<td>STOPPED</td>\s*<td>-</td>}, 'stopped')
  ->element_exists('a[data-post][href="?action=autostart&name=web&on=0"] i.fa-toggle-on', 'web starts at boot: the toggle turns it off')
  ->element_exists('a[data-post][href="?action=autostart&name=db&on=1"] i.fa-toggle-off', 'db does not')
  ->element_exists('a[data-post][href="?action=terminal&name=web"]')
  ->element_exists('a[data-post][href="?action=start&name=db"]')
  ->element_exists('a[data-post][href="?action=delete&name=db"]')
  ->content_like(qr/system disk, which a firmware update wipes/, 'warns: kept on the system disk');
unlike $t->tx->res->body, qr/location\.replace/, 'nothing being created: no reloading';

put_file("$state/new1", "creating\n");
put_file("$state/bad1", "failed\n");
$t->get_ok('/lxc')->content_like(qr{<td>new1</td>\s*<td><i class="fa fa-spinner})
  ->content_like(qr{<td>bad1</td>\s*<td class="text-danger">})
  ->element_exists('a[data-post][href="?action=delete&name=bad1"]', 'a failed one can be dismissed')
  ->content_like(qr/location\.replace/, 'reloads while one is being created');
unlink "$state/new1", "$state/bad1";

# ---- the Create form: this machine's default images only
$t->get_ok('/lxc?action=createlxcmenu')->status_is(200)
  ->element_exists('form[method="post"][action="/lxc"] input[name="action"][value="create"]')
  ->element_exists('option[value="debian:trixie"][selected]')
  ->element_exists('option[value="alpine:3.23"]')
  ->element_exists_not('option[value="ubuntu:noble"]', 'no amd64-only image on arm64');

# ---- create
@SYS = ();
$t->post_ok('/lxc' => form => { action => 'create', name => 'box', image => 'debian:trixie', network => 'lan', autostart => 1 })
  ->status_is(200)->content_like(qr/Downloading the image/);
is_deeply [grep { $_->[1] eq '/usr/bin/systemd-run' } @SYS],
  [['/usr/bin/sudo', '/usr/bin/systemd-run', '--collect', '--quiet', '--unit=easynas-lxc-create-box',
    '/easynas/startup/lxc-helper.sh', 'create', 'box', 'debian', 'trixie', 'arm64', 'lan', 1]],
  'runs the helper in its own unit, as list arguments';
@SYS = ();
$t->post_ok('/lxc' => form => { action => 'create', name => 'x;reboot', image => 'debian:trixie' })->content_like(qr/A name has letters/);
$t->post_ok('/lxc' => form => { action => 'create', name => 'web', image => 'debian:trixie' })->content_like(qr/already a container/);
$t->post_ok('/lxc' => form => { action => 'create', name => 'box2', image => 'ubuntu:noble' })->content_like(qr/Pick an image/, 'not an image for this machine');
$t->post_ok('/lxc' => form => { action => 'create', name => 'box2', image => 'debian:trixie;id' })->content_like(qr/Pick an image/);
is scalar(@SYS), 0, 'none of those ran anything';
$t->post_ok('/lxc' => form => { action => 'create', name => 'box3', image => 'alpine:3.23', network => 'bogus' });
is $SYS[-1][-2], 'nat', 'any other network is the private one';
is $SYS[-1][-1], 0, 'autostart off unless ticked';

# ---- delete, autostart, start
@SYS = ();
$t->post_ok('/lxc' => form => { action => 'delete', name => 'db' })->content_like(qr/Container deleted/);
$t->post_ok('/lxc' => form => { action => 'autostart', name => 'db', on => 1 });
$t->post_ok('/lxc' => form => { action => 'start', name => 'db' });
is_deeply $helper->(), [['delete', 'db'], ['autostart', 'db', 1], ['start', 'db']], 'helper calls';
@RC = (256);
$t->post_ok('/lxc' => form => { action => 'start', name => 'db' })->content_like(qr/reason is in \/var\/log\/easynas\/lxc\.log/, 'a failed start says where to look');
@RC = (256);
$t->post_ok('/lxc' => form => { action => 'delete', name => 'db' })->content_like(qr/That did not work/, 'a failure is reported');

# ---- storage
$t->get_ok('/lxc?action=storagemenu')->status_is(200)->element_exists('option[value="pool/data"]');
@SYS = ();
$t->post_ok('/lxc' => form => { action => 'setstorage', radio_sel => 'vol', vol => 'pool/data' })->content_like(qr/storage changed/);
$t->post_ok('/lxc' => form => { action => 'setstorage', radio_sel => 'vol', vol => '../etc' })->content_like(qr/Pick a volume/);
$t->post_ok('/lxc' => form => { action => 'setstorage', radio_sel => 'internal' });
is_deeply $helper->(), [['storage', '/mnt/pool/data'], ['storage', 'internal']], 'storage targets';

# ---- terminal
@SYS = ();
$t->post_ok('/lxc' => form => { action => 'terminal', name => 'web' })->status_is(302)
  ->header_like(Location => qr{^http://easynas:[0-9a-f]{32}\@(127\.0\.0\.1|localhost):8080/$}, 'to ttyd, with the credential');
my ($call) = @{$helper->()};
is_deeply [@$call[0, 1]], ['terminal', 'web'];
like $t->tx->res->headers->location, qr/\Q$call->[2]\E/, 'the same credential ttyd got';
@RC = (256);
$t->post_ok('/lxc' => form => { action => 'terminal', name => 'db' })->status_is(200)->content_like(qr/terminal did not start/);

# ---- a GET changes nothing (the router also refuses it before the page runs)
@SYS = ();
$t->get_ok('/lxc?action=delete&name=web')->status_is(200);
$t->get_ok('/lxc?action=create&name=box&image=debian:trixie');
is_deeply [grep { $_->[1] ne '/usr/bin/curl' } @SYS], [], 'GETs ran nothing';

done_testing;
