#!/usr/bin/perl
# Tests for startup/easynas-root, the root helper the web interface reaches
# through sudo: it only controls the units EasyNAS manages, with the actions
# it knows, and refuses everything else. systemctl is a fake that records
# what it was asked.
#
# Run: prove -v t/easynas-root.t      (core Perl only)
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;

my $helper = "$FindBin::Bin/../startup/easynas-root";
my $d = tempdir(CLEANUP => 1);
sub put { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub slurp { my ($f) = @_; open my $fh, '<', $f or return ''; local $/; my $s = <$fh>; close $fh; $s }

mkdir "$d/addons";
put("$d/addons/samba.easynas", "<addon>\n <name>samba</name>\n <service>smb.service</service>\n</addon>\n");
put("$d/addons/network.easynas", "<addon>\n <service>NetworkManager</service>\n</addon>\n");
put("$d/addons/empty.easynas", "<addon>\n <service></service>\n</addon>\n");
put("$d/addons/notes.txt", "<service>evil.service</service>\n");
put("$d/systemctl", "#!/bin/sh\necho \"\$*\" >> $d/calls\n[ -e $d/fail ] && exit 3\nexit 0\n");
chmod 0755, "$d/systemctl";
$ENV{EASYNAS_ADDONS_DIR} = "$d/addons";
$ENV{EASYNAS_SYSTEMCTL}  = "$d/systemctl";

sub run { unlink "$d/calls"; system($^X, $helper, @_); return ($? >> 8, slurp("$d/calls")) }

my ($rc, $calls) = run(qw(service start smb.service));
is $rc, 0, 'an add-on\'s service starts';
is $calls, "start smb.service\n", '...through systemctl';
($rc, $calls) = run(qw(service enable smb));
is $calls, "enable smb.service\n", '"smb" is smb.service';
($rc, $calls) = run(qw(service restart NetworkManager));
is $calls, "restart NetworkManager.service\n", 'declared without the suffix';
($rc, $calls) = run(qw(service stop nmb.service));
is $calls, "stop nmb.service\n", 'a unit the core manages';
($rc, $calls) = run(qw(service restart-later easynas.service));
is $calls, "--no-block restart easynas.service\n", 'restart-later: queued, returns at once';

put("$d/fail", '');
($rc) = run(qw(service start smb.service));
is $rc, 3, 'systemctl failing: its status';
unlink "$d/fail";

for my $bad (['service', 'start', 'sshd.service'], ['service', 'start', 'evil.service'],
             ['service', 'start', '.service'], ['service', 'start', 'smb.service;reboot'],
             ['service', 'start', '-H'], ['service', 'mask', 'smb.service'],
             ['service', 'start'], ['service', 'start', 'smb.service', 'nmb.service'],
             ['service'], ['tee', '/etc/shadow'], []) {
  ($rc, $calls) = run(@$bad);
  is $rc, 2, "refused: @$bad";
  is $calls, '', '...nothing run';
}

# ===================== file =====================
# The managed files under a scratch root (EASYNAS_ROOT_PREFIX).
my $r = "$d/root";
mkdir $_ for $r, map { "$r$_" } qw(/etc /etc/samba /etc/easynas /etc/easynas/rsyncd /etc/easynas/raddb /run /mnt /mnt/data /mnt/data/vol /outside);
$ENV{EASYNAS_ROOT_PREFIX} = $r;

# run the helper with $in on stdin; (exit status, stderr)
sub feed {
  my ($in, @args) = @_;
  open(my $p, '|-', "$^X $helper @args 2>$d/err") or die $!;
  print $p $in;
  close $p;
  return ($? >> 8, slurp("$d/err"));
}
sub ls_tmp { opendir(my $dh, $_[0]) or return (); return grep { /easynas-root\.\d+$/ } readdir $dh }

my $smb = "$r/etc/samba/smb.conf";
put($smb, "[global]\n   workgroup = WORKGROUP\n   log level = 1\n");
chmod 0640, $smb;
my $share = "#### music ####\n[music]\npath = /mnt/data/vol\nbrowsable = yes\nguest ok = no\nread only = no\n"
          . "force group = daemon\nvalid users = \@daemon\nwrite list = \@daemon\nvfs object = recycle\n"
          . "recycle:repository = recycle\nrecycle:touch = Yes\nrecycle:keeptree = Yes\nrecycle:exclude_dir = recycle\ncomment = music\n";
my ($err);
($rc, $err) = feed($share, qw(file append /etc/samba/smb.conf));
is $rc, 0, 'smb.conf: a share section as samba.pm writes it' or diag $err;
is slurp($smb), "[global]\n   workgroup = WORKGROUP\n   log level = 1\n$share", '...appended after what was there';
is sprintf('%o', (stat $smb)[2] & 07777), '640', '...the file keeps its mode';
is_deeply [ls_tmp("$r/etc/samba")], [], '...no temporary file left';

($rc, $calls) = run(qw(file read /etc/samba/smb.conf));
is $rc, 0, 'file read';
my $before = slurp($smb);
($rc, $err) = feed("[global]\n   workgroup = WORKGROUP\n   log level = 1\n", qw(file write /etc/samba/smb.conf));
is $rc, 0, 'a write that drops a share' or diag $err;
is slurp($smb), "[global]\n   workgroup = WORKGROUP\n   log level = 1\n", '...the lines already there may stay';

for my $bad ("root preexec = /bin/sh -c id", "[x]\npath = /etc", "force user = root", "force group = root",
             "valid users = root", "[global]", "[homes]", "include = /tmp/x.conf", "path = /mnt/../etc",
             "add user script = /bin/sh", "log file = /etc/cron.d/x", "vfs objects = recycle full_audit",
             "comment = a\x00b") {
  my $was = slurp($smb);
  ($rc, $err) = feed("$bad\n", qw(file append /etc/samba/smb.conf));
  is $rc, 2, "smb.conf refuses: $bad";
  is slurp($smb), $was, '...and stays as it was';
}
put($smb, $before);
($rc, $err) = feed("$before\n[global]\n", qw(file write /etc/samba/smb.conf));
is $rc, 2, 'a line that is there once may not be added again';

my $ex = "$r/etc/exports";
($rc, $err) = feed("/mnt/data/vol *(rw,sync,no_subtree_check)\n", qw(file append /etc/exports));
is $rc, 0, 'exports: a share as nfs.pm writes it' or diag $err;
is slurp($ex), "/mnt/data/vol *(rw,sync,no_subtree_check)\n", '...the file is made';
is sprintf('%o', (stat $ex)[2] & 07777), '644', '...0644';
for my $bad ("/mnt/data/vol *(rw,sync,no_subtree_check,no_root_squash)", "/ *(rw,sync,no_subtree_check)",
             "/mnt *(rw,sync,no_subtree_check)", "/mnt/data/vol 10.0.0.1(rw,sync,no_subtree_check)",
             "/etc *(ro,sync,no_subtree_check)") {
  ($rc) = feed("$bad\n", qw(file append /etc/exports));
  is $rc, 2, "exports refuses: $bad";
}

($rc, $err) = feed("#### bk ####\n[bk]\npath = /mnt/data/vol\nread only = yes\ncomment = bk\n",
                   qw(file append /etc/easynas/rsyncd/rsyncd.conf));
is $rc, 0, 'rsyncd.conf: a module as rsyncd.pm writes it' or diag $err;
for my $bad ("pre-xfer exec = /bin/sh", "uid = root", "path = /", "[global]", "post-xfer exec = /x") {
  ($rc) = feed("$bad\n", qw(file append /etc/easynas/rsyncd/rsyncd.conf));
  is $rc, 2, "rsyncd.conf refuses: $bad";
}

($rc, $err) = feed("#### sw ####\nclient sw {\nipaddr = 10.0.0.9\nsecret = s3cr!t\n}\n",
                   qw(file append /etc/easynas/raddb/clients.conf));
is $rc, 0, 'clients.conf: a client as radius.pm writes it' or diag $err;
for my $bad ("secret = `id`", "\$INCLUDE /etc/shadow", "secret = \${x}", "shortname = x", "client a {\nsecret = \"x\"") {
  ($rc) = feed("$bad\n", qw(file append /etc/easynas/raddb/clients.conf));
  is $rc, 2, "clients.conf refuses: $bad";
}

put("$r/etc/easynas/minidlna", "media_dir=/mnt\nport=8200\nuser=minidlna\n");
($rc, $err) = feed("media_dir=/mnt/data/vol\nport=8201\nuser=minidlna\nfriendly_name=EasyNAS\n", qw(file write /etc/easynas/minidlna));
is $rc, 0, 'minidlna: the settings dlna.pm changes; the user line already there may stay' or diag $err;
for my $bad ("user=root", "db_dir=/etc", "media_dir=/etc") {
  ($rc) = feed("$bad\n", qw(file append /etc/easynas/minidlna));
  is $rc, 2, "minidlna refuses: $bad";
}

($rc, $err) = feed("############ EasyNAS TFTP Config File ###########\nTFTP_USER=nobody\nTFTP_OPTIONS=\nTFTP_DIRECTORY=/mnt/data/vol \n",
                   qw(file write /etc/easynas/tftp));
is $rc, 0, 'tftp: as tftp.pm writes it' or diag $err;
for my $bad ("TFTP_OPTIONS=-c", "TFTP_USER=nosuchuser42", "TFTP_DIRECTORY=/", "TFTP_ADDRESS=0.0.0.0:69") {
  ($rc) = feed("$bad\n", qw(file append /etc/easynas/tftp));
  is $rc, 2, "tftp refuses: $bad";
}

put("$r/outside/x", "secret\n");
symlink("$r/outside/x", "$r/etc/exports.lnk");
unlink $ex; symlink("$r/outside/x", $ex);
($rc) = run(qw(file read /etc/exports));
is $rc, 2, 'a link is refused (read)';
($rc) = feed("/mnt/data/vol *(rw,sync,no_subtree_check)\n", qw(file append /etc/exports));
is $rc, 2, '...and written through';
is slurp("$r/outside/x"), "secret\n", '...its target untouched';
unlink $ex;

($rc, $calls) = run(qw(file read /etc/exports));
is $rc, 0, 'a file not there yet reads as empty';
for my $bad (['file', 'read', '/etc/shadow'], ['file', 'write', '/etc/sudoers'], ['file', 'read', '/etc/samba/../shadow'],
             ['file', 'chmod', '/etc/exports'], ['file', 'read'], ['file', 'read', '/etc/exports', 'x']) {
  ($rc) = feed('', @$bad);
  is $rc, 2, "refused: @$bad";
}

# ===================== share-marker =====================
SKIP: {
  skip 'share markers open the directory through /proc/self/fd (Linux)', 9 unless -d '/proc/self/fd';
  ($rc, $err) = feed("#### music ####\n", qw(share-marker write /mnt/data/vol smb));
  is $rc, 0, 'a share marker is written' or diag $err;
  is slurp("$r/mnt/data/vol/.easynas/smb.share"), "#### music ####\n", '...inside the volume';
  ($rc) = feed('', qw(share-marker remove /mnt/data/vol smb));
  ok !-e "$r/mnt/data/vol/.easynas/smb.share", '...and removed';
  ($rc) = feed('', qw(share-marker remove /mnt/data/vol nfs));
  is $rc, 0, 'removing one that is not there is fine';

  # a user of the volume swaps .easynas for a link elsewhere
  rmdir "$r/mnt/data/vol/.easynas";
  symlink("$r/outside", "$r/mnt/data/vol/.easynas");
  ($rc) = feed("x\n", qw(share-marker write /mnt/data/vol smb));
  is $rc, 2, '.easynas as a link: refused';
  ok !-e "$r/outside/smb.share", '...nothing written where it points';
  unlink "$r/mnt/data/vol/.easynas";
  for my $bad (['/mnt/data/../etc', 'smb'], ['/etc/x/y', 'smb'], ['/mnt/data/vol', 'cron']) {
    ($rc) = feed("x\n", 'share-marker', 'write', @$bad);
    is $rc, 2, "refused: share-marker write @$bad";
  }
}

# ===================== hostname =====================
put("$d/hostname", "#!/bin/sh\necho \"\$*\" >> $d/calls\n");
chmod 0755, "$d/hostname";
$ENV{EASYNAS_HOSTNAME_CMD} = "$d/hostname";
($rc, $calls) = run(qw(hostname nas-1.example));
is $rc, 0, 'hostname';
is $calls, "nas-1.example\n", '...set on the running system';
is slurp("$r/etc/hostname"), "nas-1.example\n", '...in /etc/hostname';
like slurp("$r/etc/hosts"), qr/^127\.0\.0\.1  localhost nas-1\.example$/m, '...and /etc/hosts';
for my $bad ('nas;reboot', '-n', 'a..b', 'x' x 64, 'nas name', '') {
  ($rc, $calls) = run('hostname', $bad);
  is $rc, 2, "refused host name: '$bad'";
  is $calls, '', '...nothing run';
}
done_testing;
