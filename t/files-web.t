#!/usr/bin/perl
# Tests for the file manager's web side (lib/EasyNAS/Controller/files.pm):
# the page, downloads, zip downloads, previews and the headers that keep a
# file from ever running as part of the appliance's pages.
#
# The controller is loaded for real against a stub of the easynas helper
# module, and runs the real files-helper.pl -- as the current user, without
# sudo -- against a throwaway root laid out like the appliance's mount point.
#
# Run: prove -v t/files-web.t      (needs Mojolicious)
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile tempdir);
use Mojolicious::Lite -signatures;
use Cwd qw(realpath);

my $root   = curfile->dirname->dirname;
my $helper = "$root/lib/EasyNAS/files-helper.pl";
my $stub   = tempdir;
my $keep   = tempdir;                   # removed when this goes out of scope
my $vols   = realpath("$keep");

sub put_file { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; binmode $fh; print $fh $s; close $fh }

put_file("$stub/easynas.pm", <<"EOF");
package easynas;
use Exporter 'import';
our \@EXPORT = qw(get_addon_info get_lang_text write_log get_mount_dir);
our \@LOG;
sub get_addon_info { return { name => \$_[0], program => \$_[0], description => \$_[0] } }
sub get_lang_text  {
  our %TEXT;
  if (!%TEXT) { do \$_ or die \$@ for glob('$root/lang/en-en/*.pl') }
  return %TEXT;
}
sub write_log      { push \@LOG, [\@_] }
sub get_mount_dir  { '$vols' }
1;
EOF
mkdir "$stub/layouts";
put_file("$stub/layouts/$_", '<%= content %>') for qw(default.html.ep);

unshift @INC, "$stub";
require "$root/lib/EasyNAS/Controller/files.pm";
{
  no warnings qw(redefine once);
  # The real helper, as this user: no sudo, no setpriv.
  *EasyNAS::Controller::Files::helper_cmd = sub { ($^X, $helper, $vols) };
}

app->renderer->paths(["$stub", "$root/templates"]);
any '/files'  => sub ($c) { EasyNAS::Controller::Files::view($c) };
get '/signin' => sub ($c) { $c->session(is_auth => 1, role => 'admin', user => 'admin'); $c->render(text => 'ok') };

# The volumes: <pool>/<volume>/...
mkdir "$vols/pool"; mkdir "$vols/pool/vol"; mkdir "$vols/pool/vol/dir"; mkdir "$vols/pool/vol/dir/sub";
my $png = "\x89PNG\r\n\x1a\n" . ("\0" x 40);
put_file("$vols/pool/vol/pic.png", $png);
put_file("$vols/pool/vol/draw.svg", '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>');
put_file("$vols/pool/vol/big.log", 'x' x 300_000);
put_file("$vols/pool/vol/dir/a.txt", "alpha\n");
put_file("$vols/pool/vol/dir/sub/b.txt", "bravo\n");

my $t = Test::Mojo->new;
$t->get_ok('/signin');

# ---- the page
$t->get_ok('/files')->status_is(200)
  ->element_exists('#fm-download')->element_exists('#fm-upload-dir')
  ->element_exists('#fm-dir[webkitdirectory]');
my ($csrf) = $t->tx->res->body =~ /var CSRF\s*=\s*"([0-9a-f]{32})"/;
ok $csrf, 'page carries the anti-forgery token';
like $t->tx->res->body, qr/\["avif","bmp","gif","ico","jpeg","jpg","png","svg","webp"\]\.forEach/,
  'image types handed to the page';

sub security_headers ($what) {
  my $h = $t->tx->res->headers;
  like $h->header('Content-Security-Policy') // '', qr/\bsandbox\b/, "$what: sandboxed";
  like $h->header('Content-Security-Policy') // '', qr/default-src 'none'/, "$what: no scripts";
  is $h->header('X-Content-Type-Options'), 'nosniff', "$what: nosniff";
}

# ---- download
$t->get_ok('/files?action=download&path=pool/vol/dir/a.txt')->status_is(200)
  ->content_type_is('application/octet-stream')->header_is('Content-Length' => 6)
  ->header_like('Content-Disposition' => qr/^attachment; filename\*=UTF-8''a\.txt$/)
  ->content_is("alpha\n");
security_headers('download');
$t->get_ok('/files?action=download&path=pool/vol/nope')->status_is(404);

# ---- preview: pictures whole and inline, anything else as its first bytes
$t->get_ok('/files?action=preview&path=pool/vol/pic.png')->status_is(200)
  ->content_type_is('image/png')->header_like('Content-Disposition' => qr/^inline;/)
  ->content_is($png);
security_headers('image preview');

$t->get_ok('/files?action=preview&path=pool/vol/draw.svg')->status_is(200)
  ->content_type_is('image/svg+xml');
security_headers('SVG preview');        # opened on its own, its script can't run

$t->get_ok('/files?action=preview&path=pool/vol/big.log')->status_is(200)
  ->content_type_is('application/octet-stream')
  ->header_is('X-File-Size' => 300_000)->header_is('Content-Length' => 256 * 1024)
  ->header_like('Content-Disposition' => qr/^attachment;/);
is length($t->tx->res->body), 256 * 1024, 'text preview: only the start of a big file';
$t->get_ok('/files?action=preview&path=pool/vol/dir/a.txt')->header_is('Content-Length' => 6)
  ->content_is("alpha\n");

# ---- zip
$t->post_ok('/files' => form => { action => 'zipcheck', item => ['pool/vol/dir'] })
  ->status_is(403)->json_is('/error' => 'csrf');
$t->post_ok('/files' => { 'X-CSRF-Token' => $csrf } => form => { action => 'zipcheck', item => ['pool/vol/dir'] })
  ->status_is(200)->json_is('/ok' => 1);
$t->post_ok('/files' => { 'X-CSRF-Token' => $csrf } => form => { action => 'zipcheck', item => ['pool/vol/nope'] })
  ->json_is('/error' => 'notfound');

# The download itself is a plain form POST: the token travels as a field.
$t->post_ok('/files' => form => { action => 'zip', csrf => $csrf, path => 'pool/vol', item => ['pool/vol/dir'] })
  ->status_is(200)->content_type_is('application/zip')
  ->header_like('Content-Disposition' => qr/filename\*=UTF-8''dir\.zip$/);
security_headers('zip');
my $zip = $t->tx->res->body;
is substr($zip, 0, 4), "PK\x03\x04", 'a zip';
like $zip, qr{dir/sub/b\.txt}, 'with the folder tree inside';
like $zip, qr{alpha\n}, '...and the contents (stored)';
is substr($zip, -22, 4), "PK\x05\x06", 'ends with the end-of-directory record';

$t->post_ok('/files' => form => { action => 'zip', csrf => $csrf, path => 'pool/vol',
                                  item => ['pool/vol/dir', 'pool/vol/pic.png'] })
  ->header_like('Content-Disposition' => qr/filename\*=UTF-8''vol\.zip$/, 'several items: named after their folder');
$t->post_ok('/files' => form => { action => 'zip', path => 'pool/vol', item => ['pool/vol/dir'] })
  ->status_is(403, 'zip without the token refused');
$t->post_ok('/files' => form => { action => 'zip', csrf => $csrf, path => 'pool/vol', item => ['pool/vol/nope'] })
  ->status_is(404, 'a bad zip request gets an answer, not a broken zip');
{ no warnings 'once';
  ok((grep { $_->[2] =~ m{downloaded pool/vol/dir as a zip} } @easynas::LOG), 'zip download logged'); }

# ---- folder upload: the folders, then the files into them
$t->post_ok('/files' => { 'X-CSRF-Token' => $csrf } => form => { action => 'mkdirs', path => 'pool/vol', name => 'Photos/2024' })
  ->json_is('/ok' => 1);
ok -d "$vols/pool/vol/Photos/2024", 'folder tree created';
$t->post_ok('/files?action=upload&path=pool/vol/Photos/2024&name=c.txt&offset=0&total=5&overwrite=0'
            => { 'X-CSRF-Token' => $csrf, 'Content-Type' => 'application/octet-stream' } => 'hello')
  ->json_is('/ok' => 1)->json_is('/done' => 1);
open my $fh, '<', "$vols/pool/vol/Photos/2024/c.txt"; my $got = <$fh>;
is $got, 'hello', 'file uploaded into it';

done_testing;
