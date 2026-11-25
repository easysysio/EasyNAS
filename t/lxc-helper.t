#!/usr/bin/perl
# Tests for startup/lxc-helper.sh, the root side of the LXC add-on, against
# fake lxc-*, ip, systemctl and mount commands and paths in a temp dir.
#
# Run: prove -v t/lxc-helper.t      (core Perl and a POSIX shell only)
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $helper = abs_path(dirname(__FILE__) . '/../startup/lxc-helper.sh');
my $d = tempdir(CLEANUP => 1);
mkdir "$d/$_" for qw(bin lxc state aa mnt mnt/pool mnt/pool/data);
sub put { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub slurp { my ($f) = @_; open my $fh, '<', $f or return undef; local $/; my $s = <$fh>; close $fh; $s }

# Every fake logs "<tool> <args>" to calls; lxc-create copies the -f config it
# was given and makes the container, unless told to fail.
for my $tool (qw(systemctl lxc-destroy lxc-ls lxc-attach umount mount mountpoint systemd-run ss sleep)) {
  put("$d/bin/$tool", "#!/bin/sh\necho \"$tool \$*\" >> $d/calls\n" .
      ($tool eq 'mountpoint' ? "[ -e $d/mounted ]\n" : $tool eq 'lxc-ls' ? "cat $d/lxc-ls 2>/dev/null\n" : $tool eq 'ss' ? "echo LISTEN\n" : "exit 0\n"));
}
put("$d/bin/ip", "#!/bin/sh\necho \"ip \$*\" >> $d/calls\n" .
    "case \"\$*\" in *'route show default'*) echo 'default via 192.168.1.1 dev enp3s0 proto dhcp';; esac\n" .
    "[ -e $d/bridge ] || case \"\$*\" in 'link show lxcbr0') exit 1;; esac\nexit 0\n");
put("$d/bin/lxc-create", <<"SH");
#!/bin/sh
echo "lxc-create \$*" >> $d/calls
[ -e $d/fail-create ] && exit 1
while [ \$# -gt 0 ]; do case "\$1" in -n) n=\$2; shift 2;; -f) /bin/cp "\$2" $d/created.conf; shift 2;; --) break;; *) shift;; esac; done
mkdir -p $d/lxc/\$n/rootfs/etc && echo "lxc.uts.name = \$n" > $d/lxc/\$n/config
[ -e $d/no-shadow ] || printf 'root:*:19000:0:99999:7:::\\nbin:*:19000::::::\\n' > $d/lxc/\$n/rootfs/etc/shadow
SH
put("$d/bin/apparmor_parser", <<"SH");
#!/bin/sh
echo "apparmor_parser \$*" >> $d/calls
[ -e $d/fail-aa ] && exit 1
echo 'lxc-container-default-cgns (enforce)' >> $d/aa/profiles
SH
put("$d/bin/lxc-start", <<"SH");
#!/bin/sh
echo "lxc-start \$*" >> $d/calls
[ -e $d/fail-start ] && exit 1
exit 0
SH
put("$d/bin/lxc-info", "#!/bin/sh\n[ -e $d/running ] && echo RUNNING || echo STOPPED\n");
put("$d/bin/cp", "#!/bin/sh\necho \"cp \$*\" >> $d/calls\nexit 0\n");
chmod 0755, glob("$d/bin/*");
# The script is written for GNU sed (the appliance's); on a Mac use gsed.
if ($^O eq 'darwin') {
  chomp(my $gsed = `command -v gsed 2>/dev/null`);
  plan skip_all => 'needs GNU sed (brew install gnu-sed)' unless $gsed;
  symlink $gsed, "$d/bin/sed";
}

$ENV{PATH} = "$d/bin:$ENV{PATH}";
$ENV{EASYNAS_LXCPATH} = "$d/lxc";
$ENV{EASYNAS_LXC_STATE} = "$d/state";
$ENV{EASYNAS_LXC_LOG} = "$d/lxc.log";
$ENV{EASYNAS_FSTAB} = "$d/fstab";
$ENV{EASYNAS_LXC_DROPIN} = "$d/dropin/easynas-storage.conf";
$ENV{EASYNAS_LXC_NETCONF} = "$d/lxc-net";
$ENV{EASYNAS_AA_SYS} = "$d/aa";
$ENV{EASYNAS_AA_PROFILES} = "$d/lxc-containers";
$ENV{EASYNAS_LXC_PWDIR} = "$d/tmp";
mkdir "$d/tmp";
# A root password file as lxc.pm writes it: a SHA-512 crypt hash.
my $HASH = '$6$abcdefgh12345678$' . ('./AZaz09' x 11 . 'xyzw') =~ s/^(.{86}).*/$1/r;
my $pwn = 0;
sub pw { my ($h) = @_; my $f = sprintf("%s/tmp/easynas-lxc-pw.T%09d", $d, ++$pwn); put($f, ($h // $HASH) . "\n"); chmod 0600, $f; return $f }
put("$d/fstab", "/dev/sda1 /mnt/pool btrfs defaults 0 0\n");

sub run { unlink "$d/calls"; system('/bin/sh', $helper, @_); my $rc = $? >> 8; return ($rc, slurp("$d/calls") // '') }

# ---- the bridge
my ($rc, $calls) = run('net');
is $rc, 1, 'net: fails when lxcbr0 never appears';
put("$d/bridge", '');
($rc, $calls) = run('net');
is $rc, 0, 'net: ok once it is up';
is slurp("$d/lxc-net"), qq{USE_LXC_BRIDGE="true"\n}, 'bridge switched on';
like $calls, qr/systemctl enable lxc-net\.service lxc\.service/, 'bridge and autostart enabled';
like $calls, qr/apparmor_parser -r \Q$d\E\/lxc-containers\n(?:.*\n)*systemctl start lxc\.service/, 'profiles loaded, then lxc.service started';
($rc) = run('net');
is slurp("$d/lxc-net"), qq{USE_LXC_BRIDGE="true"\n}, 'written once';

# ---- create: only onto a volume
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1), pw());
is $rc, 1, 'create: refused before containers have a volume';
unlike $calls, qr/lxc-create/, '...nothing downloaded onto the system disk';
is slurp("$d/state/web"), "failed\n", '...and the page is told';
run(qw(delete web));
put("$d/fstab", "/dev/sda1 /mnt/pool btrfs defaults 0 0\n/mnt/pool/data/lxc $d/lxc none bind 0 0 # easynas-lxc-storage\n");
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1), pw());
is $rc, 1, 'create: refused while the volume is not mounted';
like $calls, qr/mount \Q$d\E\/lxc/, '...after trying to mount it';
unlike $calls, qr/lxc-create/;
run(qw(delete web));
put("$d/mounted", '');

# The root password, first.
my $f = pw();
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1));
is $rc, 1, 'create: refused without a root password';
unlike $calls, qr/lxc-create/;
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1), pw('plaintext'));
is $rc, 1, '...or with a file that holds no hash';
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1), '/etc/shadow');
is $rc, 1, '...or with some other file';
ok -e '/etc/shadow' || $^O ne 'linux', '...which is left alone';
symlink "$d/fstab", "$d/tmp/easynas-lxc-pw.Tlinklink1";
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1), "$d/tmp/easynas-lxc-pw.Tlinklink1");
is $rc, 1, '...or with a symlink';
ok -e "$d/fstab", '...whose target stays';

($rc, $calls) = run(qw(create web debian trixie arm64 nat 1), $f);
is $rc, 0, 'create: ok';
ok !-e $f, 'the password file is gone';
like slurp("$d/lxc/web/rootfs/etc/shadow"), qr/^\Qroot:$HASH:19000:0:99999:7:::\E\nbin:\*:/, 'root\'s password set, the rest kept';
unlike slurp("$d/lxc.log"), qr/\Q$HASH\E/, 'the hash is not logged';
like $calls, qr/lxc-create -n web -f \S+ -t download -- -d debian -r trixie -a arm64/, 'downloads the image';
is slurp("$d/created.conf"),
   "lxc.net.0.type = veth\nlxc.net.0.link = lxcbr0\nlxc.net.0.flags = up\nlxc.net.0.hwaddr = 10:66:6a:xx:xx:xx\nlxc.start.auto = 1\n",
   'private network: on lxcbr0, autostart';
ok !-e "$d/state/web", 'no state left behind';

($rc) = run(qw(create lan1 alpine 3.23 arm64 lan 0), pw());
is slurp("$d/created.conf"),
   "lxc.net.0.type = macvlan\nlxc.net.0.macvlan.mode = bridge\nlxc.net.0.link = enp3s0\nlxc.net.0.flags = up\nlxc.net.0.hwaddr = 10:66:6a:xx:xx:xx\nlxc.start.auto = 0\n",
   'LAN: macvlan on the default route\'s interface';

($rc, $calls) = run(qw(create web debian trixie arm64 nat 0), pw());
is $rc, 1, 'an existing name is refused';
unlike $calls, qr/lxc-create/;

put("$d/fail-create", '');
($rc, $calls) = run(qw(create oops debian trixie arm64 nat 0), pw());
is $rc, 1, 'a failed download fails';
is slurp("$d/state/oops"), "failed\n", '...and says so to the page';
like $calls, qr/lxc-destroy -n oops/, '...and cleans up';
unlink "$d/fail-create";
put("$d/no-shadow", '');
$f = pw();
($rc, $calls) = run(qw(create noshadow debian trixie arm64 nat 0), $f);
is $rc, 1, 'no shadow file to set the password in: fails';
is slurp("$d/state/noshadow"), "failed\n", '...says so';
like $calls, qr/lxc-destroy -n noshadow/, '...and cleans up';
ok !-e $f, '...the password file gone too';
unlink "$d/no-shadow";
run(qw(delete noshadow));

for my $bad (['../x', qw(debian trixie arm64 nat 0)], ['-rf', qw(debian trixie arm64 nat 0)],
             ['ok', 'deb;ian', qw(trixie arm64 nat 0)], ['ok', qw(debian trixie i386 nat 0)],
             ['ok', qw(debian trixie arm64 wifi 0)], ['ok', qw(debian trixie arm64 nat yes)]) {
  ($rc, $calls) = run('create', @$bad, pw());
  is $rc, 1, "create refuses @$bad";
  unlike $calls, qr/lxc-create/;
}

# ---- delete, autostart
($rc, $calls) = run(qw(delete oops));
is $rc, 0, 'delete: a failed one (state file only)';
ok !-e "$d/state/oops", '...is dismissed';
unlike $calls, qr/lxc-destroy/, '...without lxc-destroy';
($rc, $calls) = run(qw(delete lan1));
like $calls, qr/lxc-destroy -n lan1 -f/, 'delete: destroys';

put("$d/lxc/web/config", "lxc.uts.name = web\nlxc.start.auto = 1\n");
($rc) = run(qw(autostart web 0));
is slurp("$d/lxc/web/config"), "lxc.uts.name = web\nlxc.start.auto = 0\n", 'autostart off';
($rc) = run(qw(autostart web 1));
is slurp("$d/lxc/web/config"), "lxc.uts.name = web\nlxc.start.auto = 1\n", 'autostart on, one line';
($rc) = run(qw(autostart nosuch 1));
is $rc, 1, 'autostart: no such container';

# ---- storage
put("$d/lxc-ls", "web\n");
put("$d/running", '');
($rc, $calls) = run('storage', '/mnt/pool/data');
is $rc, 1, 'storage: refused while a container runs';
unlink "$d/running";
($rc, $calls) = run('storage', '/mnt/pool/data');
is $rc, 0, 'storage: to a volume';
like $calls, qr{cp -a \Q$d\E/lxc/\. /mnt/pool/data/lxc/}, 'containers copied over';
like slurp("$d/fstab"), qr{^/mnt/pool/data/lxc \Q$d\E/lxc none bind,x-systemd\.requires-mounts-for=/mnt/pool 0 0 # easynas-lxc-storage$}m,
     'bind line, after the volume';
is slurp("$d/dropin/easynas-storage.conf"), "[Unit]\nRequiresMountsFor=$d/lxc\n", 'lxc.service waits for it';
like $calls, qr/mount \Q$d\E\/lxc/, 'mounted';
is scalar(() = slurp("$d/fstab") =~ /easynas-lxc-storage/g), 1, 'one bind line: the old one replaced';
like slurp("$d/fstab"), qr{^/dev/sda1 /mnt/pool}m, 'other lines kept';
($rc, $calls) = run('storage', 'internal');
is $rc, 1, 'storage: no going back to the system disk';
like slurp("$d/fstab"), qr/easynas-lxc-storage/, '...the bind line stays';
for my $bad ('/etc', '/mnt/../etc', 'relative') {
  ($rc) = run('storage', $bad);
  is $rc, 1, "storage refuses $bad";
}

# ---- attach (the web terminal)
($rc, $calls) = run(qw(attach web));
is $rc, 1, 'attach: refused when not running';
unlike $calls, qr/lxc-attach/;
put("$d/running", '');
($rc, $calls) = run(qw(attach web));
is $rc, 0, 'attach: ok';
like $calls, qr/^lxc-attach -n web$/m, 'a shell in the container (exec, so it gets the terminal)';
($rc, $calls) = run(qw(attach ../x));
is $rc, 1, 'attach: a bad name is refused';
unlike $calls, qr/lxc-attach/;

# ---- AppArmor and start
unlink "$d/aa/profiles", "$d/running";
put("$d/lxc/web/config", "lxc.uts.name = web\nlxc.net.0.type = macvlan\nlxc.net.0.link = enp3s0\n");
put("$d/fail-aa", '');
($rc, $calls) = run(qw(start web));
is $rc, 1, 'start: refused when the profile cannot be loaded';
unlike $calls, qr/lxc-start/, '...before lxc-start';
($rc) = run('apparmor');
is $rc, 1, 'apparmor: reports the failure';
unlink "$d/fail-aa";
($rc, $calls) = run('apparmor');
is $rc, 0, 'apparmor: loads the profiles';
like $calls, qr/apparmor_parser -r/;
($rc, $calls) = run('apparmor');
is $calls, '', 'apparmor: already loaded, nothing to do';
rename "$d/aa", "$d/aa-off";
($rc, $calls) = run('apparmor');
is $rc, 0, 'apparmor: a kernel without it needs nothing';
is $calls, '';
rename "$d/aa-off", "$d/aa";

unlink "$d/bridge";
($rc, $calls) = run(qw(start web));
is $rc, 0, 'start: a LAN container needs no bridge';
like $calls, qr/lxc-start -n web -d -o \Q$d\E\/lxc\.log -l ERROR/, 'errors go to lxc.log';
unlike $calls, qr/lxc-net/, '...and the bridge is left alone';
put("$d/lxc/web/config", "lxc.net.0.type = veth\nlxc.net.0.link = lxcbr0\n");
($rc, $calls) = run(qw(start web));
is $rc, 1, 'start: a private container needs the bridge up';
unlike $calls, qr/lxc-start/;
put("$d/bridge", '');
put("$d/fail-start", '');
($rc) = run(qw(start web));
is $rc, 1, 'start: a failed lxc-start is reported';
like slurp("$d/lxc.log"), qr/starting web failed/, '...and logged';
unlink "$d/fail-start";
($rc) = run(qw(start nosuch));
is $rc, 1, 'start: no such container';
($rc) = run('start', '../x');
is $rc, 1, 'start: bad name';

($rc) = run('bogus');
is $rc, 2, 'unknown command';

done_testing;
