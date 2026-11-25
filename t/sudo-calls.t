#!/usr/bin/perl
# The way to a sudoers rule without ALL. The web interface (and the console
# menu, which runs as the same "easynas" user) should reach root only through
# the helpers in /easynas/startup that check what they are asked to do; a
# sudo of anything else (tee, sed, systemctl, zypper...) is as good as root
# for whoever finds a bug in a page.
#
# t/sudo-baseline.txt counts the sudo calls each file still makes outside the
# helpers. This fails when a file makes more (new code goes through a helper
# -- see startup/easynas-root) and when it makes fewer (lower the count: the
# number only goes down). At zero everywhere, sudoers can name the helpers
# instead of ALL.
#
# Run: prove -v t/sudo-calls.t      (core Perl only)
use strict;
use warnings;
use Test::More;
use File::Find;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $root = abs_path(dirname(__FILE__) . '/..');

# The helpers: each checks its arguments itself.
my $HELPER = qr{/easynas/startup/(?:easynas-root|lxc-helper\.sh|addon-worker\.sh|mariadb-storage\.sh)\b|\$ROOT_HELPER\b};

my %count;
find({ no_chdir => 1, wanted => sub {
  return unless -f $_ && /\.(pm|pl|ep|sh)$/;
  (my $rel = $_) =~ s{^\Q$root\E/}{};
  return if $rel =~ m{^startup/} && $rel ne 'startup/easynas.sh';   # the rest run as root already
  open(my $fh, '<', $_) or return;
  while (my $line = <$fh>) {
    next if $line =~ /^\s*#/;                       # comments
    next unless $line =~ /\bsudo\b/;
    next if $line =~ $HELPER;
    $count{$rel}++;
  }
  close $fh;
} }, map { "$root/$_" } qw(lib templates script startup));

my %base;
open(my $b, '<', "$root/t/sudo-baseline.txt") or die "t/sudo-baseline.txt: $!";
while (<$b>) { next if /^\s*(#|$)/; my ($n, $f) = split ' ', $_, 2; chomp $f; $base{$f} = $n; }
close $b;

my $total = 0;
for my $f (sort keys %{{ %count, %base }}) {
  my ($now, $was) = ($count{$f} // 0, $base{$f} // 0);
  $total += $now;
  ok $now <= $was, "$f: no new sudo outside the helpers ($now, at most $was)"
    or diag "route it through a helper (startup/easynas-root) instead";
  ok $now >= $was, "$f: baseline up to date" or diag "lower its count in t/sudo-baseline.txt to $now";
}
note "sudo calls left outside the helpers: $total";
done_testing;
