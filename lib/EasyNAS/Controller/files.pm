package EasyNAS::Controller::Files;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::File ();
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;
use Mojo::JSON qw(decode_json);
use Mojo::Util qw(encode secure_compare url_escape);
use POSIX qw(WNOHANG);
use easynas;

# Web file manager: browse the volumes, download, upload, copy, move, rename,
# delete, create and remove folders.
#
# This controller never touches the filesystem itself. Every operation is
# handed to lib/EasyNAS/files-helper.pl, run AS THE LINUX ACCOUNT of whoever is
# signed in -- root for the administrator, the NAS account (uid, gid and all
# its groups) for a NAS user -- so what each person may read or change is
# decided by the kernel from ordinary ownership and permission bits, exactly as
# over SMB or SSH. The helper additionally keeps every path inside the volumes
# mount point.
#
# The app is a single-process event loop, so nothing here blocks it: helper
# runs go through Mojo::IOLoop->subprocess and a download is streamed from a
# pipe with backpressure -- a 50 GB copy or download leaves the rest of the UI
# responsive.

my $addon = get_addon_info("files");
my %TEXT  = get_lang_text($addon->{'name'});
my $helper = '/easynas/lib/EasyNAS/files-helper.pl';

# Upload chunk size the page uses. Must stay under Mojolicious' request size
# limit (16 MiB by default); each chunk is one POST.
my $chunk_size = 8 * 1024 * 1024;

# The command that runs the helper as the account in $runas (see runas).
# The service may sudo to root only, so for a NAS user it goes through root and
# setpriv drops to the account before anything else runs: real and effective
# uid and gid, and --init-groups for the supplementary groups, which is what
# makes membership of a share's group count. sudo -n: never prompt.
sub helper_cmd ($runas) {
  my @drop = $runas->{uid} == 0 ? ()
           : ('/usr/bin/setpriv', '--reuid', $runas->{uid}, '--regid', $runas->{gid}, '--init-groups', '--');
  return ('/usr/bin/sudo', '-n', '--', @drop, '/usr/bin/perl', $helper, get_mount_dir());
}

# The Linux account this session acts as -- { name, uid, gid } -- or undef if
# it may not act at all.
sub runas ($self) {
  return { name => 'root', uid => 0, gid => 0 } if ($self->session('role') // 'admin') eq 'admin';
  my $user = $self->session('user') // '';
  return undef unless $user =~ /^[A-Za-z_][A-Za-z0-9_.-]{0,31}$/;
  # Checked on every request: an account removed (or turned into a system
  # account) after sign-in stops working at once.
  my @pw = getpwnam($user);
  return undef unless @pw && $pw[2] >= 1000 && $pw[2] < 65000;
  return { name => $user, uid => $pw[2] + 0, gid => $pw[3] + 0 };
}

# This session's anti-forgery token: random, made on first use, kept in the
# (signed) session cookie and handed to the page, which sends it back in a
# header with every change. Our own rather than Mojolicious' csrf_token helper,
# whose format differs between the Mojolicious versions an appliance may carry.
sub csrf ($self) {
  my $tok = $self->session('files_csrf');
  return $tok if defined $tok && length($tok) == 32;
  open(my $rnd, '<:raw', '/dev/urandom') or die "csrf: /dev/urandom: $!";
  my $n = read($rnd, my $bytes, 16);
  close $rnd;
  die "csrf: short read from /dev/urandom" unless defined $n && $n == 16;
  $tok = unpack('H*', $bytes);
  $self->session(files_csrf => $tok);
  return $tok;
}

# Run a command, optionally with stdin from a file; returns its stdout. Called
# inside a subprocess, so blocking here is fine.
sub capture ($cmd, $stdin = undef) {
  my $pid = open(my $out, '-|');
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    open(STDIN, '<', $stdin // '/dev/null') or POSIX::_exit(126);
    exec { $cmd->[0] } @$cmd or POSIX::_exit(127);
  }
  my $data = do { local $/; <$out> } // '';
  close $out;
  return $data;
}

# Run one helper op without blocking and answer with its JSON. $log, when
# given, is written to the EasyNAS log if the op succeeded.
sub run_op ($self, $runas, $args, %opt) {
  $self->render_later;
  $self->inactivity_timeout(3600);          # large copies and deletes take time
  my @cmd = (helper_cmd($runas), map { encode('UTF-8', $_ // '') } @$args);
  my $stdin = $opt{stdin};
  Mojo::IOLoop->subprocess->run_p(sub { capture(\@cmd, $stdin) })->then(sub ($out) {
    my $res = eval { decode_json($out) };
    $res = { ok => 0, error => 'failed' } unless ref $res eq 'HASH';
    write_log($addon->{name}, "INFO", ($self->session('user') // '?') . ": $opt{log}")
      if $opt{log} && $res->{ok};
    $opt{keep} = undef;                      # the upload's temp file may go now
    $self->render(json => $res);
  })->catch(sub ($err) {
    $self->render(json => { ok => 0, error => 'failed' }, status => 500);
  });
  return;
}

sub view ($self) {
  my $runas = runas($self);
  if (!defined $runas) {
    $self->session(expires => 1);
    return $self->redirect_to('login');
  }
  my $action = $self->param('action') // '';

  if ($self->req->method eq 'POST') {
    # Every change arrives as a POST carrying the session's token in a header,
    # which a page on another site can neither read nor set.
    my $sent = $self->req->headers->header('X-CSRF-Token') // '';
    return $self->render(json => { ok => 0, error => 'csrf' }, status => 403)
      unless $sent ne '' && secure_compare($sent, csrf($self));

    my $path  = $self->param('path') // '';
    my @items = @{ $self->every_param('item') };
    if ($action eq 'mkdir') {
      my $name = $self->param('name') // '';
      return run_op($self, $runas, ['mkdir', $path, $name], log => "created folder $path/$name");
    }
    if ($action eq 'rename') {
      my $name = $self->param('name') // '';
      return run_op($self, $runas, ['rename', $path, $name], log => "renamed $path to $name");
    }
    if ($action eq 'delete' && @items) {
      return run_op($self, $runas, ['delete', @items], log => "deleted " . join(', ', @items));
    }
    if (($action eq 'move' || $action eq 'copy') && @items) {
      my $verb = $action eq 'move' ? 'moved' : 'copied';
      return run_op($self, $runas, [$action, $path, @items],
                    log => "$verb " . join(', ', @items) . " to $path");
    }
    if ($action eq 'upload') { return upload($self, $runas); }
    return $self->render(json => { ok => 0, error => 'badop' }, status => 400);
  }

  if ($action eq 'list') {
    return run_op($self, $runas, ['list', $self->param('path') // '']);
  }
  if ($action eq 'download') { return download($self, $runas); }

  # The page itself. The administrator gets it inside the normal layout; a NAS
  # user gets a bare frame with nothing but the file manager (see the template).
  my $role = ($self->session('role') // 'admin') eq 'admin' ? 'admin' : 'user';
  $self->stash(addon      => $addon,
               TEXT       => \%TEXT,
               is_admin   => ($role eq 'admin' ? 1 : 0),
               username   => ($self->session('user') // ''),
               csrf       => csrf($self),
               chunk_size => $chunk_size);
  $self->render(template => 'easynas/files');
}

# One chunk of an upload: the request body is the bytes; where it goes is in
# the query string. The body is handed to the helper as its stdin.
sub upload ($self, $runas) {
  my $offset = $self->param('offset') // '';
  my $total  = $self->param('total')  // '';
  return $self->render(json => { ok => 0, error => 'badarg' }, status => 400)
    unless $offset =~ /^\d+$/ && $total =~ /^\d+$/;
  my $path = $self->param('path') // '';
  my $name = $self->param('name') // '';

  # Mojolicious keeps a large body in a temp file and a small one in memory;
  # either way, put it in a file of our own that lives until the helper is done.
  my $tmp = Mojo::File::tempfile('easynas-upload-XXXXXX', TMPDIR => 1);
  $self->req->content->asset->move_to("$tmp");

  my $last = ($offset + $tmp->stat->size) >= $total;
  return run_op($self, $runas,
                ['put', $path, $name, $offset, $total, ($self->param('overwrite') ? 1 : 0)],
                stdin => "$tmp", keep => $tmp,
                ($last ? (log => "uploaded $path/$name") : ()));
}

# Stream a file to the browser. The helper's `stat` answers first (does it
# exist, may this account read it, how big is it); then `read` is started and
# its output relayed, pausing the pipe whenever the browser falls behind.
sub download ($self, $runas) {
  my $path = $self->param('path') // '';
  my @base = helper_cmd($runas);
  my $arg  = encode('UTF-8', $path);
  $self->render_later;

  Mojo::IOLoop->subprocess->run_p(sub { capture([@base, 'stat', $arg]) })->then(sub ($out) {
    my $st = eval { decode_json($out) };
    if (ref $st ne 'HASH' || !$st->{ok}) {
      my $err = (ref $st eq 'HASH' && $st->{error}) || 'failed';
      return $self->render(text => ($TEXT{"files_err_$err"} || 'Download failed'),
                           status => ($err eq 'denied' ? 403 : 404));
    }

    my $pid = open(my $fh, '-|', @base, 'read', $arg);
    return $self->render(text => 'Download failed', status => 500) unless $pid;

    my ($name) = $path =~ m{([^/]+)/*$};
    $name //= 'download';
    my $h = $self->res->headers;
    $h->content_type('application/octet-stream');
    $h->content_length($st->{size});
    # Always an attachment, never rendered in the page's origin.
    $h->content_disposition("attachment; filename*=UTF-8''" . url_escape(encode('UTF-8', $name)));
    $h->header('X-Content-Type-Options' => 'nosniff');
    $self->inactivity_timeout(0);

    my $stream = Mojo::IOLoop::Stream->new($fh)->timeout(0);
    my $reap; $reap = sub ($tries) {
      # The helper runs as another account, so it can't be signalled from
      # here; closing the pipe ends it. Collect it without ever blocking.
      return if waitpid($pid, WNOHANG) != 0 || $tries <= 0;
      Mojo::IOLoop->timer(1 => sub { $reap->($tries - 1) });
    };
    $stream->on(read => sub ($s, $bytes) {
      $s->stop;                                            # until this chunk is sent
      $self->write($bytes => sub { $s->start });
    });
    $stream->on(close => sub { $reap->(30); $self->finish; });
    $stream->on(error => sub { $self->finish; });
    $self->on(finish => sub { $stream->close; });          # browser went away
    $stream->start;
    write_log($addon->{name}, "INFO", ($self->session('user') // '?') . ": downloaded $path");
  })->catch(sub ($err) {
    $self->render(text => 'Download failed', status => 500);
  });
  return;
}

1;
