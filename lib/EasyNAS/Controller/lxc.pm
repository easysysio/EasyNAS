package EasyNAS::Controller::Lxc;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use lib '/easynas/lib/EasyNAS/Controller';
use easynas;

my $addon = get_addon_info("lxc");
my %TEXT = get_lang_text($addon->{'name'});

# A container name as accepted by lxc-* (kept strict: it also becomes a URL
# argument and reaches root commands).
my $NAME_RE = qr/^[A-Za-z0-9._-]{1,64}$/;

########## systems_list ##########
# Current containers from `lxc-ls --fancy` -- read on EVERY request (needs root)
# so state and IP are live. The previous version ran this once at module load
# without sudo, so the list was empty and never refreshed. Columns are
# NAME STATE AUTOSTART GROUPS IPV4 IPV6.
sub systems_list {
 my %systems;
 foreach (`/usr/bin/sudo /usr/bin/lxc-ls --fancy 2>/dev/null`) {
  my ($name,$state,undef,undef,$ip)=split(" ",$_);
  next if (!defined $name || $name eq "" || $name eq "NAME");
  $systems{$name}=[$name,$state,($ip && $ip ne "-") ? $ip : "-"];
 }
 return %systems;
}

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action');
  my $name=$self->param('name');
  my $msg="";
  my $result="";

  ##### start a container #####
  if (defined $action && $action eq "start" && defined $name && $name =~ $NAME_RE) {
    system("/usr/bin/sudo","/usr/bin/lxc-start","-n",$name,"-d");
    write_log("lxc","INFO","Container $name started");
  }

  ##### stop a container #####
  if (defined $action && $action eq "stop" && defined $name && $name =~ $NAME_RE) {
    system("/usr/bin/sudo","/usr/bin/lxc-stop","-n",$name);
    write_log("lxc","INFO","Container $name stopped");
  }

  ##### web terminal into a container #####
  # Serve a one-shot ttyd terminal ATTACHED TO THE CONTAINER (not a host shell)
  # on port 8080, started in its own transient unit (no shell, name passed as a
  # list argument). Redirect to the appliance's OWN address, taken from the
  # request Host header -- never a build-time hardcoded IP.
  if (defined $action && $action eq "terminal" && defined $name && $name =~ $NAME_RE) {
    system("/usr/bin/sudo","/usr/bin/systemd-run","--collect",
           "/usr/bin/ttyd","-p","8080","-o","-W",
           "/usr/bin/lxc-attach","-n",$name);
    my $host=$self->req->headers->host // "";
    $host =~ s/:.*//;                       # drop the app's port
    if ($host ne "") {
      $self->redirect_to("http://$host:8080/");
      return;
    }
  }

  my %systems = systems_list();
  $self->render(template => 'easynas/lxc',
                addon => $addon,
                TEXT => \%TEXT,
                systems => \%systems,
                result => $result,
                msg => $msg);
}

1;
