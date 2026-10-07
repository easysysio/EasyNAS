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
#   read   <path>                     file contents on stdout
#   mkdir  <dir> <name>
#   rename <path> <newname>
#   delete <path>...
#   move   <destdir> <path>...
#   copy   <destdir> <path>...
#   put    <dir> <name> <offset> <total> <overwrite>   upload chunk on stdin
#
# Every op but `read` prints one line of JSON: {"ok":1,...} or
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

  sysopen(my $in, $real, O_RDONLY) or fail(errcode(), $!);
  binmode(STDOUT);
  $| = 1;
  while (1) {
    my $n = sysread($in, my $buf, 1 << 20);
    last unless $n;                       # 0 = EOF, undef = read error
    my $off = 0;
    while ($off < $n) {
      my $w = syswrite(STDOUT, $buf, $n - $off, $off);
      exit 1 unless defined $w;           # the browser went away
      $off += $w;
    }
  }
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
