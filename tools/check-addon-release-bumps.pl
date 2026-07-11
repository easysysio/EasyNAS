#!/usr/bin/perl -w
#========================================================================
# check-addon-release-bumps.pl <git-range>
#
# CI guard for the per-addon versioning scheme: addon subpackages keep a
# stable NEVRA unless their Release is bumped, so a changed addon that is
# NOT bumped ships new payload under the old version and no appliance ever
# sees the update. This script fails when, within the given git range, a
# file belonging to a subpackage changed but that subpackage's "Release:"
# line in easynas.spec did not.
#
# Relies on the spec layout "%package NAME / Version / Release" (Release
# within diff-context distance of the %package line).
#########################################################################
use strict;

my $range = $ARGV[0] or die "usage: $0 <git-range>\n";

##### subpackage -> repo files, from the spec's %files sections #####
open my $S, '<', 'easynas.spec' or die "easynas.spec: $!";
my %files;
my $cur = "";
while (<$S>) {
  if    (/^%files\s+(\S+)/) { $cur = $1; }
  elsif (/^%files\s*$/)     { $cur = ""; }          # base package: CI auto-bumps it
  elsif (/^%(?:package|description|pre\b|post\b|preun|postun|install|build|prep|changelog)/) { $cur = ""; }
  elsif ($cur && m{^(?:%\w+(?:\([^)]*\))?\s+)?/easynas/(\S+)}) {
    push @{$files{$cur}}, $1;                       # repo-relative path
  }
}
close $S;

##### files changed in the range #####
my %changed = map { chomp; $_ => 1 } `git diff --name-only $range`;

##### subpackages whose Release changed in the range #####
my %bumped;
my $ctx = "";
foreach my $l (split /\n/, `git diff $range -- easynas.spec`) {
  if    ($l =~ /^[ +-]%package\s+(\S+)/)  { $ctx = $1; }
  elsif ($l =~ /^\+Release:/ && $ctx ne "") { $bumped{$ctx} = 1; }
}

##### verdict #####
my @errors;
foreach my $p (sort keys %files) {
  next if $bumped{$p};
  my @hit = grep { $changed{$_} } @{$files{$p}};
  push @errors, "$p (files: @hit)" if @hit;
}

if (@errors) {
  print STDERR "ERROR: subpackage payload changed without a Release bump in easynas.spec:\n";
  print STDERR "  - $_\n" for @errors;
  print STDERR "Bump each listed subpackage's 'Release:' line (e.g. 1 -> 2) so the\n";
  print STDERR "repo publishes a new NEVRA and appliances see the update.\n";
  exit 1;
}
print "Release-bump check OK for $range\n";
exit 0;
