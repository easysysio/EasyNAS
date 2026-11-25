#!/usr/bin/perl
# startup/conf-perms.sh: who owns what under /etc/easynas and /var/log/easynas.
# It chowns to root, so this runs only on Linux with passwordless sudo (the CI
# runner); elsewhere it skips. "nobody"/"nogroup" stand in for easynas.
#
# Run: prove -v t/conf-perms.t      (core Perl only)
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use File::Basename qw(dirname);

plan skip_all => 'needs Linux' unless $^O eq 'linux';
plan skip_all => 'needs passwordless sudo' unless system('sudo -n true >/dev/null 2>&1') == 0;
my ($user, $group) = ('nobody', (getgrnam('nogroup') ? 'nogroup' : 'nobody'));
plan skip_all => "needs a $user user" unless defined getpwnam($user);

my $script = abs_path(dirname(__FILE__) . '/../startup/conf-perms.sh');
my $d = tempdir(CLEANUP => 0);
chmod 0755, $d;
my ($conf, $log) = ("$d/etc", "$d/log");
END { system('sudo', '-n', 'rm', '-rf', '--', $d) if $d }

sub sh   { system('sudo', '-n', 'sh', '-c', $_[0]) == 0 or die "setup: $_[0]" }
sub as_app { system('sudo', '-n', '-u', $user, 'sh', '-c', $_[0]) }
sub run_perms {
  return system('sudo', '-n', 'env', "EASYNAS_CONF_DIR=$conf", "EASYNAS_LOG_DIR=$log",
                "EASYNAS_APP_USER=$user", "EASYNAS_APP_GROUP=$group", 'bash', $script) >> 8;
}
sub st    { my @s = lstat($_[0]); return @s ? { uid => $s[4], gid => $s[5], mode => $s[2] & 07777 } : undef }
sub owner { my $s = st($_[0]) or return 'none'; return scalar(getpwuid($s->{uid})) . ':' . scalar(getgrgid($s->{gid})) }
sub mode  { my $s = st($_[0]) or return 'none'; return sprintf('%o', $s->{mode}) }
sub slurp { open(my $f, '<', $_[0]) or return undef; local $/; return <$f> }

# An older release's layout: everything easynas's.
sh(<<"SH");
set -e
mkdir -p $conf/rsyncd $conf/raddb/mods-available $conf/raddb/mods-enabled $conf/addons $log $d/outside
echo 'pid file = /run/x.pid' > $conf/rsyncd/rsyncd.conf
echo 'u:pw' > $conf/rsyncd/rsyncd.secrets; chmod 600 $conf/rsyncd/rsyncd.secrets
echo 'client x {' > $conf/raddb/clients.conf; chmod 664 $conf/raddb/clients.conf
echo m > $conf/raddb/mods-available/eap; ln -s ../mods-available/eap $conf/raddb/mods-enabled/eap
echo 'media_dir=/mnt/a' > $conf/minidlna
echo 'admin:x' > $conf/admin.conf; chmod 600 $conf/admin.conf
echo 'EASYNAS_PORT=1443' > $conf/easynas.conf
echo '<stream/>' > $conf/easynas.updates; echo updating > $conf/update.status
echo secret > $d/outside/target; ln -s $d/outside/target $conf/tftp
echo 'old update' > $log/update.log; echo 'app' > $log/easynas.log
chown -R $user:$group $conf $log $d/outside/target
SH

is run_perms(), 0, 'first run';
is owner($conf), "root:$group", '/etc/easynas: root:easynas';
is mode($conf), '1775', '...sticky, group-writable';
is owner($log), "root:$group", '/var/log/easynas: root:easynas';
is mode($log), '1775', '...sticky, group-writable';
for my $p (qw(rsyncd rsyncd/rsyncd.conf rsyncd/rsyncd.secrets raddb raddb/clients.conf addons tgt minidlna)) {
  is owner("$conf/$p"), 'root:root', "$p: root's";
}
is mode("$conf/raddb/clients.conf"), '644', 'raddb/clients.conf: writable by root only';
is mode("$conf/rsyncd/rsyncd.secrets"), '600', 'rsyncd.secrets keeps its mode';
is slurp("$conf/rsyncd/rsyncd.conf"), "pid file = /run/x.pid\n", 'rsyncd.conf keeps what is in it';
ok -l "$conf/raddb/mods-enabled/eap", 'a link inside raddb stays a link';
is slurp("$conf/raddb/mods-available/eap"), "m\n", '...its target untouched';
ok !-e "$conf/tftp" && !-l "$conf/tftp", 'a link where a root file belongs is removed';
is slurp("$d/outside/target"), "secret\n", '...its target untouched';
is owner("$d/outside/target"), "$user:$group", '...and not chowned';
is owner("$conf/admin.conf"), "$user:$group", "admin.conf stays easynas's";
is mode("$conf/admin.conf"), '600', '...and 0600';
is owner("$conf/easynas.conf"), "$user:$group", "easynas.conf stays easynas's";
ok !-e "$conf/easynas.updates" && !-e "$conf/update.status", "root's old state files are gone";
is owner("$log/update.log"), 'root:root', "update.log: root's";
is slurp("$log/update.log"), "old update\n", '...keeps what is in it';
is owner("$log/lxc.log"), 'root:root', "lxc.log made, root's";
is owner("$log/easynas.log"), "$user:$group", "easynas.log stays easynas's";
is owner("$conf/.root-owned"), 'root:root', 'first run marked done';

# easynas, from now on
isnt as_app("mv $conf/rsyncd $conf/x 2>/dev/null"), 0, "easynas can't move root's directory";
isnt as_app("rm -f $log/update.log 2>/dev/null"), 0, "...or remove root's log";
isnt as_app("echo x >> $conf/rsyncd/rsyncd.conf 2>/dev/null"), 0, "...or write root's config";
is as_app("echo n > $conf/wizard.done"), 0, '...but makes its own files';
is as_app("echo 'admin:y' > $conf/admin.conf.new && mv -f $conf/admin.conf.new $conf/admin.conf"), 0,
   '...and replaces them';
as_app("echo 'friendly_name=evil' > $conf/pure-ftpd.conf; ln -s $d/outside/target $conf/tftp");

is run_perms(), 0, 'second run';
ok !-e "$conf/pure-ftpd.conf", "a file easynas made where root's belongs is not adopted";
my @aside = glob("$conf/pure-ftpd.conf.not-root.*");
is scalar(@aside), 1, '...it is moved aside';
ok !-l "$conf/tftp", '...a link is removed again';
is owner("$conf/wizard.done"), "$user:$group", "easynas's own file left alone";
is slurp("$conf/admin.conf"), "admin:y\n", "...and what is in it";

# A .root-owned easynas made doesn't end the first run.
sh("rm -f $conf/.root-owned; chown $user:$group $conf/minidlna");
as_app("echo > $conf/.root-owned");
is run_perms(), 0, 'a run with a .root-owned of easynas';
is owner("$conf/minidlna"), 'root:root', '...still adopts: the mark was not root\'s';

done_testing;
