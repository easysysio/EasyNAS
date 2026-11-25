#!/usr/bin/perl
# Tests for the setup wizard (wizard.pm): its four steps -- user, filesystem,
# volume, Samba share -- run the Users, Filesystem, Volume and Samba pages' own
# functions with the wizard's choices, and pass on what they report; each
# step can take something that exists, or be skipped; finishing marks the
# wizard done.
#
# The controllers and templates are the real ones, against a stub of the
# easynas helper module; system() and backticks are recorded instead of run.
#
# Run: prove -v t/wizard-web.t      (needs Mojolicious)
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile tempdir);
use Mojolicious::Lite -signatures;
no warnings 'once';

my $root = curfile->dirname->dirname;
my $stub = tempdir;
sub put_file { my ($f, $s) = @_; open my $fh, ">", $f or die "$f: $!"; print $fh $s; close $fh }

# Every name the real module exports, as a do-nothing sub unless set below.
open(my $real, '<', "$root/lib/EasyNAS/Controller/easynas.pm") or die $!;
my ($exports) = do { local $/; <$real> } =~ /our \@EXPORT\s*=\s*qw\(([^)]*)\)/s or die 'no @EXPORT';
close $real;
put_file($stub->child('easynas.pm'), <<"EOF2");
package easynas;
use Exporter 'import';
our \@EXPORT = qw($exports);
our (\@LOG, %FS, %VOL, %DISK, \$DONE);
sub get_addon_info { return { name => \$_[0], program => \$_[0], service => 'smb.service', config => '/etc/samba/smb.conf' } }
sub get_lang_text  { our %TEXT; if (!%TEXT) { do '$root/lang/en-en/lang_english_easynas.pl'; do '$root/lang/en-en/lang_english_samba.pl' } return %TEXT }
sub write_log      { push \@LOG, [\@_] }
sub get_mount_dir  { '/mnt' }
sub get_group_default { 'users' }
sub get_admin_group { 'easynas-admins' }
sub is_nas_admin   { 0 }
sub users_info  { (alice => [1000, 'alice', 'Alice', 'users', 0]) }
sub groups_info { (users => [100, 'users']) }
sub fs_info     { (ROOT => [], %FS) }
sub vol_info    { %VOL }
sub disk_info   { %DISK }
sub setup_done  { \$DONE++; 1 }
sub setup_needed { 0 }
sub service_ctl  { my \$a = shift; system('/usr/bin/sudo', '/easynas/startup/easynas-root', 'service', \$a, \$_) for \@_; 1 }
# The root helper's storage commands, recorded like system() and answered from \@RC.
sub root_do      { push \@main::SYS, join(' ', 'easynas-root', \@_); my \$rc = shift(\@main::RC) // 0; return (\$rc == 0 ? 1 : 0, '') }
sub root_append  { push \@main::SYS, join(' ', 'root_append', \@_); 1 }
sub root_write   { push \@main::SYS, join(' ', 'root_write', \@_); 1 }
sub root_read    { '' }
for my \$n (\@EXPORT) { no strict 'refs'; *{\$n} = sub { return } unless defined &{\$n} }
1;
EOF2
$stub->child('layouts')->make_path;
put_file($stub->child('layouts', 'default.html.ep'), '<%= content %>');
unshift @INC, "$stub";

our (@SYS, @RC, @PIPE, %PW);
BEGIN {
  %PW = map { $_ => 1 } qw(root alice users);
  *CORE::GLOBAL::system   = sub { push @SYS, join(' ', @_); my $rc = shift(@RC) // 0; $? = $rc; return $rc };
  *CORE::GLOBAL::readpipe = sub { push @PIPE, $_[0]; $? = 0; return wantarray ? () : '' };
  *CORE::GLOBAL::getpwnam = sub { $PW{$_[0] // ''} ? ($_[0], 'x', 1000) : () };
  *CORE::GLOBAL::getgrnam = sub { $PW{$_[0] // ''} ? ($_[0], 'x', 100) : () };
}
require "$root/lib/EasyNAS/Controller/$_.pm" for qw(users filesystem volume samba wizard);

# The parts that write through a pipe to sudo.
my @SHARES;
{
  no warnings 'redefine';
  *EasyNAS::Controller::Users::set_passwords = sub { $PW{$_[0]} = 1; return '' };
  *EasyNAS::Controller::Samba::apply_share   = sub { my ($c) = @_; push @SHARES, [$c->param('name'), $c->param('vol'), $c->param('readonly'), $c->param('guest')] };
}

app->secrets(['test']);
app->renderer->paths(["$stub", "$root/templates"]);
any '/wizard' => sub ($c) { EasyNAS::Controller::Wizard::view($c) };
my $t = Test::Mojo->new;
$t->ua->max_redirects(0);
my $post = sub { my ($form) = @_; @SYS = (); @PIPE = (); $t->post_ok('/wizard' => form => $form) };
# All the text inside the first element $sel matches.
my $all_like = sub { my ($sel, $re, $name) = @_; my $e = $t->tx->res->dom->at($sel); like $e ? $e->all_text : '', $re, $name // "$sel text"; };
my $next = sub { my ($step) = @_; $t->status_is(302)->header_is(Location => "/wizard?step=$step") };

%easynas::DISK = (sda => ['sda', 'sat', '32G', 'disk_system', 'SYS'],
                  sdb => ['sdb', 'sat', '4T',  'disk_free',   'WD'],
                  sdc => ['sdc', 'sat', '4T',  'disk_used',   'WD'],
                  sdd => ['sdd', 'sat', '4T',  'disk_free',   'WD']);

# ---- 1: user
$t->get_ok('/wizard')->status_is(200)
  ->element_exists('#wizard-steps li.active', 'the steps are shown')
  ->text_like('#wizard-steps li.active a' => qr/1\.\s+User/)
  ->element_exists('form#wizard-user-new[method=post] input[name=user_name]')
  ->element_exists('form#wizard-user-existing select[name=existing] option[value=alice]', 'an existing user can be picked');

$post->({action => 'user', mode => 'new', user_name => 'carol', password1 => 'a', password2 => 'b'});
$next->(1);
ok !grep(/useradd/, @SYS), 'passwords differ: no account';
$t->get_ok('/wizard?step=1')->text_like('.alert-danger' => qr/match/i, 'and says why');

$post->({action => 'user', mode => 'new', user_name => 'bad name', password1 => 'a', password2 => 'a'});
$next->(1);
ok !grep(/useradd/, @SYS), 'a bad name: no account';

$post->({action => 'user', mode => 'new', user_name => 'carol', password1 => 'pw', password2 => 'pw'});
$next->(2);
like $SYS[0], qr{^/usr/bin/sudo /usr/sbin/useradd -g users -d /mnt -c  -- carol$}, 'createuser made a plain user, in no extra group';

$post->({action => 'user', mode => 'existing', existing => 'mallory'});
$next->(1);

# ---- 2: filesystem
$t->get_ok('/wizard?step=1')->text_like('#wizard-chosen' => qr/carol/, 'the user picked is shown');
$t->get_ok('/wizard?step=2')->status_is(200)
  ->element_exists('input[name=disks][value=sdb]', 'a free disk is offered')
  ->element_exists('input[name=disks][value=sdd]')
  ->element_exists_not('input[name=disks][value=sda]', 'the system disk is not')
  ->element_exists_not('input[name=disks][value=sdc]', 'nor one in use')
  ->element_exists('input[name=fs_name][value=data]', 'named "data" to start with')
  ->element_exists('input[name=erase][required]')
  ->element_exists_not('#wizard-fs-existing', 'no filesystem to pick yet');

$post->({action => 'fs', disks => 'sdb', fs_name => 'data'});
$next->(2);
ok !grep(/mkfs/, @SYS), 'not confirmed: nothing erased';
$t->get_ok('/wizard?step=2')->text_like('.alert-danger' => qr/Tick the box/);

$post->({action => 'fs', disks => 'sda', fs_name => 'data', erase => 1});
$next->(2);
ok !grep(/mkfs/, @SYS), 'the system disk is refused even when sent';

$post->({action => 'fs', disks => 'sdb', fs_name => 'bad name', erase => 1});
$next->(2);
ok !grep(/mkfs/, @SYS), 'a bad filesystem name is refused';

$post->({action => 'fs', disks => ['sdb', 'sdd'], fs_name => 'data', erase => 1});
$next->(3);
my ($mkfs) = grep /mkfs/, @SYS;
is $mkfs, 'easynas-root fs mkfs data raid1 /dev/sdb /dev/sdd', 'two disks: mirrored';
ok grep(m{^root_append /etc/fstab LABEL=data /mnt/data btrfs rw 0 0$}, @SYS), 'mounted read-write at boot';
$post->({action => 'fs', disks => 'sdb', fs_name => 'one', erase => 1});
($mkfs) = grep /mkfs/, @SYS;
is $mkfs, 'easynas-root fs mkfs one single /dev/sdb', 'one disk: as it is';
%easynas::FS = (data => []);

$post->({action => 'fs', mode => 'existing', existing => 'ROOT'});
$next->(2);
$post->({action => 'fs', mode => 'existing', existing => 'data'});
$next->(3);

# ---- 3: volume
$t->get_ok('/wizard?step=3')->status_is(200)
  ->element_exists('select[name=fs] option[value=data][selected]', 'on the filesystem from step 2')
  ->element_exists('input[name=vol_name][value=share]')
  ->element_exists('input[name=access][value=all][checked]', 'for all users to start with');
$all_like->('#wizard-vol-new' => qr/Only carol/, 'or only the user from step 1');

$post->({action => 'vol', vol_name => 'x;rm -rf', fs => 'data', access => 'all'});
$next->(3);
ok !grep(/subvolume/, @SYS), 'a bad volume name: nothing run';
$t->get_ok('/wizard?step=3')->text_like('.alert-danger' => qr/volume name/);

$post->({action => 'vol', vol_name => 'share', fs => 'nope', access => 'all'});
$next->(3);
ok !grep(/subvolume/, @SYS), 'not a filesystem: nothing run';

$post->({action => 'vol', vol_name => 'share', fs => 'data', access => 'only'});
$next->(4);
is_deeply \@SYS, ['easynas-root vol create data share',
                  'easynas-root vol owner data share carol users 700'], 'only carol: hers alone, through the root helper';

$post->({action => 'vol', vol_name => 'family', fs => 'data', access => 'all'});
$next->(4);
like $SYS[1], qr{^easynas-root vol owner data family \S+ users 770$}, 'all users: the users group shares it';

@RC = (256);
$post->({action => 'vol', vol_name => 'taken', fs => 'data', access => 'all'});
$next->(3);
is scalar(@SYS), 1, 'the subvolume failed: no chown';
$t->get_ok('/wizard?step=3')->text_like('.alert-danger' => qr/not created/, 'and it says so');
%easynas::VOL = ('data/share' => [256, 'share', 'data', '0'], 'data/family' => [257, 'family', 'data', '0']);

# ---- 4: share
$post->({action => 'vol', mode => 'existing', existing => 'data/nope'});
$next->(3);
$post->({action => 'vol', mode => 'existing', existing => 'data/share'});
$next->(4);
$t->get_ok('/wizard?step=4')->status_is(200)
  ->element_exists('input[name=share_name][value=share]', 'named after the volume')
  ->element_exists('select[name=vol] option[value="data/share"][selected]');

$post->({action => 'share', share_name => 'my share', vol => 'data/share'});
$next->(4);
is scalar(@SHARES), 0, 'a bad share name: nothing added';
$post->({action => 'share', share_name => 'share', vol => '../../etc'});
$next->(4);
is scalar(@SHARES), 0, 'not a volume: nothing added';

$post->({action => 'share', share_name => 'share', vol => 'data/share'});
$next->(5);
is_deeply \@SHARES, [['share', 'data/share', 'no', 'no']], 'shared read-write, for signed-in users';
ok grep(m{easynas-root service enable smb\.service}, @SYS) && grep(m{easynas-root service start nmb\.service}, @SYS), 'Samba started, and at boot';

{
  no warnings 'redefine';
  local *EasyNAS::Controller::Wizard::samba_ready = sub { 0 };
  $t->get_ok('/wizard?step=4')->element_exists('#wizard-no-samba a[href="/addons"]', 'no Samba add-on: says where to get it')
    ->element_exists_not('#wizard-share-new');
  @SHARES = ();
  $post->({action => 'share', share_name => 'x', vol => 'data/share'});
  $next->(4);
  is scalar(@SHARES), 0;
}

# ---- 5: done
$t->get_ok('/wizard?step=5')->status_is(200);
$all_like->('#wizard-summary' => qr/carol.*data.*data\/share.*share/s, 'a summary of the choices');
$t->text_like('#wizard-connect code' => qr{^\\\\[^\\]+\\share$}, 'how to connect from Windows')
  ->content_like(qr{smb://[^/]+/share}, 'and macOS/Linux');

# ---- moving around
$post->({action => 'skip', from => 1}); $next->(2);
$post->({action => 'skip', from => 4}); $next->(5);
$post->({action => 'back', from => 3}); $next->(2);
$post->({action => 'back', from => 1}); $next->(1);
$post->({action => 'skip', from => 'x'}); $next->(2);
$t->get_ok('/wizard?step=9')->text_like('#wizard-steps li.active a' => qr/1\./, 'an unknown step shows the first');
ok !$easynas::DONE, 'not marked done yet';

$post->({action => 'finish'});
$t->status_is(302)->header_is(Location => '/');
is $easynas::DONE, 1, 'finishing marks the wizard done';
$t->get_ok('/wizard?step=5');
$all_like->('#wizard-summary' => qr/Skipped/, 'and forgets the choices');

$post->({action => 'dismiss'});
$t->status_is(302)->header_is(Location => '/');
is $easynas::DONE, 2, 'closing it does too';

# ---- a GET changes nothing
@SYS = (); @PIPE = ();
$t->get_ok('/wizard?action=user&mode=new&user_name=eve&password1=x&password2=x')->status_is(200);
ok !grep(/useradd/, @SYS), 'a GET creates nothing';

done_testing;
