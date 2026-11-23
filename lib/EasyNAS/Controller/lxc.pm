package EasyNAS::Controller::Lxc;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use lib '/easynas/lib/EasyNAS/Controller';
use easynas;

my $addon = get_addon_info("lxc");
my %TEXT = get_lang_text($addon->{'name'});

# Everything that needs root goes through this helper, with list arguments.
my $HELPER = "/easynas/startup/lxc-helper.sh";

# A container name as lxc-* accepts it, kept strict: it reaches root commands.
my $NAME_RE = qr/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

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
# or "" for the system disk.
sub storage_vol {
  my $mount_dir = get_mount_dir();
  open(my $fh, '<', '/etc/fstab') or return "";
  while (<$fh>) {
    if (m{^(\S+)/lxc\s+/var/lib/lxc\s.*easynas-lxc-storage}) {
      my $p = $1; $p =~ s{^\Q$mount_dir\E/}{}; close $fh; return $p;
    }
  }
  close $fh;
  return "";
}

sub helper (@args) { return system("/usr/bin/sudo", $HELPER, @args) == 0 ? 1 : 0; }

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
  if ($post && $action eq "create") {
    my %img = images();
    my ($dist, $rel) = split(/:/, $self->param('image') // '', 2);
    my $net  = ($self->param('network') // '') eq 'lan' ? 'lan' : 'nat';
    my $auto = $self->param('autostart') ? 1 : 0;
    my %systems = systems_list();
    if (!$named) {
      $result = "fail"; $msg = $T->('lxc_bad_name', "A name has letters, digits, '.', '_' and '-', and starts with a letter or digit.");
    } elsif ($systems{$name}) {
      $result = "fail"; $msg = $T->('lxc_exists', 'There is already a container with that name.');
    } elsif (!defined $rel || !grep { $_ eq $rel } @{$img{$dist // ''} // []}) {
      $result = "fail"; $msg = $T->('lxc_bad_image', 'Pick an image from the list.');
    } elsif (system("/usr/bin/sudo","/usr/bin/systemd-run","--collect","--quiet","--unit=easynas-lxc-create-$name",
                    $HELPER,"create",$name,$dist,$rel,lxc_arch(),$net,$auto) != 0) {
      $result = "fail"; $msg = $T->('lxc_failed', 'That did not work. See /var/log/easynas/lxc.log.');
    } else {
      write_log("lxc","INFO","Creating container $name from $dist $rel");
      $result = "success";
      $msg = $T->('lxc_creating', 'Downloading the image and creating the container. This takes a few minutes; the list updates by itself.');
    }
  }

  ##### storage #####
  if ($post && $action eq "setstorage") {
    my $sel = $self->param('radio_sel') // '';
    my $vol = $self->param('vol') // '';
    my $target = $sel eq 'internal' ? 'internal'
               : ($sel eq 'vol' && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$} && $vol !~ /\.\./) ? get_mount_dir()."/$vol"
               : undef;
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

  ##### web terminal into a container #####
  # A one-shot ttyd attached to the container (not a host shell) on port 8080,
  # guarded by a fresh random credential handed only to the admin who clicked,
  # at the appliance's own address from the Host header.
  if ($post && $action eq "terminal" && $named) {
    my @c = (0..9,'a'..'f');
    my $token = join('', map { $c[int rand @c] } 1..32);
    my $host = $self->req->headers->host // "";
    $host =~ s/:\d+$//;
    if ($host =~ /^[A-Za-z0-9.-]+$|^\[[0-9A-Fa-f:.]+\]$/ && helper("terminal", $name, $token)) {
      # Not redirect_to: Mojo::URL leaves the user:password part out of the
      # URL it writes, and without it ttyd only asks for a login nobody knows.
      $self->res->headers->location("http://easynas:$token\@$host:8080/");
      $self->rendered(302);
      return;
    }
    $result = "fail"; $msg = $T->('lxc_terminal_failed', 'The terminal did not start. Is the container running?');
  }

  ##### pages #####
  $self->stash(addon => $addon, TEXT => \%TEXT, result => $result, msg => $msg);
  if ($action eq "createlxcmenu") {
    my %img = images();
    $self->render(template => 'easynas/lxc_create', images => \%img, arch => lxc_arch(),
                  storage_vol => storage_vol());
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

1;
