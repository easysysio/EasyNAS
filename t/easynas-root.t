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

# stdin is empty, as from sudo with nothing piped in.
sub run {
  unlink "$d/calls";
  open(my $in, '<&', \*STDIN) or die $!; open(STDIN, '<', '/dev/null') or die $!;
  system($^X, $helper, @_);
  my $rc = $? >> 8;
  open(STDIN, '<&', $in) or die $!;
  return ($rc, slurp("$d/calls"));
}

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

# Whose files and directories (older releases gave /etc/easynas to easynas)
{
  my $tf = "$r/etc/easynas/tftp";
  my $good = "TFTP_USER=nobody\nTFTP_OPTIONS=\nTFTP_DIRECTORY=/mnt/data/vol \n";
  put($tf, "TFTP_OPTIONS=-c\n");            # a line the helper wouldn't write
  ($rc) = feed("TFTP_OPTIONS=-c\n", qw(file write /etc/easynas/tftp));
  is $rc, 0, 'lines already in a file only root can change may stay';
  chmod 0664, $tf;
  ($rc) = feed("TFTP_OPTIONS=-c\n", qw(file write /etc/easynas/tftp));
  is $rc, 2, '...not in a file others could have changed';
  ($rc, $err) = feed($good, qw(file write /etc/easynas/tftp));
  is $rc, 0, '...which can be rewritten with lines that pass' or diag $err;
  is sprintf('%o', (stat $tf)[2] & 07777), '644', '...and is then writable only by root';

  chmod 0775, "$r/etc/easynas";
  ($rc) = feed($good, qw(file write /etc/easynas/tftp));
  is $rc, 2, 'a directory on the way others can write to is refused';
  ($rc) = run(qw(file read /etc/easynas/tftp));
  is $rc, 2, '...for a read too';
  chmod 01775, "$r/etc/easynas";
  ($rc, $err) = feed($good, qw(file write /etc/easynas/tftp));
  is $rc, 0, '...unless it is sticky (/etc/easynas: root:easynas 1775)' or diag $err;
  chmod 0755, "$r/etc/easynas";

  rename "$r/etc/easynas/raddb", "$r/outside/raddb";
  symlink "$r/outside/raddb", "$r/etc/easynas/raddb";
  my $was = -e "$r/outside/raddb/clients.conf" ? slurp("$r/outside/raddb/clients.conf") : undef;
  ($rc) = feed("client a {\n", qw(file append /etc/easynas/raddb/clients.conf));
  is $rc, 2, 'a directory on the way that is a link is refused';
  is((-e "$r/outside/raddb/clients.conf" ? slurp("$r/outside/raddb/clients.conf") : undef), $was,
     '...nothing written through it');
  unlink "$r/etc/easynas/raddb"; rename "$r/outside/raddb", "$r/etc/easynas/raddb";
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
# ===================== storage =====================
# Fake programs: each records "<name> <args>"; btrfs `filesystem show <x>`
# prints $d/show/<x> (or $d/show/ALL), and fails when there is none.
mkdir "$d/bin"; mkdir "$d/show";
for my $p (qw(mkfs.btrfs wipefs mount umount smartctl du systemd-run)) {
  put("$d/bin/$p", "#!/bin/sh\necho \"$p \$*\" >> $d/calls\n");
  chmod 0755, "$d/bin/$p";
}
put("$d/bin/btrfs", <<"SH");
#!/bin/sh
echo "btrfs \$*" >> $d/calls
if [ "\$1 \$2" = "filesystem show" ]; then
  f="$d/show/\${3:-ALL}"
  [ -f "\$f" ] && cat "\$f" && exit 0
  exit 1
fi
exit 0
SH
chmod 0755, "$d/bin/btrfs";
$ENV{EASYNAS_BIN_DIR} = "$d/bin";

my $act = '11111111-2222-3333-4444-555555555555';
my $old = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
mkdir $_ for map { "$r$_" } qw(/sys /sys/class /sys/class/block /sys/fs /sys/fs/btrfs /proc /mnt/old);
mkdir "$r/sys/class/block/$_" for qw(sda sda/sda1 sda1 sdb sdc sdd sdd/holders sdd/holders/md0 sde sdf);
mkdir $_ for "$r/sys/fs/btrfs/$act", "$r/sys/fs/btrfs/$act/devices", "$r/sys/fs/btrfs/$act/devices/sde";
put("$r/proc/mounts", "/dev/sda1 / btrfs rw 0 0\n/dev/sdc $r/mnt/data btrfs rw 0 0\nproc /proc proc rw 0 0\n");
put("$r/proc/swaps", "Filename Type Size Used Priority\n");
put("$d/show/pool2", "Label: 'pool2'  uuid: 99999999-2222-3333-4444-555555555555\n");
put("$d/show/$old", "Label: 'old'  uuid: $old\n\tTotal devices 2 FS bytes used 1G\n"
                  . "\tdevid    1 size 1.00GiB used 0 path /dev/sdb\n\tdevid    2 size 1.00GiB used 0 path /dev/sdf\n");
put("$d/show/old", slurp("$d/show/$old"));
put("$d/show/$act", "Label: 'busy'  uuid: $act\n\tdevid    1 size 1G used 0 path /dev/sde\n");
my $root_uuid = 'cccccccc-2222-3333-4444-555555555555';
put("$d/show/$root_uuid", "Label: 'ROOT'  uuid: $root_uuid\n\tdevid    1 size 1G used 0 path /dev/sdb\n");

($rc, $calls) = run(qw(fs mkfs pool raid1 /dev/sdb /dev/sdf));
is $rc, 0, 'mkfs on two free disks';
like $calls, qr{^mkfs\.btrfs -f -L pool -d raid1 -m raid1 /dev/sdb /dev/sdf$}m, '...as the page asked';
for my $bad ([qw(pool single /dev/sda)], [qw(pool single /dev/sdc)], [qw(pool single /dev/sdd)],
             [qw(pool single /dev/sde)], [qw(pool raid1 /dev/sdb)], [qw(ROOT single /dev/sdb)],
             [qw(pool raid7 /dev/sdb)], ['po;ol', 'single', '/dev/sdb'], [qw(pool raid1 /dev/sdb /dev/sdb)],
             [qw(pool single /dev/nosuch)], [qw(pool single /dev/sdb;reboot)], [qw(pool2 single /dev/sdb)],
             [qw(pool single)]) {
  ($rc, $calls) = run('fs', 'mkfs', @$bad);
  is $rc, 2, "mkfs refused: @$bad";
  unlike $calls, qr/^mkfs/m, '...no mkfs';
}

($rc, $calls) = run('fs', 'wipe', $old);
is $rc, 0, 'wipe a file system that is not mounted';
like $calls, qr{^wipefs -f -o 0x10040 /dev/sdb\nwipefs -f -o 0x10040 /dev/sdf$}m, '...every member';
for my $bad ($act, $root_uuid, 'nosuchuuid', '99999999-0000-0000-0000-000000000000') {
  ($rc, $calls) = run('fs', 'wipe', $bad);
  is $rc, 2, "wipe refused: $bad";
  unlike $calls, qr/^wipefs/m, '...nothing wiped';
}

($rc, $calls) = run(qw(fs label old new));
is $rc, 0, 'rename a file system';
like $calls, qr{^btrfs filesystem label /dev/sdb new$}m, '...its label';
ok -d "$r/mnt/new" && !-e "$r/mnt/old", '...and its directory';
($rc) = run(qw(fs label busy x));
is $rc, 2, 'rename refused: no file system "busy" by that name';
($rc) = run(qw(fs label old ROOT));
is $rc, 2, 'rename refused: to ROOT';

($rc, $calls) = run(qw(fs mount data));
is $calls, "mount $r/mnt/data\n", 'mount: by its fstab line';
($rc, $calls) = run(qw(fs mount-label data rw,compress=zstd,noatime));
is $calls, "mount -t btrfs -o rw,compress=zstd,noatime LABEL=data $r/mnt/data\n", 'mount by label, with options';
($rc, $calls) = run(qw(fs remount data ro));
is $calls, "mount -o remount,ro $r/mnt/data\n", 'remount';
($rc, $calls) = run(qw(fs umount data));
is $calls, "umount $r/mnt/data\n", 'umount';
for my $bad ([qw(mount-label data rw,suid)], [qw(mount-label data rw,exec)], [qw(remount data ro,dev)],
             [qw(umount ROOT)], [qw(mount ../etc)], [qw(mount nosuch)], [qw(mount-label data)], [qw(mount --bind)]) {
  ($rc, $calls) = run('fs', @$bad);
  is $rc, 2, "refused: fs @$bad";
  is $calls, '', '...nothing run';
}
($rc) = run(qw(fs mkdir fresh));
ok $rc == 0 && -d "$r/mnt/fresh", 'mkdir /mnt/<name>';
($rc) = run(qw(fs rmdir fresh));
ok $rc == 0 && !-e "$r/mnt/fresh", 'rmdir it';
($rc) = run(qw(fs rmdir data));
is $rc, 2, 'rmdir refused: mounted';

($rc, $calls) = run(qw(fs balance start /mnt/data));
is $rc, 0, 'balance start';
like $calls, qr{^systemd-run --collect --quiet -p StandardOutput=append:\Q$r\E/var/log/easynas/balance\.log -p StandardError=append:\S+ -- \Q$d\E/bin/btrfs balance start \Q$r\E/mnt/data$}m,
     '...in its own unit, logging to balance.log';
($rc, $calls) = run(qw(fs balance pause /mnt/data));
is $calls, "btrfs balance pause $r/mnt/data\n", 'balance pause';
($rc, $calls) = run(qw(fs convert /mnt/data raid1));
like $calls, qr{-- \S+/btrfs balance start --force -dconvert=raid1 -mconvert=raid1 \Q$r\E/mnt/data$}m, 'convert';
($rc, $calls) = run(qw(fs scrub start /mnt/data));
like $calls, qr{-- \S+/btrfs scrub start -B \Q$r\E/mnt/data$}m, 'scrub';
($rc, $calls) = run(qw(fs replace /mnt/data /dev/sdc /dev/sdf));
like $calls, qr{-- \S+/btrfs replace start -B -f /dev/sdc /dev/sdf \Q$r\E/mnt/data$}m, 'replace a disk';
($rc, $calls) = run(qw(fs device-add /mnt/data /dev/sdf));
is $calls, "btrfs device add -f /dev/sdf $r/mnt/data\n", 'add a disk';
($rc, $calls) = run(qw(fs stats-reset /dev/sdc));
is $calls, "btrfs device stats -z /dev/sdc\n", 'reset a disk\'s error counters';
for my $bad ([qw(balance start /etc)], [qw(balance start /mnt/data/vol)], [qw(balance defrag /mnt/data)],
             [qw(convert /mnt/data raid9)], [qw(replace /mnt/data /dev/sdc /dev/sda)],
             [qw(device-add /mnt/data /dev/sdc)], [qw(device-remove /mnt/data sdc)], [qw(scrub start)]) {
  ($rc, $calls) = run('fs', @$bad);
  is $rc, 2, "refused: fs @$bad";
  is $calls, '', '...nothing run';
}

($rc, $calls) = run(qw(disk wipe /dev/sdb));
is $calls, "wipefs -f -o 0x10040 /dev/sdb\n", 'wipe a free disk';
for my $bad (qw(/dev/sda /dev/sdc /dev/sde /dev/sdd sdb)) {
  ($rc, $calls) = run('disk', 'wipe', $bad);
  is $rc, 2, "wipe refused: $bad (in use, or not a disk)";
}

# volumes
my ($me, $mygroup) = (scalar getpwuid($<), scalar getgrgid((split ' ', $()[0]));
($rc, $calls) = run(qw(vol create data music));
is $calls, "btrfs subvolume create $r/mnt/data/music\n", 'create a volume';
($rc, $calls) = run(qw(vol snapshot data vol snap1));
is $calls, "btrfs subvolume snapshot $r/mnt/data/vol $r/mnt/data/snap1\n", 'snapshot';
($rc, $calls) = run(qw(vol delete data vol));
is $calls, "btrfs subvolume delete $r/mnt/data/vol\n", 'delete';
($rc) = run('vol', 'owner', 'data', 'vol', $me, $mygroup, '750');
is $rc, 0, 'owner and mode';
is sprintf('%o', (stat "$r/mnt/data/vol")[2] & 07777), '750', '...set';
symlink("$r/outside", "$r/mnt/data/lnk");
for my $bad ([qw(create data vol)], [qw(create data ../x)], [qw(create data .snapshots)], [qw(create data @)],
             [qw(delete data lnk)], [qw(snapshot data vol vol)], [qw(create ../etc x)],
             ['owner', 'data', 'lnk', $me, $mygroup, '755'], ['owner', 'data', 'vol', $me, $mygroup, '4755'],
             ['owner', 'data', 'vol', 'nosuchuser42', $mygroup, '755'], [qw(create data)]) {
  ($rc, $calls) = run('vol', @$bad);
  is $rc, 2, "refused: vol @$bad";
  is $calls, '', '...nothing run';
}

# queries
($rc, $calls) = run(qw(query btrfs-show));
is $calls, "btrfs filesystem show\n", 'query btrfs-show';
($rc, $calls) = run(qw(query status replace /mnt/data));
is $calls, "btrfs replace status -1 $r/mnt/data\n", 'query status';
($rc, $calls) = run(qw(query du data vol));
is $calls, "du -h -s -- $r/mnt/data/vol\n", 'query du';
($rc, $calls) = run(qw(query smart-health /dev/sda));
is $calls, "smartctl -H /dev/sda\n", 'query smart-health';
mkdir $_ for "$r/proc/1234", "$r/proc/1234/fd", "$r/proc/99", "$r/proc/99/fd";
put("$r/proc/1234/comm", "smbd\n");
symlink("$r/mnt/data/vol/song.mp3", "$r/proc/1234/fd/3");
symlink("/", "$r/proc/1234/cwd");
symlink("$r/mnt/data2", "$r/proc/99/cwd");
open(my $q, '-|', $^X, $helper, qw(query holders /mnt/data)) or die;
my $held = do { local $/; <$q> };
close $q;
is $held, "smbd(1234)\n", 'query holders: what keeps a mount busy (not /mnt/data2)';
for my $bad ([qw(btrfs-df /etc)], ['smart-info', '/dev/sda;id'], [qw(du data ../..)], [qw(holders /)],
             [qw(status defrag /mnt/data)], [qw(btrfs-show --all-devices)], [qw(nosuch)]) {
  ($rc, $calls) = run('query', @$bad);
  is $rc, 2, "refused: query @$bad";
  is $calls, '', '...nothing run';
}

# fstab and easynas.cron, through `file`
put("$r/etc/fstab", "UUID=$root_uuid / btrfs defaults 0 0\n");
($rc, $err) = feed("LABEL=data /mnt/data btrfs rw,compress=zstd 0 0\n", qw(file append /etc/fstab));
is $rc, 0, 'fstab: a pool as the filesystem page writes it' or diag $err;
for my $bad ("LABEL=data /mnt/other btrfs rw 0 0", "/dev/sdb /mnt/x btrfs rw 0 0", "LABEL=x /mnt/x btrfs rw,suid 0 0",
             "LABEL=x /etc btrfs rw 0 0", "LABEL=x /mnt/x ext4 rw 0 0", "LABEL=x /mnt/x btrfs rw 0 1",
             "tmpfs /tmp tmpfs rw 0 0") {
  ($rc) = feed("$bad\n", qw(file append /etc/fstab));
  is $rc, 2, "fstab refuses: $bad";
}
mkdir "$r/etc/cron.d";
put("$r/etc/cron.d/easynas.cron", "0 */6 * * *  root /easynas/startup/check_update.pl\n0 1 * * * root /x /mnt/data/vol \n");
($rc) = feed("0 */6 * * *  root /easynas/startup/check_update.pl\n", qw(file write /etc/cron.d/easynas.cron));
is $rc, 0, 'easynas.cron: a job taken out';
($rc) = feed("* * * * * root /bin/sh -c id\n", qw(file append /etc/cron.d/easynas.cron));
is $rc, 2, '...none added';

# ===================== accounts, network, NFS, MariaDB, iSCSI =====================
# Fake programs record "<name> <args>", then what came on their stdin.
for my $p (qw(useradd usermod userdel groupadd groupdel chpasswd smbpasswd nmcli exportfs mysql
              tgt-setup-lun tgtadm)) {
  put("$d/bin/$p", "#!/bin/sh\necho \"$p \$*\" >> $d/calls\ncat >> $d/calls\n[ -e $d/fail-$p ] && exit 4\nexit 0\n");
  chmod 0755, "$d/bin/$p";
}
put("$d/bin/pdbedit", "#!/bin/sh\necho \"pdbedit \$*\" >> $d/calls\n[ -e $d/smb-known ]\n");
put("$d/bin/tgt-admin", "#!/bin/sh\necho \"tgt-admin \$*\" >> $d/calls\n[ \"\$1\" = --dump ] && echo '<target iqn.x:t>'\nexit 0\n");
chmod 0755, "$d/bin/pdbedit", "$d/bin/tgt-admin";
sub feed_calls { unlink "$d/calls"; my ($rc) = feed(@_); return ($rc, slurp("$d/calls")) }

# A real NAS-range account and group to work on, when this system has one.
my ($nas_user, $nas_uid);
setpwent();
while (my @pw = getpwent()) {
  if ($pw[2] >= 1000 && $pw[2] < 65000 && $pw[0] =~ /^[A-Za-z_][A-Za-z0-9_.-]{0,31}$/ && $pw[0] ne 'easynas') { ($nas_user, $nas_uid) = @pw[0, 2]; last }
}
endpwent();
my $nas_group;
setgrent();
while (my @gr = getgrent()) { if ($gr[2] >= 1000 && $gr[2] < 65000 && $gr[0] =~ /^[A-Za-z_][A-Za-z0-9_.-]{0,31}$/ && $gr[0] ne 'easynas') { $nas_group = $gr[0]; last } }
endgrent();
my $free = 'enastest' . $$;
$free = substr($free, 0, 32);

($rc, $calls) = run('user', 'add', $free, 'Carol IT', '');
is $rc, 0, 'user add';
is $calls, "useradd -g users -d /mnt -c Carol IT -- $free\n", '...in users, home /mnt, no extra groups';
SKIP: {
  skip 'no NAS-range group here', 2 unless $nas_group;
  ($rc, $calls) = run('user', 'add', $free, '', $nas_group);
  is $rc, 0, 'user add, in a NAS group';
  is $calls, "useradd -g users -d /mnt -c  -G $nas_group -- $free\n", '...with -G';
}
my $root_group = getgrgid(0);
for my $bad ([$free, 'x:y', ''], [$free, "a\nb", ''], [$free, 'x' x 129, ''], [$free, '', $root_group],
             [$free, '', 'nosuchgroup'], [$free, '', ',x'], ['root', '', ''], ['-o', '', ''], ['a b', '', ''],
             [$free, ''], [$free, '', '', 'extra']) {
  ($rc, $calls) = run('user', 'add', @$bad);
  is $rc, 2, "user add refused: @$bad";
  is $calls, '', '...nothing run';
}
for my $u ('root', 'nobody', $free, 'daemon') {
  ($rc, $calls) = run('user', 'delete', $u);
  is $rc, 2, "user delete refused: $u (not a NAS account)";
  is $calls, '', '...nothing run';
  ($rc, $calls) = feed_calls("pw\n", 'user', 'password', $u);
  is $rc, 2, "user password refused: $u";
}
SKIP: {
  skip 'no NAS-range account here', 9 unless $nas_user;
  ($rc, $calls) = run('user', 'set', $nas_user, 'Alice', '');
  is $rc, 0, 'user set';
  is $calls, "usermod -g users -G  -d /mnt -c Alice -- $nas_user\n", '...an empty -G clears the extra groups';
  ($rc, $calls) = run('user', 'delete', $nas_user);
  is $calls, "pdbedit -L -u $nas_user\nuserdel -f $nas_user\n", 'user delete: not in Samba, so no smbpasswd -x';
  put("$d/smb-known", '');
  ($rc, $calls) = run('user', 'delete', $nas_user);
  is $calls, "pdbedit -L -u $nas_user\nsmbpasswd -x $nas_user\nuserdel -f $nas_user\n", '...and out of Samba when it is there';
  unlink "$d/smb-known";
  ($rc, $calls) = feed_calls("s3cr:et\n", 'user', 'password', $nas_user);
  is $rc, 0, 'user password';
  is $calls, "chpasswd \n$nas_user:s3cr:et\nsmbpasswd -s -a $nas_user\ns3cr:et\ns3cr:et\n", '...on stdin, to chpasswd and Samba';
  put("$d/fail-smbpasswd", '');
  ($rc) = feed_calls("pw\n", 'user', 'password', $nas_user);
  is $rc, 3, '...Samba failing: 3';
  unlink "$d/fail-smbpasswd";
  ($rc, $calls) = feed_calls("a\nb\n", 'user', 'password', $nas_user);
  ok $rc == 0 && $calls =~ /^$nas_user:a$/m && $calls !~ /^b$/m, 'only the first line is the password';
  ($rc, $calls) = feed_calls("\n", 'user', 'password', $nas_user);
  is $rc, 2, 'an empty password: refused';
}

($rc, $calls) = run('group', 'add', $free);
is $calls, "groupadd -- $free\n", 'group add';
for my $bad (['add', $root_group], [qw(add -g)], [qw(delete users)], [qw(delete easynas-admins)], ['delete', $root_group],
             [qw(delete nosuchgroup)], [qw(add-admins x)], ['add', $free, 'extra'], [qw(rename a)]) {
  ($rc, $calls) = run('group', @$bad);
  is $rc, 2, "group refused: @$bad";
  is $calls, '', '...nothing run';
}
SKIP: {
  skip 'no NAS-range group here', 1 unless $nas_group;
  ($rc, $calls) = run('group', 'delete', $nas_group);
  is $calls, "groupdel -- $nas_group\n", 'group delete';
}
($rc, $calls) = run('group', 'add-admins');
is $calls, (getgrnam('easynas-admins') ? '' : "groupadd --system easynas-admins\n"), 'group add-admins, when missing';

# auth: against a scratch shadow file.
SKIP: {
  my $hash = crypt('right pw', '$6$abcdefgh$');
  skip 'no NAS-range account, or no SHA-512 crypt, here', 6 unless $nas_user && defined $hash && $hash =~ /^\$6\$/;
  put("$r/etc/shadow", "root:\$6\$x\$y:1::::::\n$nas_user:$hash:19000:0:99999:7:::\n");
  ($rc) = feed_calls("right pw\n", 'auth', $nas_user);
  is $rc, 0, 'auth: the right password';
  ($rc) = feed_calls("wrong\n", 'auth', $nas_user);
  is $rc, 1, 'auth: a wrong one';
  ($rc) = feed_calls("right pw", 'auth', $nas_user);
  is $rc, 0, '...no newline needed';
  put("$r/etc/shadow", "$nas_user:!$hash:19000:0:99999:7:::\n");
  ($rc) = feed_calls("right pw\n", 'auth', $nas_user);
  is $rc, 1, 'auth: a locked account';
  put("$r/etc/shadow", "$nas_user::19000:0:99999:7:::\n");
  ($rc) = feed_calls("\n", 'auth', $nas_user);
  is $rc, 2, 'auth: an empty password is refused';
  ($rc) = feed_calls("x\n", 'auth', $nas_user);
  is $rc, 1, 'auth: an account with no password never signs in';
}
for my $u ('root', 'nobody', 'nosuchuser', '-x') {
  ($rc) = feed_calls("x\n", 'auth', $u);
  is $rc, 2, "auth refused: $u";
}

# net: an interface that exists, not lo.
mkdir $_ for map { "$r$_" } qw(/sys/class/net /sys/class/net/eth0 /sys/class/net/lo);
($rc, $calls) = run(qw(net eth0 auto));
is $rc, 0, 'net auto';
is $calls, "nmcli con mod eth0 ipv4.method auto ipv4.gateway  ipv4.addresses  ipv4.dns \nnmcli con up eth0\n", '...DHCP, then up';
($rc, $calls) = run(qw(net eth0 manual 192.168.1.10 24 192.168.1.1 1.1.1.1 -));
is $calls, "nmcli con mod eth0 ipv4.method manual ipv4.addresses 192.168.1.10/24 ipv4.gateway 192.168.1.1 ipv4.dns 1.1.1.1\nnmcli con up eth0\n",
  'net manual';
($rc, $calls) = run(qw(net eth0 manual 10.0.0.2 8 - - -));
like $calls, qr{^nmcli con mod eth0 ipv4.method manual ipv4.addresses 10.0.0.2/8 ipv4.gateway  ipv4.dns $}m, '...no gateway, no DNS';
for my $bad ([qw(lo auto)], [qw(eth9 auto)], [qw(../eth0 auto)], [qw(eth0 auto x)], [qw(eth0 dhcp)],
             [qw(eth0 manual 300.1.1.1 24 - - -)], [qw(eth0 manual 10.0.0.1 33 - - -)], [qw(eth0 manual 10.0.0.1 0 - - -)],
             [qw(eth0 manual 10.0.0.1 24 x - -)], ['eth0', 'manual', '10.0.0.1', '24', '-', '1.1.1.1,2.2.2.2', '-'],
             [qw(eth0 manual 10.0.0.1 24 -)], ['eth0', 'manual', '10.0.0.1', '24', '-', '-', '+ipv4.routes']) {
  ($rc, $calls) = run('net', @$bad);
  is $rc, 2, "net refused: @$bad";
  is $calls, '', '...nothing run';
}

($rc, $calls) = run(qw(nfs reexport));
is $calls, "exportfs -ra\n", 'nfs reexport';
($rc) = run(qw(nfs reexport -v));
is $rc, 2, '...nothing else';

($rc, $calls) = run(qw(mysql databases));
is $calls, "mysql --batch --skip-column-names -e SHOW DATABASES\n", 'mysql databases';
($rc, $calls) = run(qw(mysql create shop_1));
is $calls, "mysql --batch --skip-column-names\nCREATE DATABASE IF NOT EXISTS `shop_1`;\n", 'mysql create';
($rc, $calls) = run(qw(mysql drop shop_1));
is $calls, "mysql --batch --skip-column-names\nDROP DATABASE IF EXISTS `shop_1`;\n", 'mysql drop';
for my $bad ([qw(drop mysql)], [qw(drop information_schema)], ['create', 'a`b'], ['create', 'a;b'], ['create', ''],
             [qw(create a b)], [qw(shell x)], [qw(databases x)]) {
  ($rc, $calls) = run('mysql', @$bad);
  is $rc, 2, "mysql refused: @$bad";
  is $calls, '', '...nothing run';
}
($rc, $calls) = feed_calls("it's a \\ pw\n", qw(mysql root-password));
is $rc, 0, 'mysql root-password';
like $calls, qr{^ALTER USER 'root'\@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD\('it\\'s a \\\\ pw'\);\nFLUSH PRIVILEGES;$}m,
  '...quotes and backslashes escaped';
($rc, $calls) = feed_calls("a\tb\n", qw(mysql root-password));
is $rc, 2, '...control characters refused';

# iscsi: the backing file in a volume, made by the helper.
mkdir $_ for "$r/mnt/data", "$r/mnt/data/vol";
mkdir "$r/etc/easynas"; mkdir "$r/etc/easynas/tgt";
($rc, $calls) = run(qw(iscsi create data vol disk1 2M iqn.2026-01.nas:disk1 192.168.1.0/24));
is $rc, 0, 'iscsi create';
is -s "$r/mnt/data/vol/disk1", 2 << 20, '...a 2M backing file';
is((stat "$r/mnt/data/vol/disk1")[2] & 07777, 0600, '...0600');
like $calls, qr{^tgt-setup-lun -n iqn.2026-01.nas:disk1 -d $r/mnt/data/vol/disk1 192.168.1.0/24$}m, '...the LUN';
is slurp("$r/etc/easynas/tgt/targets.conf"), "<target iqn.x:t>\n", '...and the targets saved';
($rc) = run(qw(iscsi create data vol disk1 2M iqn.2026-01.nas:disk1));
is $rc, 1, 'iscsi create: an existing file is not reused';
symlink "$r/etc/easynas/tgt/targets.conf", "$r/mnt/data/vol/link";
($rc) = run(qw(iscsi create data vol link 1M iqn.x:l));
ok $rc == 1 && slurp("$r/etc/easynas/tgt/targets.conf") eq "<target iqn.x:t>\n", '...nor a link: nothing written through it';
put("$d/fail-tgt-setup-lun", '');
($rc) = run(qw(iscsi create data vol disk2 1M iqn.x:d2));
ok $rc == 1 && !-e "$r/mnt/data/vol/disk2", 'tgt-setup-lun failing: the file is removed';
unlink "$d/fail-tgt-setup-lun";
for my $bad ([qw(create data nosuch d 1M iqn.x:a)], [qw(create ROOT vol d 1M iqn.x:a)], [qw(create data vol ../d 1M iqn.x:a)],
             [qw(create data vol -d 1M iqn.x:a)], [qw(create data vol d 0M iqn.x:a)], [qw(create data vol d 1T iqn.x:a)],
             [qw(create data vol d 1M -x)], [qw(create data vol d 1M iqn.x:a ALL)], [qw(create data vol d 1M)],
             [qw(delete 1;2)], [qw(delete)], [qw(delete tid=1)]) {
  ($rc, $calls) = run('iscsi', @$bad);
  is $rc, 2, "iscsi refused: @$bad";
  is $calls, '', '...nothing run';
}
($rc, $calls) = run(qw(iscsi delete 3));
is $calls, "tgt-admin --delete tid=3\ntgt-admin --dump\n", 'iscsi delete, then the targets saved';
($rc, $calls) = run(qw(query iscsi-targets));
is $calls, "tgtadm --lld iscsi --op show --mode target\n", 'query iscsi-targets';

done_testing;
