#!/usr/bin/perl
# Every Perl module the appliance's code loads is either part of core Perl or
# named by a Requires: in easynas.spec. A missing one doesn't show on an
# appliance that already has it from earlier, only on a fresh install, where
# the web interface then dies at startup (that is how perl-Number-Bytes-Human
# went missing).
#
# Run: prove -v t/perl-requires.t      (core Perl only)
use strict;
use warnings;
use Test::More;
use Module::CoreList;
use File::Find;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $root = abs_path(dirname(__FILE__) . '/..');

# The modules the code loads, and where.
my %where;
find({ no_chdir => 1, wanted => sub {
  return unless -f $_ && /\.(pm|pl|ep)$|\/script\/[^\/]+$/;
  open(my $fh, '<', $_) or return;
  (my $rel = $_) =~ s{^\Q$root\E/}{};
  while (my $line = <$fh>) {
    last if $line =~ /^__(END|DATA)__/;
    $line =~ s/^\s*%\s*/ /;                         # template code lines
    next unless $line =~ /^\s*(?:use|require)\s+([A-Z][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*)[\s;(]/;
    push @{$where{$1}}, $rel;
  }
  close $fh;
} }, map { "$root/$_" } qw(lib startup script templates));

# What the spec requires, as packages and as perl(Module) capabilities.
open(my $spec, '<', "$root/easynas.spec") or die "easynas.spec: $!";
my %requires;
while (<$spec>) { $requires{$_} = 1 for /^Requires:\s*(.*)$/ ? split(/[\s,]+/, $1) : () }
close $spec;

# openSUSE's name for a module's package: Foo::Bar -> perl-Foo-Bar. Mojo::* and
# Mojolicious::* come with perl-Mojolicious.
sub package_of {
  my ($m) = @_;
  return 'perl-Mojolicious' if $m =~ /^Mojo(licious)?(::|$)/;
  (my $p = $m) =~ s/::/-/g;
  return "perl-$p";
}

ok(keys %where > 10, 'found the modules the code loads') or diag explain \%where;
for my $m (sort keys %where) {
  next if $m eq 'EasyNAS' || $m =~ /^EasyNAS::/;          # the app's own
  next if defined Module::CoreList->first_release($m);    # core Perl
  my $pkg = package_of($m);
  ok($requires{$pkg} || $requires{"perl($m)"}, "$m is required ($pkg)")
    or diag "used in: " . join(', ', sort { $a cmp $b } keys %{{ map { $_ => 1 } @{$where{$m}} }});
}

done_testing;
