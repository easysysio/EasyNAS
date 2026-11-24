#!/usr/bin/perl
# Every change the admin pages make has to reach the app as a POST: the
# router (lib/EasyNAS.pm) refuses a GET asking for any action other than a
# display one. This goes through every template and fails on a link or a form
# that would still ask for a change by GET -- the kind of thing a new page or
# add-on brings in.
#
# Run: prove -v t/templates-post.t      (plain Perl, no Mojolicious needed)
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/..";

# The router's own rule, read from lib/EasyNAS.pm so the two can't drift.
open(my $fh, '<', "$root/lib/EasyNAS.pm") or die "lib/EasyNAS.pm: $!";
my $src = do { local $/; <$fh> };
close $fh;
my ($list) = $src =~ /my %view_action = map \{ \$_ => 1 \} qw\(([^)]*)\)/
  or BAIL_OUT('no %view_action list in lib/EasyNAS.pm');
my %view = map { $_ => 1 } split ' ', $list;
like $src, qr/\$action =~ \/menu\$\//, 'the router lets "...menu" actions through';
sub is_view { my ($a) = @_; return $a =~ /menu$/ || $view{$a} }

ok is_view('createmenu') && is_view('progress') && !is_view('delete') && !is_view('menus'),
  'display actions told from changes';

my @templates = (glob("$root/templates/easynas/*.ep"), glob("$root/templates/layouts/*.ep"));
ok @templates > 20, 'templates found';

my (@bad_links, @bad_forms, @reloads);
for my $file (@templates) {
  open(my $t, '<', $file) or die "$file: $!";
  my $s = do { local $/; <$t> };
  close $t;
  (my $name = $file) =~ s{^.*/templates/}{};

  # Links: each <a ...> up to the next one, so several on a line stay apart.
  my @starts;
  push @starts, $-[0] while $s =~ /<a\s/g;
  for my $i (0 .. $#starts) {
    my $end = $i < $#starts ? $starts[$i + 1] : length $s;
    my $seg = substr($s, $starts[$i], $end - $starts[$i]);
    next unless $seg =~ /href=["']?([^"' >]*)/;
    my ($href, $before) = ($1, substr($seg, 0, $-[0]));
    next unless $href =~ /[?&]action=([A-Za-z_0-9]+)/;
    next if is_view($1) || $before =~ /\bdata-post\b/;
    push @bad_links, "$name: $href";
  }

  # Forms: a changing action in a hidden field or a submit button. A value
  # worked out in the template ("<%= ... %>") counts as a change.
  while ($s =~ /(<form\b[^>]*>)(.*?)<\/form>/gs) {
    my ($tag, $body) = ($1, $2);
    next if $tag =~ /method=["']?post/i;
    my @acts = ($body =~ /name=["']?action["']?\s+value=["']?([^"' >]+)/g,
                $body =~ /value=["']?([^"' >]+)["']?\s+name=["']?action\b/g);
    push @bad_forms, "$name: $tag" if grep { !is_view($_) } @acts;
  }

  # A reload after a POST sends the POST again. (The file manager's page is
  # always reached by GET and makes its changes with fetch.)
  push @reloads, $name if $s =~ /location\.reload\(\)/ && $name ne 'easynas/files.html.ep';
}
is_deeply \@bad_links, [], 'no link asks for a change without data-post';
is_deeply \@bad_forms, [], 'no form asks for a change by GET';
is_deeply \@reloads,   [], 'no page reloads itself (that would repeat a POST)';

# The layout carries the script that turns a data-post link into a POST.
open(my $l, '<', "$root/templates/layouts/default.html.ep") or die $!;
my $layout = do { local $/; <$l> };
close $l;
like $layout, qr/matches\('a\[data-post\]'\)/, 'layout turns data-post links into POST forms';
like $layout, qr/composedPath\(\)/, '...found on the click\'s path, even after an onclick changed the link';

done_testing;
