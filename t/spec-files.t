#!/usr/bin/perl
# Every file the app ships (addons, lib, templates, lang, startup, script,
# public) is in some package's %files in easynas.spec. rpmbuild stops at an
# installed file no %files lists -- this catches it before a build does (that
# is how lxc_terminal.html.ep stopped build #106).
#
# Run: prove -v t/spec-files.t      (core Perl only)
use strict;
use warnings;
use Test::More;
use File::Find;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $root = abs_path(dirname(__FILE__) . '/..');

# The %files entries under /easynas, as patterns (rpm globs: * and ?; a
# directory entry covers what is under it unless it is %dir).
open(my $spec, '<', "$root/easynas.spec") or die "easynas.spec: $!";
my (@pat, $in_files);
while (<$spec>) {
  # A section starts: %files, or another (%package, %post, %changelog...).
  if (/^%(files|package|description|prep|build|install|check|clean|changelog|pre|post|preun|postun|pretrans|posttrans|trigger\w*)\b/) {
    $in_files = ($1 eq 'files');
    next;
  }
  next unless $in_files;
  chomp;
  my $dir = s/^%dir\s+//;
  s/^%(?:config|attr|ghost|verify)(?:\([^)]*\))?\s+//;
  next unless m{^(/easynas/\S+)};
  my $re = join '', map { $_ eq '*' ? '[^/]*' : $_ eq '?' ? '[^/]' : quotemeta } split /([*?])/, $1;
  push @pat, $dir ? qr{^$re$} : qr{^$re(?:/.*)?$};
}
close $spec;
ok @pat > 50, 'read the %files entries';

my @missing;
find({ no_chdir => 1, wanted => sub {
  return unless -f $_;
  (my $rel = $_) =~ s{^\Q$root\E/}{};
  return if $rel =~ m{(^|/)\.};                    # dotfiles
  my $path = "/easynas/$rel";
  push @missing, $rel unless grep { $path =~ $_ } @pat;
} }, grep { -d } map { "$root/$_" } qw(addons lib templates lang startup script public));

is_deeply \@missing, [], 'every shipped file is in a package';
done_testing;
