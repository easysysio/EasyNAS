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
mkdir "$d/$_" for qw(bin lxc state mnt mnt/pool mnt/pool/data);
sub put { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub slurp { my ($f) = @_; open my $fh, '<', $f or return undef; local $/; my $s = <$fh>; close $fh; $s }

# Every fake logs "<tool> <args>" to calls; lxc-create copies the -f config it
# was given and makes the container, unless told to fail.
for my $tool (qw(systemctl lxc-destroy lxc-ls umount mount mountpoint systemd-run ss sleep)) {
  put("$d/bin/$tool", "#!/bin/sh\necho \"$tool \$*\" >> $d/calls\n" .
      ($tool eq 'mountpoint' ? "exit 1\n" : $tool eq 'lxc-ls' ? "cat $d/lxc-ls 2>/dev/null\n" : $tool eq 'ss' ? "echo LISTEN\n" : "exit 0\n"));
}
put("$d/bin/ip", "#!/bin/sh\necho \"ip \$*\" >> $d/calls\n" .
    "case \"\$*\" in *'route show default'*) echo 'default via 192.168.1.1 dev enp3s0 proto dhcp';; esac\n" .
    "[ -e $d/bridge ] || case \"\$*\" in 'link show lxcbr0') exit 1;; esac\nexit 0\n");
put("$d/bin/lxc-create", <<"SH");
#!/bin/sh
echo "lxc-create \$*" >> $d/calls
[ -e $d/fail-create ] && exit 1
while [ \$# -gt 0 ]; do case "\$1" in -n) n=\$2; shift 2;; -f) /bin/cp "\$2" $d/created.conf; shift 2;; --) break;; *) shift;; esac; done
mkdir -p $d/lxc/\$n && echo "lxc.uts.name = \$n" > $d/lxc/\$n/config
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
($rc) = run('net');
is slurp("$d/lxc-net"), qq{USE_LXC_BRIDGE="true"\n}, 'written once';

# ---- create
($rc, $calls) = run(qw(create web debian trixie arm64 nat 1));
is $rc, 0, 'create: ok';
like $calls, qr/lxc-create -n web -f \S+ -t download -- -d debian -r trixie -a arm64/, 'downloads the image';
is slurp("$d/created.conf"),
   "lxc.net.0.type = veth\nlxc.net.0.link = lxcbr0\nlxc.net.0.flags = up\nlxc.net.0.hwaddr = 10:66:6a:xx:xx:xx\nlxc.start.auto = 1\n",
   'private network: on lxcbr0, autostart';
ok !-e "$d/state/web", 'no state left behind';

($rc) = run(qw(create lan1 alpine 3.23 arm64 lan 0));
is slurp("$d/created.conf"),
   "lxc.net.0.type = macvlan\nlxc.net.0.macvlan.mode = bridge\nlxc.net.0.link = enp3s0\nlxc.net.0.flags = up\nlxc.net.0.hwaddr = 10:66:6a:xx:xx:xx\nlxc.start.auto = 0\n",
   'LAN: macvlan on the default route\'s interface';

($rc, $calls) = run(qw(create web debian trixie arm64 nat 0));
is $rc, 1, 'an existing name is refused';
unlike $calls, qr/lxc-create/;

put("$d/fail-create", '');
($rc, $calls) = run(qw(create oops debian trixie arm64 nat 0));
is $rc, 1, 'a failed download fails';
is slurp("$d/state/oops"), "failed\n", '...and says so to the page';
like $calls, qr/lxc-destroy -n oops/, '...and cleans up';
unlink "$d/fail-create";

for my $bad (['../x', qw(debian trixie arm64 nat 0)], ['-rf', qw(debian trixie arm64 nat 0)],
             ['ok', 'deb;ian', qw(trixie arm64 nat 0)], ['ok', qw(debian trixie i386 nat 0)],
             ['ok', qw(debian trixie arm64 wifi 0)], ['ok', qw(debian trixie arm64 nat yes)]) {
  ($rc, $calls) = run('create', @$bad);
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
($rc) = run('storage', 'internal');
unlike slurp("$d/fstab"), qr/easynas-lxc-storage/, 'internal: bind line gone';
ok !-e "$d/dropin/easynas-storage.conf", '...and the drop-in';
like slurp("$d/fstab"), qr{^/dev/sda1 /mnt/pool}m, 'other lines kept';
for my $bad ('/etc', '/mnt/../etc', 'relative') {
  ($rc) = run('storage', $bad);
  is $rc, 1, "storage refuses $bad";
}

# ---- terminal
($rc) = run(qw(terminal web 0123456789abcdef0123456789abcdef));
is $rc, 1, 'terminal: refused when not running';
put("$d/running", '');
($rc, $calls) = run(qw(terminal web 0123456789abcdef0123456789abcdef));
is $rc, 0, 'terminal: starts';
like $calls, qr/systemctl stop easynas-lxc-terminal/, 'an old one is stopped first';
like $calls, qr{systemd-run --collect --quiet --unit=easynas-lxc-terminal -p RuntimeMaxSec=8h /usr/bin/ttyd -p 8080 -o -W -c easynas:0123456789abcdef0123456789abcdef /usr/bin/lxc-attach -n web},
     'ttyd attached to the container, with the credential';
($rc) = run(qw(terminal web nothex));
is $rc, 1, 'terminal: bad token';

($rc) = run('bogus');
is $rc, 2, 'unknown command';

done_testing;
