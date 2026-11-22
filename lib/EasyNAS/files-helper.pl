#!/usr/bin/perl
#========================================================================
# files-helper.pl <root> <op> [args...]
#
# The file manager addon's only way of touching the filesystem. The web app
# runs it as the Linux account of whoever is signed in (root for the
# administrator; see helper_cmd in files.pm), so every operation is
# permission-checked by the kernel exactly as it would be over SMB or SSH --
# nothing here decides who may do what, and nothing here has more rights than
# the account it runs as.
#
# What this script does enforce is WHERE: every path is given relative to
# <root> (the volumes mount point) and must stay inside it once symlinks are
# resolved, and nothing may be created, changed or removed above the inside of
# a volume (<root>/<pool>/<volume>/...) -- pools and volumes belong to the
# Storage pages.
#
# Ops (paths relative to <root>; "" is <root> itself):
#   list   <dir>                      directory listing
#   stat   <path>                     one entry (used before a download)
#   read   <path> [<max bytes>]       file contents on stdout (or their start)
#   zipcheck <path>...                can these be downloaded as a zip?
#   zip    <path>...                  a zip of files and folders on stdout
#   mkdir  <dir> <name>
#   mkdirs <dir> <relpath>            create nested folders (folder upload)
#   rename <path> <newname>
#   delete <path>...
#   move   <destdir> <path>...
#   copy   <destdir> <path>...
#   put    <dir> <name> <offset> <total> <overwrite>   upload chunk on stdin
#
# Every op but `read` and `zip` prints one line of JSON: {"ok":1,...} or
# {"ok":0,"error":"<code>","detail":"..."} and exits 0 / 1.
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
use strict;
use warnings;
use Cwd qw(realpath);
use Encode ();
use Errno qw(EACCES EPERM ENOENT EEXIST ENOTEMPTY ENOSPC EDQUOT ENOTDIR EISDIR EROFS);
use Fcntl qw(:mode O_WRONLY O_CREAT O_TRUNC O_RDONLY);
use JSON::PP ();
use Compress::Raw::Zlib ();
use File::Temp ();

# Entries may be changed only from this depth down: <pool>/<volume>/<entry>.
my $MIN_DEPTH = 2;
# An upload in progress; hidden from listings, renamed into place when complete.
my $PART = '.easynas-part';

my $json = JSON::PP->new->utf8->canonical;

sub out  { print $json->encode($_[0]), "\n"; }
sub fail {
  my ($code, $detail) = @_;
  out({ ok => 0, error => $code, (defined $detail ? (detail => "$detail") : ()) });
  exit 1;
}

# Turn errno into the short codes the UI has messages for.
sub errcode {
  my $e = shift // ($! + 0);
  return 'denied'   if $e == EACCES || $e == EPERM || $e == EROFS;
  return 'notfound' if $e == ENOENT || $e == ENOTDIR;
  return 'exists'   if $e == EEXIST || $e == ENOTEMPTY;
  return 'nospace'  if $e == ENOSPC || $e == EDQUOT;
  return 'failed';
}

my $ROOT = shift(@ARGV) // '';
my $op   = shift(@ARGV) // '';
fail('badroot') unless $ROOT =~ m{^/} && -d $ROOT;
my $ROOT_REAL = realpath($ROOT) or fail('badroot');
$ROOT_REAL =~ s{/+$}{} unless $ROOT_REAL eq '/';

sub inside {
  my $p = shift;
  return 0 unless defined $p;
  return 1 if $p eq $ROOT_REAL;
  return index($p, ($ROOT_REAL eq '/' ? '/' : "$ROOT_REAL/")) == 0;
}

# A relative path as its components. ".." is refused outright rather than
# resolved: nothing the UI sends ever contains it.
sub comps {
  my $rel = shift // '';
  fail('badpath') if $rel =~ /\0/;
  my @c = grep { $_ ne '' && $_ ne '.' } split(m{/+}, $rel);
  fail('badpath') if grep { $_ eq '..' } @c;
  return @c;
}

# A name for something new, or a rename target: one path component.
sub good_name {
  my $n = shift;
  return defined $n && $n ne '' && $n ne '.' && $n ne '..'
      && $n !~ m{[/\0]} && length($n) <= 255 && $n !~ /\Q$PART\E$/;
}

# An existing directory, symlinks resolved, guaranteed inside the root.
sub real_dir {
  my @c = @_;
  my $real = realpath(join('/', $ROOT_REAL, @c));
  fail('notfound') unless defined $real && -e $real;
  fail('outside')  unless inside($real);
  fail('notdir')   unless -d $real;
  return $real;
}

# An entry addressed for a change (rename/delete/move/copy source): its parent
# directory is resolved and checked, the last component is taken as-is, so a
# symlink is acted on as a link and never followed.
sub entry {
  my ($rel, $need_depth) = @_;
  my @c = comps($rel);
  fail('badpath') unless @c;
  fail('protected') if $need_depth && @c <= $MIN_DEPTH;
  my $name = pop @c;
  my $dir  = real_dir(@c);
  return ($dir, $name, "$dir/$name");
}

# A directory that will receive something new: must be inside a volume.
sub target_dir {
  my @c = comps(shift);
  fail('protected') if @c < $MIN_DEPTH;
  return real_dir(@c);
}

# New files in a setgid directory (a group share) stay group-writable, so the
# other members of the share can work with them -- what Samba's force group and
# create mask do for the same directory. Elsewhere, the usual 022.
sub set_umask {
  my $dir = shift;
  my @st = stat($dir);
  umask((@st && ($st[2] & S_ISGID)) ? 0002 : 0022);
}

# Run a command (list form, no shell); returns (exit status, first stderr line).
sub run {
  my @cmd = @_;
  pipe(my $r, my $w) or return (-1, "$!");
  my $pid = fork();
  return (-1, "$!") unless defined $pid;
  if (!$pid) {
    close $r;
    open(STDERR, '>&', $w);
    open(STDOUT, '>', '/dev/null');
    exec { $cmd[0] } @cmd;
    exit 127;
  }
  close $w;
  my $err = do { local $/; <$r> } // '';
  close $r;
  waitpid($pid, 0);
  ($err) = split(/\n/, $err);
  return ($? >> 8, $err // '');
}

# A file name as text for the UI. Names are bytes on disk; one that is not
# valid UTF-8 can be shown (approximately) but not sent back intact, so it is
# flagged and the UI offers no actions on it.
sub name_text {
  my $bytes = shift;
  my $copy = $bytes;
  my $text = eval { Encode::decode('UTF-8', $copy, Encode::FB_CROAK) };
  return ($text, 0) if defined $text;
  return (Encode::decode('ISO-8859-1', $bytes), 1);
}

my (%uname, %gname);
sub uname { my $u = shift; $uname{$u} //= (getpwuid($u))[0] // $u; }
sub gname { my $g = shift; $gname{$g} //= (getgrgid($g))[0] // $g; }

sub mode_text {
  my $m = shift;
  my $s = '';
  foreach my $shift (6, 3, 0) {
    my $b = ($m >> $shift) & 7;
    $s .= ($b & 4 ? 'r' : '-') . ($b & 2 ? 'w' : '-') . ($b & 1 ? 'x' : '-');
  }
  return $s;
}

# One directory entry as the UI wants it. $full is the path to lstat.
sub describe {
  my ($full, $name) = @_;
  my @l = lstat($full) or return undef;
  my ($text, $bad) = name_text($name);
  my %e = ( name => $text, size => $l[7] + 0, mtime => $l[9] + 0,
            mode => mode_text($l[2]), owner => uname($l[4]) . '', group => gname($l[5]) . '' );
  $e{badname} = 1 if $bad;
  if (S_ISLNK($l[2])) {
    $e{link} = 1;
    # Where the link leads decides what it can be used as; one that leaves the
    # root (or dangles) is listed but is neither a folder nor a download.
    my $real = realpath($full);
    if (defined $real && -e $real && inside($real)) {
      $e{type} = (-d $real) ? 'dir' : (-f $real) ? 'file' : 'other';
      $e{size} = (-s $real) + 0 if $e{type} eq 'file';
      $e{readable} = ($e{type} eq 'dir') ? ((-r $real && -x $real) ? 1 : 0) : ((-r $real) ? 1 : 0);
    } else {
      $e{type} = 'other';
      $e{readable} = 0;
    }
  }
  elsif (S_ISDIR($l[2])) { $e{type} = 'dir';  $e{readable} = (-r $full && -x $full) ? 1 : 0; }
  elsif (S_ISREG($l[2])) { $e{type} = 'file'; $e{readable} = (-r $full) ? 1 : 0; }
  else                   { $e{type} = 'other'; $e{readable} = 0; }
  return \%e;
}

# ---------------------------------------------------------------- list
if ($op eq 'list') {
  my @c = comps($ARGV[0]);
  my $dir = real_dir(@c);
  opendir(my $dh, $dir) or fail(errcode(), $!);
  my @entries;
  while (defined(my $n = readdir($dh))) {
    next if $n eq '.' || $n eq '..' || $n =~ /\Q$PART\E$/;
    my $e = describe("$dir/$n", $n) or next;
    push @entries, $e;
  }
  closedir $dh;
  # "writable" is what the signed-in account may do here: it is running this
  # script, so the kernel's answer to -w/-x is the real one.
  my $writable = (@c >= $MIN_DEPTH && -w $dir && -x $dir) ? 1 : 0;
  out({ ok => 1, entries => \@entries, writable => $writable,
        protected => (@c < $MIN_DEPTH ? 1 : 0) });
  exit 0;
}

# ---------------------------------------------------------------- stat / read
if ($op eq 'stat' || $op eq 'read') {
  my @c = comps($ARGV[0]);
  fail('badpath') unless @c;
  my $real = realpath(join('/', $ROOT_REAL, @c));
  fail('notfound') unless defined $real && -e $real;
  fail('outside')  unless inside($real);
  fail('notfile')  unless -f $real;

  if ($op eq 'stat') {
    fail('denied') unless -r $real;
    out({ ok => 1, size => (-s $real) + 0 });
    exit 0;
  }

  # An optional byte limit: a text preview needs only the start of a file.
  my $left = (defined $ARGV[1] && $ARGV[1] =~ /^\d+$/) ? $ARGV[1] : undef;
  sysopen(my $in, $real, O_RDONLY) or fail(errcode(), $!);
  binmode(STDOUT);
  $| = 1;
  while (!defined $left || $left > 0) {
    my $want = 1 << 20;
    $want = $left if defined $left && $left < $want;
    my $n = sysread($in, my $buf, $want);
    last unless $n;                       # 0 = EOF, undef = read error
    $left -= $n if defined $left;
    my $off = 0;
    while ($off < $n) {
      my $w = syswrite(STDOUT, $buf, $n - $off, $off);
      exit 1 unless defined $w;           # the browser went away
      $off += $w;
    }
  }
  exit 0;
}

# ---------------------------------------------------------------- zip
# Download files and folders as one zip, streamed: nothing is staged on disk
# and nothing large is held in memory, so a folder of any size can be fetched.
# Entries are stored, not compressed -- a NAS holds mostly photos, video and
# archives that don't compress, and storing costs no CPU -- and written with
# ZIP64 records where sizes or offsets pass 4 GB.
#
# Like every op it runs as the signed-in account, so what it can't read is
# left out; so are links to folders (they could loop, or lead out of the
# root), other filesystems below a folder (snapshots, nested subvolumes) and
# anything that is neither a file nor a folder. What was left out is listed in
# a text file added at the end of the zip.

# The items to zip, checked: each exists and is inside the root. Returns a
# list of [dir, name, full].
sub zip_items {
  fail('badpath') unless @ARGV;
  my @items;
  foreach my $rel (@ARGV) {
    my ($dir, $name, $full) = entry($rel, 0);
    my @l = lstat($full) or fail('notfound');
    my $real = realpath($full);
    fail('outside')  unless defined $real && inside($real);
    fail('denied')   unless -r $real && (!-d $real || -x $real);
    fail('notfound') unless -f $real || -d $real;
    push @items, [$dir, $name, $full];
  }
  return @items;
}

if ($op eq 'zipcheck') {
  zip_items();
  out({ ok => 1 });
  exit 0;
}

if ($op eq 'zip') {
  my @items = zip_items();
  binmode(STDOUT);

  my $pos  = 0;           # bytes written so far: the next entry's offset
  my $obuf = '';
  my (@cd, @skipped);
  my $Z64  = 0xFFFFFFFF;    # "see the ZIP64 record" placeholder
  # Sizes and offsets from this value up go into ZIP64 records. Only the
  # tests lower it, to exercise those records without 4 GB of data.
  my $LIM  = ($ENV{EASYNAS_ZIP64_AT} // '') =~ /^\d+$/ ? $ENV{EASYNAS_ZIP64_AT} : $Z64;

  my $flush = sub {
    my $off = 0;
    while ($off < length $obuf) {
      my $w = syswrite(STDOUT, $obuf, length($obuf) - $off, $off);
      exit 1 unless defined $w;              # the browser went away
      $off += $w;
    }
    $obuf = '';
  };
  my $emit = sub { $obuf .= $_[0]; $pos += length $_[0]; $flush->() if length $obuf >= (1 << 20); };

  # MS-DOS date and time, local time, as zip wants them.
  my $dostime = sub {
    my @t = localtime(shift);
    my $y = $t[5] + 1900; $y = 1980 if $y < 1980;
    return (($t[2] << 11) | ($t[1] << 5) | int($t[0] / 2),
            (($y - 1980) << 9) | (($t[4] + 1) << 5) | $t[3]);
  };

  # One entry. $path is the name inside the zip (bytes), $full what to read
  # (undef for a folder), @st its stat.
  my $add = sub {
    my ($path, $full, @st) = @_;
    my $isdir = !defined $full;
    $path .= '/' if $isdir;
    my $utf8  = defined eval { my $c = $path; Encode::decode('UTF-8', $c, Encode::FB_CROAK) };
    my ($time, $date) = $dostime->($st[9]);
    my $offset = $pos;

    my ($fh, $size, $crc) = (undef, 0, 0);
    if (!$isdir) {
      if (!sysopen($fh, $full, O_RDONLY)) { push @skipped, [$path, "$!"]; return; }
      $size = $st[7];
    }
    # A file that may pass 4 GB gets ZIP64 sizes from its local header on.
    my $big   = !$isdir && $size >= $LIM;
    my $flags = ($isdir ? 0 : 0x08) | ($utf8 ? 0x800 : 0);
    my $need  = $big ? 45 : 20;
    my $lextra = $big ? pack('vvQ<Q<', 1, 16, 0, 0) : '';
    $emit->(pack('VvvvvvVVVvv', 0x04034b50, $need, $flags, 0, $time, $date, 0,
                 ($big ? ($Z64, $Z64) : (0, 0)), length $path, length $lextra) . $path . $lextra);

    if (!$isdir) {
      # Read no more than the size taken at the start, so the entry stays
      # consistent with a file that grows while it is being zipped.
      my ($done, $left) = (0, $size);
      while ($left > 0) {
        my $n = sysread($fh, my $buf, $left < (1 << 20) ? $left : (1 << 20));
        if (!defined $n) { push @skipped, [$path, "read error after $done bytes: $!"]; last; }
        last if $n == 0;                   # shrank meanwhile
        $crc = Compress::Raw::Zlib::crc32($buf, $crc);
        $emit->($buf);
        $done += $n; $left -= $n;
      }
      close $fh;
      $size = $done;
      $emit->($big ? pack('VVQ<Q<', 0x08074b50, $crc, $size, $size)
                   : pack('VVVV',   0x08074b50, $crc, $size, $size));
    }
    my $mode = ($st[2] & 07777) | ($isdir ? 0040000 : 0100000);
    push @cd, { path => $path, flags => $flags, need => $need, time => $time, date => $date,
                crc => $crc, size => $size, offset => $offset,
                attr => (($mode << 16) | ($isdir ? 0x10 : 0)) };
  };

  # A folder and everything below it, depth first. $dev: the filesystem the
  # walk started on; other ones below are not entered.
  my $walk;
  $walk = sub {
    my ($path, $full, $dev) = @_;
    my @st = stat($full);
    $add->($path, undef, @st);
    my $dh;
    if (!opendir($dh, $full)) { push @skipped, ["$path/", "$!"]; return; }
    my @names = sort grep { $_ ne '.' && $_ ne '..' && !/\Q$PART\E$/ } readdir($dh);
    closedir $dh;
    foreach my $n (@names) {
      my ($p, $f) = ("$path/$n", "$full/$n");
      my @l = lstat($f) or next;
      if (S_ISLNK($l[2])) {
        my $real = realpath($f);
        if (defined $real && inside($real) && -f $real) {
          my @s = stat($real);
          $add->($p, $real, @s);
        } else {
          push @skipped, [$p, (defined $real && inside($real) && -d $real) ? 'link to a folder' : 'link leading outside the volumes'];
        }
      }
      elsif (S_ISDIR($l[2])) {
        if ($l[0] != $dev)          { push @skipped, ["$p/", 'another filesystem (snapshot or volume)']; }
        elsif (!-r $f || !-x $f)    { push @skipped, ["$p/", 'permission denied']; }
        else                        { $walk->($p, $f, $dev); }
      }
      elsif (S_ISREG($l[2])) {
        if (-r $f) { $add->($p, $f, @l); }
        else       { push @skipped, [$p, 'permission denied']; }
      }
      else { push @skipped, [$p, 'not a file or folder']; }
    }
  };

  foreach my $it (@items) {
    my ($dir, $name, $full) = @$it;
    my $real = realpath($full);              # a selected link is followed
    my @st = stat($real);
    if (-d $real) { $walk->($name, $real, $st[0]); }
    else          { $add->($name, $real, @st); }
  }

  if (@skipped) {
    my $note = "These were not included in the download:\n\n"
             . join('', map { "$_->[0]  ($_->[1])\n" } @skipped);
    my $tmp = File::Temp->new;
    print $tmp $note; close $tmp;
    my @st = stat("$tmp");
    $st[2] = 0100644; $st[9] = time;
    $add->('EasyNAS - not included.txt', "$tmp", @st);
  }

  # Central directory, then its end record(s).
  my $cd_start = $pos;
  foreach my $e (@cd) {
    my @z64;
    push @z64, $e->{size}, $e->{size} if $e->{size} >= $LIM;
    push @z64, $e->{offset}            if $e->{offset} >= $LIM;
    my $extra = @z64 ? pack('vv', 1, 8 * @z64) . pack('Q<' x @z64, @z64) : '';
    my $need  = @z64 ? 45 : $e->{need};
    my $sz    = $e->{size} >= $LIM ? $Z64 : $e->{size};
    $emit->(pack('VvvvvvvVVVvvvvvVV', 0x02014b50, (3 << 8) | 45, $need, $e->{flags}, 0,
                 $e->{time}, $e->{date}, $e->{crc}, $sz, $sz, length $e->{path}, length $extra,
                 0, 0, 0, $e->{attr}, ($e->{offset} >= $LIM ? $Z64 : $e->{offset}))
            . $e->{path} . $extra);
  }
  my ($cd_size, $count) = ($pos - $cd_start, scalar @cd);
  my $z64_end = $count >= 0xFFFF || $cd_size >= $LIM || $cd_start >= $LIM;
  if ($z64_end) {
    my $z64_at = $pos;
    $emit->(pack('VQ<vvVVQ<Q<Q<Q<', 0x06064b50, 44, (3 << 8) | 45, 45, 0, 0,
                 $count, $count, $cd_size, $cd_start));
    $emit->(pack('VVQ<V', 0x07064b50, 0, $z64_at, 1));
  }
  $emit->(pack('VvvvvVVv', 0x06054b50, 0, 0,
               ($z64_end ? 0xFFFF : $count) x 2,
               ($z64_end ? $Z64 : $cd_size), ($z64_end ? $Z64 : $cd_start), 0));
  $flush->();
  exit 0;
}

# ---------------------------------------------------------------- mkdir
if ($op eq 'mkdir') {
  my $dir  = target_dir($ARGV[0]);
  my $name = $ARGV[1];
  fail('badname') unless good_name($name);
  set_umask($dir);
  mkdir("$dir/$name") or fail(errcode(), $!);
  out({ ok => 1 });
  exit 0;
}

# ---------------------------------------------------------------- mkdirs
# The folders a folder upload needs: <relpath> below <dir>, each level created
# if missing. A level that already exists must be a real folder -- a link is
# never followed here -- so the files that follow land where the listing says.
if ($op eq 'mkdirs') {
  my $dir = target_dir($ARGV[0]);
  my @parts = comps($ARGV[1]);
  fail('badpath') unless @parts;
  foreach my $p (@parts) { fail('badname') unless good_name($p); }
  set_umask($dir);
  my $at = $dir;
  foreach my $p (@parts) {
    my $next = "$at/$p";
    my @l = lstat($next);
    if (@l) {
      fail('notdir', $p) unless S_ISDIR($l[2]) && !S_ISLNK($l[2]);
    } else {
      mkdir($next) or fail(errcode(), $!);
    }
    $at = $next;
  }
  out({ ok => 1 });
  exit 0;
}

# ---------------------------------------------------------------- rename
if ($op eq 'rename') {
  my ($dir, $name, $full) = entry($ARGV[0], 1);
  my $new = $ARGV[1];
  fail('badname')  unless good_name($new);
  fail('notfound') unless lstat($full);
  fail('exists')   if lstat("$dir/$new");
  rename($full, "$dir/$new") or fail(errcode(), $!);
  out({ ok => 1 });
  exit 0;
}

# ---------------------------------------------------------------- delete
if ($op eq 'delete') {
  fail('badpath') unless @ARGV;
  my (@done, @failed);
  foreach my $rel (@ARGV) {
    my ($dir, $name, $full) = entry($rel, 1);
    my ($text) = name_text($name);
    my @l = lstat($full);
    if (!@l) { push @failed, { name => $text, error => 'notfound' }; next; }
    if (S_ISDIR($l[2])) {
      # --one-file-system: never descend into another filesystem or a btrfs
      # subvolume (a nested volume, a snapshot) that happens to live below.
      my ($rc, $err) = run('/bin/rm', '-rf', '--one-file-system', '--', $full);
      if ($rc != 0 || lstat($full)) {
        push @failed, { name => $text, error => ($err =~ /denied|not permitted/i ? 'denied' : 'failed'), detail => $err };
        next;
      }
    }
    elsif (!unlink($full)) {
      push @failed, { name => $text, error => errcode(), detail => "$!" };
      next;
    }
    push @done, $text;
  }
  out({ ok => (@failed ? 0 : 1), done => \@done, failed => \@failed,
        (@failed ? (error => $failed[0]{error}) : ()) });
  exit(@failed ? 1 : 0);
}

# ---------------------------------------------------------------- move / copy
if ($op eq 'move' || $op eq 'copy') {
  my $dest = target_dir(shift @ARGV);
  fail('badpath') unless @ARGV;
  set_umask($dest);
  my (@done, @failed);
  foreach my $rel (@ARGV) {
    # A copy only reads its source, so it may come from anywhere under the
    # root; a move removes it, so the source must be inside a volume too.
    my ($dir, $name, $full) = entry($rel, $op eq 'move');
    my ($text) = name_text($name);
    my @l = lstat($full);
    if (!@l) { push @failed, { name => $text, error => 'notfound' }; next; }

    # Into itself: a folder can't be moved or copied inside its own tree.
    if (S_ISDIR($l[2]) && !S_ISLNK($l[2])) {
      my $src_real = realpath($full);
      if (defined $src_real && ($dest eq $src_real || index($dest, "$src_real/") == 0)) {
        push @failed, { name => $text, error => 'intoitself' };
        next;
      }
    }

    my $target = "$dest/$name";
    if ($op eq 'move' && $dir eq $dest) { push @done, $text; next; }   # already there
    if (lstat($target)) {
      if ($op eq 'copy' && $dir eq $dest) {
        # Copy next to the original: "name (copy)", "name (copy 2)", ...
        my ($stem, $ext) = (S_ISDIR($l[2]) || $name !~ /^(.+)(\.[^.]+)$/) ? ($name, '') : ($1, $2);
        my $i = 1;
        do {
          $target = "$dest/$stem (copy" . ($i > 1 ? " $i" : '') . ")$ext";
          $i++;
        } while (lstat($target) && $i < 1000);
      }
      if (lstat($target)) { push @failed, { name => $text, error => 'exists' }; next; }
    }

    my ($rc, $err);
    if ($op eq 'move') {
      if (rename($full, $target)) { push @done, $text; next; }
      # Across volumes rename() can't do it; mv copies then removes.
      ($rc, $err) = run('/bin/mv', '--', $full, $target);
    } else {
      # -P: copy symlinks as links. --reflink=auto: an instant, space-sharing
      # copy where the filesystem supports it (btrfs), a plain one elsewhere.
      ($rc, $err) = run('/bin/cp', '-R', '-P', '--reflink=auto',
                        '--preserve=mode,timestamps', '--', $full, $target);
    }
    if ($rc != 0) {
      my $code = $err =~ /denied|not permitted/i ? 'denied'
               : $err =~ /No space|quota/i       ? 'nospace' : 'failed';
      push @failed, { name => $text, error => $code, detail => $err };
      next;
    }
    push @done, $text;
  }
  out({ ok => (@failed ? 0 : 1), done => \@done, failed => \@failed,
        (@failed ? (error => $failed[0]{error}) : ()) });
  exit(@failed ? 1 : 0);
}

# ---------------------------------------------------------------- put
# One chunk of an upload. Chunks are appended to a hidden part file beside the
# destination, in order (the offset must equal what is already there), and the
# part is renamed into place once it reaches the announced size -- so a file
# never appears half-written and an interrupted upload leaves no broken file
# under the real name.
if ($op eq 'put') {
  my ($reldir, $name, $offset, $total, $overwrite) = @ARGV;
  my $dir = target_dir($reldir);
  fail('badname') unless good_name($name) && length($name) + length($PART) + 1 <= 255;
  fail('badarg')  unless defined $offset && $offset =~ /^\d+$/ && defined $total && $total =~ /^\d+$/;
  my $final = "$dir/$name";
  my $part  = "$dir/.$name$PART";

  if ($offset == 0) {
    my @f = lstat($final);
    fail('isdir')  if @f && S_ISDIR($f[2]);
    fail('exists') if @f && !$overwrite;
  }
  set_umask($dir);
  my $fh;
  if ($offset == 0) {
    sysopen($fh, $part, O_WRONLY | O_CREAT | O_TRUNC, 0666) or fail(errcode(), $!);
  } else {
    sysopen($fh, $part, O_WRONLY) or fail(errcode(), $!);
    my $have = (stat($fh))[7];
    if ($have != $offset) {
      out({ ok => 0, error => 'offset', have => $have + 0 });
      exit 1;
    }
    sysseek($fh, $offset, 0);
  }

  binmode(STDIN);
  my $size = $offset;
  while (1) {
    my $n = sysread(STDIN, my $buf, 1 << 20);
    if (!defined $n) { my $e = $! + 0; close $fh; fail(errcode($e), 'read'); }
    last if $n == 0;
    $size += $n;
    if ($size > $total) { close $fh; unlink $part; fail('toolarge'); }
    my $off = 0;
    while ($off < $n) {
      my $w = syswrite($fh, $buf, $n - $off, $off);
      if (!defined $w) {
        my ($e, $msg) = ($! + 0, "$!");
        close $fh;
        unlink $part if $e == ENOSPC || $e == EDQUOT;
        fail(errcode($e), $msg);
      }
      $off += $w;
    }
  }
  close($fh) or fail(errcode(), $!);

  if ($size == $total) {
    rename($part, $final) or fail(errcode(), $!);
    out({ ok => 1, size => $size + 0, done => 1 });
  } else {
    out({ ok => 1, size => $size + 0, done => 0 });
  }
  exit 0;
}

fail('badop');
