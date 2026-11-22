#!/usr/bin/perl
# Tests for startup/web-port.sh: the web interface's port goes from
# /etc/easynas/easynas.conf into easynas.socket's drop-in, and the web
# interface restarts the right way for it. Run against throwaway paths and a
# stand-in systemctl that records its calls.
#
# Run: prove -v t/web-port.t      (needs bash)
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);

my $script = "$FindBin::Bin/../startup/web-port.sh";
my $dir    = tempdir(CLEANUP => 1);
my $conf   = "$dir/easynas.conf";
my $dropin = "$dir/easynas.socket.d";
my $log    = "$dir/systemctl.log";

# systemctl stand-in: logs each call; "show" prints LISTEN, "is-active"
# answers from ACTIVE.
open(my $fh, '>', "$dir/systemctl") or die $!;
print $fh <<'SH';
#!/bin/bash
echo "$*" >> "$LOG"
case "$*" in
  "show -p Listen --value easynas.socket") echo "${LISTEN:-}" ;;
  "-q is-active easynas.socket")           [ "${ACTIVE:-0}" = 1 ]; exit $? ;;
esac
exit 0
SH
close $fh;
chmod 0755, "$dir/systemctl";
mkdir "$dir/systemd";

sub put { my ($f, $s) = @_; open(my $o, '>', $f) or die $!; print $o $s; close $o }
sub slurp { my ($f) = @_; open(my $i, '<', $f) or return undef; local $/; my $s = <$i>; close $i; $s }
sub run {
  my (%o) = @_;
  unlink $log;
  local $ENV{EASYNAS_CONF}          = $conf;
  local $ENV{EASYNAS_SOCKET_DROPIN} = $dropin;
  local $ENV{EASYNAS_SYSTEMD_DIR}   = $o{systemd} // "$dir/systemd";
  local $ENV{EASYNAS_SYSTEMCTL}     = "$dir/systemctl";
  local $ENV{LOG}    = $log;
  local $ENV{LISTEN} = $o{listen} // '';
  local $ENV{ACTIVE} = $o{active} // 0;
  my $rc = system('bash', $script, @{$o{args} // []});
  my @calls = grep { length } split /\n/, (slurp($log) // '');
  return ($rc >> 8, \@calls);
}
sub port_in_dropin { my $s = slurp("$dropin/port.conf") // ''; my @l = $s =~ /^ListenStream=(\d*)$/mg; \@l }

# ---- the drop-in
put($conf, "EASYNAS_PORT=1443\n");
my ($rc, $calls) = run();
is $rc, 0, 'runs';
is_deeply port_in_dropin(), ['', 1443], 'drop-in resets the default and listens on the port';
like slurp("$dropin/port.conf"), qr/^\[Socket\]$/m, '...in a [Socket] section';
is_deeply $calls, ['daemon-reload'], 'a new drop-in reloads systemd';

($rc, $calls) = run();
is_deeply $calls, [], 'unchanged: no reload';

put($conf, "# a comment\nEASYNAS_PORT=8443\nOTHER=1\n");
(undef, $calls) = run();
is_deeply port_in_dropin(), ['', 8443], 'the port from the conf';
is_deeply $calls, ['daemon-reload'], 'changed: reload';

for my $bad ("EASYNAS_PORT=80\n", "EASYNAS_PORT=99999\n", "EASYNAS_PORT=8443; reboot\n", "", "nothing here\n") {
  put($conf, $bad);
  run();
  is_deeply port_in_dropin(), ['', 1443], "falls back to 1443 for: " . ($bad =~ s/\n//r || '(empty)');
}
unlink $conf;
run();
is_deeply port_in_dropin(), ['', 1443], 'no conf: 1443';

put($conf, "EASYNAS_PORT=8443");                  # no newline at the end
run();
is_deeply port_in_dropin(), ['', 8443], 'last line without a newline is read';

# ---- without systemd (an image build): the drop-in only
put($conf, "EASYNAS_PORT=9443\n");
(undef, $calls) = run(systemd => "$dir/none", args => ['--apply']);
is_deeply port_in_dropin(), ['', 9443], 'no systemd: drop-in still written';
is_deeply $calls, [], '...and systemctl left alone';

# ---- --apply
put($conf, "EASYNAS_PORT=9443\n");
(undef, $calls) = run(args => ['--apply'], listen => '[::]:9443 (Stream)', active => 1);
is_deeply [grep { !/^(show|-q)/ } @$calls], ['restart easynas.service'],
  'same port: only the app restarts (the socket stays open)';

put($conf, "EASYNAS_PORT=7443\n");
(undef, $calls) = run(args => ['--apply'], listen => '[::]:9443 (Stream)', active => 1);
is_deeply [grep { !/^(show|-q)/ } @$calls],
  ['daemon-reload', 'stop easynas.service', 'restart easynas.socket', 'start easynas.service'],
  'new port: the app stops, the socket reopens, the app starts';

(undef, $calls) = run(args => ['--apply'], listen => '', active => 0);
is_deeply [grep { !/^(show|-q)/ } @$calls],
  ['stop easynas.service', 'restart easynas.socket', 'start easynas.service'],
  'socket not open: opened, with the app restarted around it';

# ---- --boot
(undef, $calls) = run(args => ['--boot'], listen => '[::]:1443 (Stream)', active => 1);
is_deeply [grep { !/^(show|-q)/ } @$calls], ['restart easynas.socket'],
  'boot, socket open on another port: reopened';
(undef, $calls) = run(args => ['--boot'], listen => '[::]:7443 (Stream)', active => 1);
is_deeply [grep { !/^(show|-q)/ } @$calls], [], 'boot, right port: nothing';
(undef, $calls) = run(args => ['--boot'], listen => '', active => 0);
is_deeply [grep { !/^(show|-q)/ } @$calls], [], 'boot, socket not open (moving over in %post): left alone';

done_testing;
