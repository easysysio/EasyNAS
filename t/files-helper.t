#!/usr/bin/perl
# Tests for the file manager's filesystem helper (lib/EasyNAS/files-helper.pl).
# It runs the real script, as the current user, against a throwaway root laid
# out like the appliance's mount point: <root>/<pool>/<volume>/...
#
#   prove t/files-helper.t
#
# Needs only core Perl. The recursive delete and copy use GNU rm/cp options, so
# those cases are skipped where /bin/cp isn't GNU (e.g. a macOS workstation).
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(realpath);
use JSON::PP ();

my $helper = $ENV{FILES_HELPER} || realpath(dirname(__FILE__) . '/../lib/EasyNAS/files-helper.pl');
ok(-f $helper, "helper found at $helper") or BAIL_OUT('no helper');

my $gnu  = (`/bin/cp --version 2>&1` // '') =~ /GNU/ || $ENV{FILES_HELPER} ? 1 : 0;
my $root = realpath(tempdir(CLEANUP => 1));
my $out  = realpath(tempdir(CLEANUP => 1));      # somewhere OUTSIDE the root
my $vol  = "$root/pool/vol";

sub put_file { my ($p, $c) = @_; open(my $f, '>', $p) or die "$p: $!"; print $f $c; close $f; }
sub slurp    { my $p = shift; open(my $f, '<', $p) or return undef; local $/; my $c = <$f>; close $f; $c; }

mkdir "$root/pool" or die; mkdir $vol or die; mkdir "$root/pool/vol2" or die;
mkdir "$vol/docs" or die;
put_file("$vol/a.txt", "alpha\n");
put_file("$vol/docs/b.txt", "bravo\n");
put_file("$out/secret.txt", "outside\n");
symlink($out, "$vol/escape_dir") or die;
symlink("$out/secret.txt", "$vol/escape_file") or die;
symlink("$vol/docs", "$vol/docs_link") or die;

# Run the helper; returns (decoded JSON or undef, exit code, raw stdout).
sub h {
  my ($args, $stdin) = @_;
  my $pid = open(my $fh, '-|');
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    if (defined $stdin) { open(STDIN, '<', $stdin) or exit 99; }
    else                { open(STDIN, '<', '/dev/null'); }
    open(STDERR, '>', '/dev/null');
    exec($^X, $helper, $root, @$args);
    exit 98;
  }
  my $raw = do { local $/; <$fh> } // '';
  close $fh;
  my $rc = $? >> 8;
  my $j = eval { JSON::PP->new->utf8->decode($raw) };
  return ($j, $rc, $raw);
}
sub names { my $j = shift; return { map { $_->{name} => $_ } @{ $j->{entries} || [] } }; }

# ---- listing and the protected levels
{
  my ($j) = h(['list', '']);
  ok($j->{ok} && names($j)->{pool}, 'root lists the pool');
  is($j->{protected}, 1, 'root is protected');
  is($j->{writable}, 0, 'root is never writable');
  ($j) = h(['list', 'pool']);
  ok(names($j)->{vol}, 'pool lists the volume');
  is($j->{writable}, 0, 'pool level is not writable');
  ($j) = h(['list', 'pool/vol']);
  is($j->{writable}, 1, 'inside a volume is writable');
  my $n = names($j);
  is($n->{'a.txt'}{type}, 'file', 'file entry');
  is($n->{'a.txt'}{size}, 6, 'file size');
  is($n->{docs}{type}, 'dir', 'dir entry');
  is($n->{docs_link}{type}, 'dir', 'symlink to a folder inside the root is a folder');
  ok($n->{docs_link}{link}, '...and flagged as a link');
  is($n->{escape_dir}{type}, 'other', 'symlink leaving the root is not a folder');
  is($n->{escape_dir}{readable}, 0, '...and not readable');
  is($n->{escape_file}{type}, 'other', 'symlink to a file outside is not a file');
}

# ---- staying inside the root
{
  for my $p ('..', '../', 'pool/../..', 'pool/vol/../../..', 'pool/vol/docs/../../../..') {
    my ($j, $rc) = h(['list', $p]);
    is($j->{error}, 'badpath', "list '$p' refused");
  }
  my ($j) = h(['list', 'pool/vol/escape_dir']);
  is($j->{error}, 'outside', 'cannot list through a symlink that leaves the root');
  ($j) = h(['stat', 'pool/vol/escape_file']);
  is($j->{error}, 'outside', 'cannot stat a file outside through a symlink');
  my (undef, $rc, $raw) = h(['read', 'pool/vol/escape_file']);
  unlike($raw, qr/outside\n\z/, 'cannot read a file outside through a symlink');
  isnt($rc, 0, '...and the read fails');
  ($j) = h(['mkdir', 'pool/vol/escape_dir', 'x']);
  is($j->{error}, 'outside', 'cannot mkdir through an escaping symlink');
  ok(!-e "$out/x", '...nothing was created outside');
  ($j) = h(['put', 'pool/vol/escape_dir', 'x.txt', 0, 3, 0], "$vol/a.txt");
  is($j->{error}, 'outside', 'cannot upload through an escaping symlink');
  ($j) = h(['copy', 'pool/vol/escape_dir', 'pool/vol/a.txt']);
  is($j->{error}, 'outside', 'cannot copy into an escaping symlink');
  ok(!-e "$out/a.txt", '...nothing was copied outside');
}

# ---- read / stat
{
  my ($j) = h(['stat', 'pool/vol/a.txt']);
  is($j->{size}, 6, 'stat size');
  my (undef, $rc, $raw) = h(['read', 'pool/vol/a.txt']);
  is($raw, "alpha\n", 'read returns the bytes');
  is($rc, 0, 'read exit 0');
  (undef, undef, $raw) = h(['read', 'pool/vol/docs_link/b.txt']);
  is($raw, "bravo\n", 'read through a symlink that stays inside');
  ($j) = h(['stat', 'pool/vol/docs']);
  is($j->{error}, 'notfile', 'a folder is not downloadable');
  ($j) = h(['stat', 'pool/vol/nope.txt']);
  is($j->{error}, 'notfound', 'missing file');
}

# ---- mkdir
{
  my ($j) = h(['mkdir', '', 'x']);         is($j->{error}, 'protected', 'no mkdir at the root');
  ($j) = h(['mkdir', 'pool', 'x']);        is($j->{error}, 'protected', 'no mkdir at pool level');
  ok(!-e "$root/x" && !-e "$root/pool/x", '...nothing created');
  ($j) = h(['mkdir', 'pool/vol', 'new']);  ok($j->{ok} && -d "$vol/new", 'mkdir inside a volume');
  ($j) = h(['mkdir', 'pool/vol', 'new']);  is($j->{error}, 'exists', 'mkdir twice');
  for my $bad ('', '.', '..', 'a/b', '../x') {
    ($j) = h(['mkdir', 'pool/vol', $bad]);
    is($j->{error}, 'badname', "mkdir name '$bad' refused");
  }
  ok(!-e "$root/pool/x", 'no escape through the name');
}

# ---- rename
{
  put_file("$vol/r1.txt", "r");
  my ($j) = h(['rename', 'pool/vol/r1.txt', 'r2.txt']);
  ok($j->{ok} && -f "$vol/r2.txt" && !-e "$vol/r1.txt", 'rename');
  ($j) = h(['rename', 'pool/vol/r2.txt', 'a.txt']);     is($j->{error}, 'exists', 'rename onto an existing name');
  ($j) = h(['rename', 'pool/vol/r2.txt', '../up.txt']); is($j->{error}, 'badname', 'rename cannot move upward');
  ($j) = h(['rename', 'pool/vol', 'vol9']);             is($j->{error}, 'protected', 'a volume cannot be renamed');
  ($j) = h(['rename', 'pool', 'pool9']);                is($j->{error}, 'protected', 'a pool cannot be renamed');
  ok(-d $vol, '...still there');
}

# ---- upload (put)
{
  put_file("$out/c1", "hello ");
  put_file("$out/c2", "world");
  put_file("$out/empty", "");
  my ($j) = h(['put', 'pool/vol', 'up.txt', 0, 11, 0], "$out/c1");
  ok($j->{ok} && !$j->{done}, 'first chunk accepted, not done');
  ok(!-e "$vol/up.txt", 'the file does not appear until complete');
  ok(!names((h(['list', 'pool/vol']))[0])->{'.up.txt.easynas-part'}, 'part file hidden from listings');
  ($j) = h(['put', 'pool/vol', 'up.txt', 3, 11, 0], "$out/c2");
  is($j->{error}, 'offset', 'out-of-order chunk refused');
  is($j->{have}, 6, '...and reports what it has');
  ($j) = h(['put', 'pool/vol', 'up.txt', 6, 11, 0], "$out/c2");
  ok($j->{ok} && $j->{done}, 'last chunk completes the upload');
  is(slurp("$vol/up.txt"), 'hello world', 'content assembled in order');
  ok(!-e "$vol/.up.txt.easynas-part", 'part file gone');

  ($j) = h(['put', 'pool/vol', 'up.txt', 0, 5, 0], "$out/c2");
  is($j->{error}, 'exists', 'no silent overwrite');
  is(slurp("$vol/up.txt"), 'hello world', '...original untouched');
  ($j) = h(['put', 'pool/vol', 'up.txt', 0, 5, 1], "$out/c2");
  ok($j->{ok} && $j->{done}, 'overwrite when asked');
  is(slurp("$vol/up.txt"), 'world', '...replaced');

  ($j) = h(['put', 'pool/vol', 'big.txt', 0, 2, 0], "$out/c2");
  is($j->{error}, 'toolarge', 'more bytes than announced refused');
  ok(!-e "$vol/big.txt" && !-e "$vol/.big.txt.easynas-part", '...nothing left behind');

  ($j) = h(['put', 'pool/vol', 'zero', 0, 0, 0], "$out/empty");
  ok($j->{ok} && $j->{done} && -f "$vol/zero" && -z "$vol/zero", 'empty file');

  ($j) = h(['put', 'pool', 'x.txt', 0, 5, 0], "$out/c2");
  is($j->{error}, 'protected', 'no upload at pool level');
  ($j) = h(['put', 'pool/vol', '../x.txt', 0, 5, 0], "$out/c2");
  is($j->{error}, 'badname', 'upload name cannot contain a path');
  ($j) = h(['put', 'pool/vol', 'docs', 0, 5, 1], "$out/c2");
  is($j->{error}, 'isdir', 'an upload never replaces a folder');

  # group shares: a setgid directory gets group-writable files
  mkdir "$vol/share"; chmod 02775, "$vol/share";
  SKIP: {
    skip 'setgid bit not kept here', 2 unless ((stat("$vol/share"))[2] & 02000);
    h(['put', 'pool/vol/share', 'g.txt', 0, 5, 0], "$out/c2");
    ok(((stat("$vol/share/g.txt"))[2] & 0020), 'file in a setgid share is group-writable');
    h(['put', 'pool/vol', 'p.txt', 0, 5, 0], "$out/c2");
    ok(!((stat("$vol/p.txt"))[2] & 0020), 'file elsewhere is not');
  }
}

# ---- copy / move
SKIP: {
  skip 'GNU cp/rm not available', 24 unless $gnu;
  my ($j) = h(['copy', 'pool/vol/docs', 'pool/vol/a.txt']);
  ok($j->{ok} && slurp("$vol/docs/a.txt") eq "alpha\n" && -f "$vol/a.txt", 'copy a file');
  ($j) = h(['copy', 'pool/vol/docs', 'pool/vol/a.txt']);
  is($j->{failed}[0]{error}, 'exists', 'copy never overwrites');
  ($j) = h(['copy', 'pool/vol', 'pool/vol/a.txt']);
  ok($j->{ok} && -f "$vol/a (copy).txt", 'copy beside the original gets a new name');
  ($j) = h(['copy', 'pool/vol', 'pool/vol/a.txt']);
  ok($j->{ok} && -f "$vol/a (copy 2).txt", '...and again');
  ($j) = h(['copy', 'pool/vol2', 'pool/vol/docs']);
  ok($j->{ok} && slurp("$root/pool/vol2/docs/b.txt") eq "bravo\n", 'copy a folder to another volume');
  ($j) = h(['copy', 'pool/vol/docs', 'pool/vol/docs']);
  is($j->{failed}[0]{error}, 'intoitself', 'a folder cannot be copied into itself');
  ($j) = h(['copy', 'pool/vol/docs_link', 'pool/vol/docs']);
  is($j->{failed}[0]{error}, 'intoitself', '...not through a symlink either');
  ($j) = h(['copy', 'pool/vol2', 'pool/vol/docs_link']);
  ok($j->{ok} && -l "$root/pool/vol2/docs_link", 'a symlink is copied as a link');
  ($j) = h(['copy', 'pool', 'pool/vol/a.txt']);
  is($j->{error}, 'protected', 'no copy to pool level');

  put_file("$vol/m.txt", "move me");
  ($j) = h(['move', 'pool/vol2', 'pool/vol/m.txt']);
  ok($j->{ok} && !-e "$vol/m.txt" && slurp("$root/pool/vol2/m.txt") eq 'move me', 'move a file');
  put_file("$vol/m.txt", "again");
  ($j) = h(['move', 'pool/vol2', 'pool/vol/m.txt']);
  is($j->{failed}[0]{error}, 'exists', 'move never overwrites');
  ok(-f "$vol/m.txt", '...source kept');
  ($j) = h(['move', 'pool/vol2', 'pool/vol']);
  is($j->{error}, 'protected', 'a volume cannot be moved');
  ok(-d $vol, '...still there');
  mkdir "$vol/tree"; mkdir "$vol/tree/sub";
  ($j) = h(['move', 'pool/vol/tree/sub', 'pool/vol/tree']);
  is($j->{failed}[0]{error}, 'intoitself', 'a folder cannot be moved into itself');
  ($j) = h(['move', 'pool/vol2', 'pool/vol/tree', 'pool/vol/nope']);
  is_deeply($j->{done}, ['tree'], 'a batch reports what worked');
  is($j->{failed}[0]{error}, 'notfound', '...and what did not');

  # ---- delete
  ($j) = h(['delete', 'pool/vol/m.txt']);
  ok($j->{ok} && !-e "$vol/m.txt", 'delete a file');
  ($j) = h(['delete', 'pool/vol2/docs']);
  ok($j->{ok} && !-e "$root/pool/vol2/docs", 'delete a folder with its contents');
  ($j) = h(['delete', 'pool/vol/docs_link']);
  ok($j->{ok} && !-e "$vol/docs_link" && -f "$vol/docs/b.txt", 'deleting a symlink leaves its target');
  ($j) = h(['delete', 'pool/vol/escape_dir']);
  ok($j->{ok} && -f "$out/secret.txt", 'deleting an escaping symlink leaves the outside alone');
  ($j) = h(['delete', 'pool/vol']);
  is($j->{error}, 'protected', 'a volume cannot be deleted');
  ($j) = h(['delete', 'pool']);
  is($j->{error}, 'protected', 'a pool cannot be deleted');
  ok(-d $vol && -f "$vol/a.txt", '...and nothing was');
}

# ---- the kernel has the last word on permissions
SKIP: {
  skip 'running as root: permissions are not enforced', 6 if $> == 0;
  mkdir "$vol/ro"; put_file("$vol/ro/keep.txt", "k"); chmod 0555, "$vol/ro";
  mkdir "$vol/hidden"; put_file("$vol/hidden/h.txt", "h"); chmod 0000, "$vol/hidden";
  my ($j) = h(['list', 'pool/vol/ro']);
  is($j->{writable}, 0, 'read-only folder reported as not writable');
  ($j) = h(['mkdir', 'pool/vol/ro', 'x']);
  is($j->{error}, 'denied', 'mkdir denied there');
  ($j) = h(['put', 'pool/vol/ro', 'x.txt', 0, 5, 0], "$out/c2");
  is($j->{error}, 'denied', 'upload denied there');
  ($j) = h(['delete', 'pool/vol/ro/keep.txt']);
  is($j->{failed}[0]{error}, 'denied', 'delete denied there');
  ($j) = h(['list', 'pool/vol/hidden']);
  is($j->{error}, 'denied', 'a folder without access cannot be listed');
  is(names((h(['list', 'pool/vol']))[0])->{hidden}{readable}, 0, '...and is shown as unreadable');
  chmod 0755, "$vol/ro", "$vol/hidden";
}

{
  my ($j) = h(['frobnicate']);
  is($j->{error}, 'badop', 'unknown op');
}

done_testing();
