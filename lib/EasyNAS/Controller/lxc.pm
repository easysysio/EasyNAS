package EasyNAS::Controller::Lxc;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use lib '/easynas/lib/EasyNAS/Controller';
use easynas;
use Mojo::IOLoop::Stream;
use Mojo::JSON qw(from_json);
use Mojo::Util qw(encode);
use POSIX ();

my $addon = get_addon_info("lxc");
my %TEXT = get_lang_text($addon->{'name'});

# Everything that needs root goes through this helper, with list arguments.
my $HELPER = "/easynas/startup/lxc-helper.sh";

# A container name as lxc-* accepts it, kept strict: it reaches root commands.
my $NAME_RE = qr/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

# How the terminal runs "lxc-helper.sh attach <name>" on a pseudo-terminal:
# ($fh of its master side, $pid). Replaced in t/lxc-web.t.
our $SPAWN = \&spawn_pty;

# The images on offer: the "default" variant of every system image for this
# machine on images.linuxcontainers.org (what lxc-create's download template
# fetches from), as "dist;release;arch;variant;..." lines. Kept for a day in
# the config dir so the Create page doesn't wait on the network every time.
our $IMAGES = "/etc/easynas/lxc-images";
my $INDEX  = "https://images.linuxcontainers.org/meta/1.0/index-system";

# Containers being created (or whose creation failed), as lxc-helper.sh
# reports them: one file per name holding "creating" or "failed".
our $STATE = "/run/easynas-lxc";

sub lxc_arch {
  my $m = `/usr/bin/uname -m`; chomp $m;
  return { x86_64 => 'amd64', aarch64 => 'arm64' }->{$m} // '';
}

# dist => [releases], for this machine's architecture.
sub images {
  my $arch = lxc_arch();
  return () if $arch eq '';
  my @st = stat($IMAGES);
  if (!@st || time - $st[9] > 86400 || !$st[7]) {
    system("/usr/bin/curl","-fsS","--connect-timeout","5","--max-time","20","-o","$IMAGES.new",$INDEX);
    rename("$IMAGES.new", $IMAGES) if -s "$IMAGES.new";
    unlink("$IMAGES.new");
  }
  my %img;
  open(my $fh, '<', $IMAGES) or return ();
  while (<$fh>) {
    chomp;
    my ($dist,$rel,$a,$variant) = split /;/;
    next unless defined $variant && $a eq $arch && $variant eq 'default';
    next unless "$dist$rel" =~ /^[A-Za-z0-9._-]+$/;
    push @{$img{$dist}}, $rel;
  }
  close $fh;
  return %img;
}

########## systems_list ##########
# Current containers, live on every request (lxc-ls needs root): name =>
# [name, state, ip, autostart]. A container still being created, or whose
# creation failed, shows with that state.
sub systems_list {
  my %systems;
  foreach (`/usr/bin/sudo /usr/bin/lxc-ls -f -F name,state,autostart,ipv4 2>/dev/null`) {
    chomp;
    my ($name,$state,$auto,$ip) = split(" ", $_, 4);
    next if (!defined $name || $name eq "" || $name eq "NAME" || $name !~ $NAME_RE);
    $ip //= ""; $ip =~ s/^\s+|\s+$//g;
    $ip = "-" if $ip eq "";
    $systems{$name} = [$name, $state, $ip, ($auto // '') eq '1' ? 1 : 0];
  }
  if (opendir(my $d, $STATE)) {
    foreach my $name (grep { $_ =~ $NAME_RE } readdir $d) {
      open(my $fh, '<', "$STATE/$name") or next;
      my $s = <$fh> // ''; close $fh; chomp $s;
      $systems{$name} = [$name, ($s eq 'failed' ? 'FAILED' : 'CREATING'), '-', 0] if $s =~ /^(creating|failed)$/;
    }
    closedir $d;
  }
  return %systems;
}

# Where containers are kept: the volume ("pool/vol") from our fstab bind line,
# or "" before one is picked. They are only ever kept on a volume (the system
# disk is wiped by a firmware update): the first container's Create form
# picks it, and every container after goes there too.
our $FSTAB = "/etc/fstab";
sub storage_vol {
  my $mount_dir = get_mount_dir();
  open(my $fh, '<', $FSTAB) or return "";
  while (<$fh>) {
    if (m{^(\S+)/lxc\s+/var/lib/lxc\s.*easynas-lxc-storage}) {
      my $p = $1; $p =~ s{^\Q$mount_dir\E/}{}; close $fh; return $p;
    }
  }
  close $fh;
  return "";
}

# (The path spelled out, as in every sudo of a helper: t/sudo-calls.t looks for it.)
sub helper (@args) { return system("/usr/bin/sudo", "/easynas/startup/lxc-helper.sh", @args) == 0 ? 1 : 0; }

# A volume ("pool/vol") from the Volumes page, as the path lxc-helper.sh
# takes; undef for anything else.
sub volume_path ($vol) {
  return undef unless defined $vol && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$} && $vol !~ /\.\./;
  my %vols = vol_info();
  return exists $vols{$vol} ? get_mount_dir()."/$vol" : undef;
}

sub view ($self) {
  my $action = $self->param('action') // '';
  my $name   = $self->param('name') // '';
  my $msg    = "";
  my $result = "";
  # Changes only on POST; the router already sends a GET asking for one back.
  my $post   = ($self->req->method eq "POST");
  my $named  = ($name =~ $NAME_RE);
  my $T = sub ($key, $default) { $TEXT{$key} || $default };

  ##### start / stop #####
  if ($post && $action eq "start" && $named) {
    # The helper first makes sure of what it needs (AppArmor profile, bridge).
    if (helper("start", $name)) {
      write_log("lxc","INFO","Container $name started");
    } else {
      $result = "fail";
      $msg = $T->('lxc_start_failed', "The container didn't start. The reason is in /var/log/easynas/lxc.log.");
    }
  }
  if ($post && $action eq "stop" && $named) {
    system("/usr/bin/sudo","/usr/bin/lxc-stop","-n",$name);
    write_log("lxc","INFO","Container $name stopped");
  }

  ##### autostart on boot #####
  if ($post && $action eq "autostart" && $named) {
    my $on = $self->param('on') ? 1 : 0;
    if (helper("autostart", $name, $on)) {
      write_log("lxc","INFO","Container $name ".($on ? "starts" : "no longer starts")." at boot");
    } else { $result = "fail"; $msg = $T->('lxc_failed', 'That did not work. See /var/log/easynas/lxc.log.'); }
  }

  ##### delete #####
  if ($post && $action eq "delete" && $named) {
    if (helper("delete", $name)) {
      write_log("lxc","INFO","Container $name deleted");
      $result = "success"; $msg = $T->('lxc_deleted', 'Container deleted.');
    } else { $result = "fail"; $msg = $T->('lxc_failed', 'That did not work. See /var/log/easynas/lxc.log.'); }
  }

  ##### create #####
  # Downloading the image takes minutes, so the helper runs in its own
  # transient unit and the list shows the container as "creating" meanwhile.
  # Containers live on a volume: until one is set, the form asks for it and
  # it is set up first (the helper refuses to create on the system disk).
  if ($post && $action eq "create") {
    my %img = images();
    my ($dist, $rel) = split(/:/, $self->param('image') // '', 2);
    my $net  = ($self->param('network') // '') eq 'lan' ? 'lan' : 'nat';
    my $auto = $self->param('autostart') ? 1 : 0;
    my %systems = systems_list();
    my $new_storage = storage_vol() eq "" ? volume_path($self->param('vol')) : "";
    if (!$named) {
      $result = "fail"; $msg = $T->('lxc_bad_name', "A name has letters, digits, '.', '_' and '-', and starts with a letter or digit.");
    } elsif ($systems{$name}) {
      $result = "fail"; $msg = $T->('lxc_exists', 'There is already a container with that name.');
    } elsif (!defined $rel || !grep { $_ eq $rel } @{$img{$dist // ''} // []}) {
      $result = "fail"; $msg = $T->('lxc_bad_image', 'Pick an image from the list.');
    } elsif (!defined $new_storage) {
      $result = "fail"; $msg = $T->('lxc_bad_vol', 'Pick a volume.');
    } elsif ($new_storage ne "" && !helper("storage", $new_storage)) {
      $result = "fail";
      $msg = $T->('lxc_storage_failed', 'Container storage was not changed. Stop every container first; see /var/log/easynas/lxc.log.');
    } elsif (system("/usr/bin/sudo","/usr/bin/systemd-run","--collect","--quiet","--unit=easynas-lxc-create-$name",
                    $HELPER,"create",$name,$dist,$rel,lxc_arch(),$net,$auto) != 0) {
      $result = "fail"; $msg = $T->('lxc_failed', 'That did not work. See /var/log/easynas/lxc.log.');
    } else {
      write_log("lxc","INFO","Container storage set to $new_storage") if $new_storage ne "";
      write_log("lxc","INFO","Creating container $name from $dist $rel");
      $result = "success";
      $msg = $T->('lxc_creating', 'Downloading the image and creating the container. This takes a few minutes; the list updates by itself.');
    }
  }

  ##### storage: move the containers to another volume #####
  if ($post && $action eq "setstorage") {
    my $target = volume_path($self->param('vol'));
    if (!defined $target) {
      $result = "fail"; $msg = $T->('lxc_bad_vol', 'Pick a volume.');
    } elsif (helper("storage", $target)) {
      write_log("lxc","INFO","Container storage set to $target");
      $result = "success"; $msg = $T->('lxc_storage_saved', 'Container storage changed.');
    } else {
      $result = "fail";
      $msg = $T->('lxc_storage_failed', 'Container storage was not changed. Stop every container first; see /var/log/easynas/lxc.log.');
    }
  }

  ##### pages #####
  $self->stash(addon => $addon, TEXT => \%TEXT, result => $result, msg => $msg);
  # The terminal: a page of its own (it opens in a new tab) that talks to ws()
  # below over this same address, port and sign-in.
  if ($action eq "terminalmenu" && $named) {
    $self->render(template => 'easynas/lxc_terminal', name => $name);
    return;
  }
  if ($action eq "createlxcmenu") {
    my %img = images();
    my %vol = vol_info();
    $self->render(template => 'easynas/lxc_create', images => \%img, arch => lxc_arch(),
                  storage_vol => storage_vol(), volumes => \%vol);
    return;
  }
  if ($action eq "storagemenu") {
    my %vol = vol_info();
    $self->render(template => 'easynas/lxc_storage', volumes => \%vol, storage_vol => storage_vol());
    return;
  }
  my %systems = systems_list();
  $self->render(template => 'easynas/lxc', systems => \%systems, storage_vol => storage_vol(),
                busy => (grep { $_->[1] eq 'CREATING' } values %systems) ? 1 : 0);
}

########## the terminal ##########
# A shell in a container, in the browser: the page (lxc_terminal.html.ep)
# runs xterm.js and opens a WebSocket here (/lxc/ws?name=..., admin only, the
# same sign-in as every page); this end runs lxc-attach on a pseudo-terminal
# and passes the bytes both ways. The client sends JSON: {"t":"i","d":text}
# typed, {"t":"r","c":cols,"r":rows} resized, {"t":"p"} keep-alive. Output
# goes back as binary frames. Closing the tab hangs the shell up.
#
# (It used to be ttyd on port 8080, but Tumbleweed's ttyd 1.7.7 with
# libwebsockets 5 closes right after it starts listening.)
sub ws ($self) {
  my $name = $self->param('name') // '';
  # Only from this appliance's own pages: a page elsewhere can open a
  # WebSocket here too, and the browser would send the session cookie along.
  my $origin = $self->req->headers->origin // '';
  my $host   = $self->req->headers->host // '';
  if ($name !~ $NAME_RE || $host eq '' || $origin !~ m{^https?://\Q$host\E$}i) {
    write_log("lxc","WARNING","refused a terminal connection".($name =~ $NAME_RE ? " to $name" : "")." from origin \"".
              substr($origin =~ s/[^A-Za-z0-9:\/._\[\]-]/?/gr, 0, 80)."\"");
    return $self->render(text => 'Forbidden', status => 403);
  }
  my ($fh, $pid) = $SPAWN->($name);
  return $self->render(text => 'The terminal did not start.', status => 500) unless $fh;
  write_log("lxc","INFO","Terminal opened to container $name");

  # The page pings every 30 seconds, so a connection quiet for longer is gone.
  $self->inactivity_timeout(120);
  my $stream = Mojo::IOLoop::Stream->new($fh);
  $stream->timeout(0);
  my $sid = Mojo::IOLoop->stream($stream);
  my $done;
  my $end = sub {
    return if $done++;
    Mojo::IOLoop->remove($sid);
    close $fh;                            # the master: the shell gets SIGHUP
    reap($pid);
    write_log("lxc","INFO","Terminal to container $name closed");
  };
  $stream->on(read  => sub ($s, $bytes) { $self->send({binary => $bytes}) });
  $stream->on(error => sub { $self->finish; $end->() });   # EIO: the shell exited
  $stream->on(close => sub { $self->finish; $end->() });
  $self->on(message => sub ($c, $msg) {
    my $m = eval { from_json($msg) };
    return unless ref $m eq 'HASH' && defined $m->{t};
    if ($m->{t} eq 'i' && defined $m->{d} && !ref $m->{d}) { $stream->write(encode('UTF-8', $m->{d})) }
    elsif ($m->{t} eq 'r') { resize($fh, $m->{r}, $m->{c}) }
  });
  $self->on(finish => sub { $end->() });
}

# The terminal size the shell sees (TIOCSWINSZ on the master; the shell is
# sent SIGWINCH).
sub resize ($fh, $rows, $cols) {
  return unless defined $rows && defined $cols && "$rows$cols" =~ /^\d+$/;
  return unless $rows > 0 && $rows < 1000 && $cols > 0 && $cols < 1000 && -t $fh;
  my $req = eval { require IO::Tty; IO::Tty::Constant::TIOCSWINSZ() } // return;
  ioctl($fh, $req, pack('S4', $rows, $cols, 0, 0));
}

# Collect the attach process once it has exited (closing the master hangs it
# up); one that ignores the hangup is killed.
sub reap ($pid) {
  return unless $pid && $pid > 0;
  return if waitpid($pid, POSIX::WNOHANG()) != 0;
  my $tries = 0;
  my $tid; $tid = Mojo::IOLoop->recurring(0.5 => sub ($loop) {
    my $r = waitpid($pid, POSIX::WNOHANG());
    kill 'KILL', $pid if $r == 0 && ++$tries == 10;
    $loop->remove($tid) if $r != 0 || $tries > 20;
  });
}

# Run the helper's "attach" on a new pseudo-terminal: its own session, with
# the terminal's slave side as its controlling terminal and stdio.
sub spawn_pty ($name) {
  my $pty = eval { require IO::Pty; IO::Pty->new };
  if (!$pty) { write_log("lxc","ERROR","terminal: no pseudo-terminal (perl IO::Pty): ".($@ || $!)); return; }
  my $pid = fork;
  if (!defined $pid) { write_log("lxc","ERROR","terminal: fork failed: $!"); return; }
  if (!$pid) {
    eval {
      $pty->make_slave_controlling_terminal;
      my $slave = $pty->slave;
      close $pty;
      open(STDIN,  '<&', $slave) or die;
      open(STDOUT, '>&', $slave) or die;
      open(STDERR, '>&', $slave) or die;
      close $slave;
      $ENV{TERM} = 'xterm-256color';
      exec('/usr/bin/sudo', '/easynas/startup/lxc-helper.sh', 'attach', $name);
    };
    POSIX::_exit(127);
  }
  $pty->close_slave;
  $pty->blocking(0);
  return ($pty, $pid);
}

1;
