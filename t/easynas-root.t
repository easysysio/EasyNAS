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
done_testing;
