package EasyNAS::Controller::Realm;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;

# The realm addon configures the directory backend that serves share/service
# users (see docs/identity-design.md). v1 supports the two owned backends:
#   local  -- self-contained local accounts (default)
#   ad-dc  -- a local Samba AD Domain Controller (provisioned in the background
#             by startup/realm-setup.sh, the sequence validated by the spike)
# The external consumer backends (ad-member, ldap) come in a later phase.

my $msg;
my $result;
my $addon = get_addon_info("realm");
my %TEXT = get_lang_text($addon->{'name'});

my $status_file = "/etc/easynas/realm.status";
my $realm_conf  = "/etc/easynas/realm.conf";

# POSIX-safe single-quote wrapping for values passed to a shell command.
sub shq { my $s = shift // ""; $s =~ s/'/'\\''/g; return "'$s'"; }

# In-progress state written by realm-setup.sh ("configuring" / "ready" /
# "failed: ..."); empty when no realm has ever been configured.
sub realm_status {
  open(my $fh, '<', $status_file) or return "";
  my $s = <$fh>;
  close $fh;
  chomp $s if defined $s;
  return $s // "";
}

# Record the active backend (read back by easynas.pm get_realm). The app runs
# as the easynas user, which owns /etc/easynas, so it writes this directly.
sub write_realm_conf ($backend, $realm, $domain) {
  if (open(my $fh, '>', $realm_conf)) {
    print $fh "BACKEND=$backend\n";
    print $fh "REALM=$realm\n"   if $realm  ne "";
    print $fh "DOMAIN=$domain\n" if $domain ne "";
    close $fh;
  }
}

sub view ($self) {
  if (!($self->session('is_auth'))) {
    $self->redirect_to('login');
  }
  my $action = $self->param('action');
  $msg = "";
  $result = "";
  $self->stash(addon => $addon, TEXT => \%TEXT);

  if (defined $action && $action eq "configure") { configure($self); }
  if (defined $action && $action eq "leave")     { leave($self); }

  $self->stash(realm  => get_realm(),
               status => realm_status(),
               result => $result,
               msg    => $msg);
  $self->render(template => 'easynas/realm');
}

sub configure ($self) {
  my $backend = $self->param("backend") // "local";

  if ($backend eq "local") {
    write_realm_conf("local", "", "");
    system("/bin/echo ready | /usr/bin/sudo /usr/bin/tee $status_file >/dev/null");
    $result = "success";
    $msg = $TEXT{'realm_local_set'} || "Local accounts backend selected.";
    write_log($addon->{"name"}, "INFO", "Realm backend set to local");
    return;
  }

  if ($backend eq "ad-dc") {
    my $realm  = $self->param("realm")     // "";
    my $domain = $self->param("domain")    // "";
    my $pass   = $self->param("adminpass") // "";
    my $fwd    = $self->param("forwarder") // "1.1.1.1";
    if ($realm eq "" || $domain eq "" || $pass eq "") {
      $result = "fail";
      $msg = $TEXT{'realm_missing'} || "Realm, domain and admin password are required.";
      return;
    }
    # realm/domain go into config + a hostname; keep them to safe characters.
    if ("$realm$domain$fwd" =~ /[^A-Za-z0-9._-]/) {
      $result = "fail";
      $msg = $TEXT{'realm_bad_name'} || "Realm, domain and forwarder may contain only letters, digits, dot and dash.";
      return;
    }
    # Provisioning is long and destructive: run it detached. The script records
    # progress in realm.status and writes realm.conf on success.
    start_bg("/easynas/startup/realm-setup.sh " . join(" ", map { shq($_) } $realm, $domain, $pass, $fwd));
    $result = "success";
    $msg = $TEXT{'realm_provisioning'} || "Provisioning the domain controller. This takes a few minutes -- refresh to check status.";
    write_log($addon->{"name"}, "INFO", "AD DC provisioning started for realm $realm");
    return;
  }

  if ($backend eq "ad-member") {
    my $realm  = $self->param("realm")     // "";
    my $domain = $self->param("domain")    // "";
    my $dcip   = $self->param("dc_ip")     // "";
    my $user   = $self->param("adminuser") // "";
    my $pass   = $self->param("adminpass") // "";
    if ($realm eq "" || $domain eq "" || $dcip eq "" || $user eq "" || $pass eq "") {
      $result = "fail";
      $msg = $TEXT{'realm_join_missing'} || "Realm, domain, DC IP, admin user and password are required.";
      return;
    }
    if ("$realm$domain$dcip$user" =~ /[^A-Za-z0-9._\-\@]/) {
      $result = "fail";
      $msg = $TEXT{'realm_bad_name'} || "Fields may contain only letters, digits, dot, dash, at and underscore.";
      return;
    }
    start_bg("/easynas/startup/realm-join.sh " . join(" ", map { shq($_) } $realm, $domain, $dcip, $user, $pass));
    $result = "success";
    $msg = $TEXT{'realm_joining'} || "Joining the Active Directory domain -- refresh to check status.";
    write_log($addon->{"name"}, "INFO", "AD join started for realm $realm");
    return;
  }

  if ($backend eq "ldap") {
    my $uri    = $self->param("ldap_uri")  // "";
    my $base   = $self->param("ldap_base") // "";
    my $binddn = $self->param("bind_dn")   // "";
    my $bindpw = $self->param("bind_pw")   // "";
    if ($uri eq "" || $base eq "") {
      $result = "fail";
      $msg = $TEXT{'realm_ldap_missing'} || "LDAP URI and search base are required.";
      return;
    }
    start_bg("/easynas/startup/realm-ldap.sh " . join(" ", map { shq($_) } $uri, $base, $binddn, $bindpw));
    $result = "success";
    $msg = $TEXT{'realm_ldap_configuring'} || "Configuring the LDAP directory -- refresh to check status.";
    write_log($addon->{"name"}, "INFO", "LDAP directory configuration started");
    return;
  }

  $result = "fail";
  $msg = $TEXT{'realm_backend_todo'} || "Unknown backend.";
}

# Launch a setup script detached, recording an immediate "configuring" state.
sub start_bg ($cmd) {
  system("/bin/echo configuring | /usr/bin/sudo /usr/bin/tee $status_file >/dev/null");
  system("/usr/bin/nohup /usr/bin/sudo $cmd >/var/log/easynas/realm-setup.log 2>&1 &");
}

sub leave ($self) {
  my $realm = get_realm();
  my $b = $realm->{backend};
  if ($b eq "ad-dc") {
    system("/usr/bin/sudo /usr/bin/systemctl disable --now samba-ad-dc.service samba.service 2>/dev/null");
  }
  elsif ($b eq "ad-member") {
    system("/usr/bin/sudo /usr/bin/systemctl disable --now winbind smb 2>/dev/null");
  }
  elsif ($b eq "ldap") {
    system("/usr/bin/sudo /usr/bin/systemctl disable --now sssd 2>/dev/null");
  }
  # Reset NSS back to files-only.
  system("/usr/bin/sudo /usr/bin/sed -i -E 's/^(passwd:).*/\\1 files/' /etc/nsswitch.conf 2>/dev/null");
  system("/usr/bin/sudo /usr/bin/sed -i -E 's/^(group:).*/\\1 files/'  /etc/nsswitch.conf 2>/dev/null");
  write_realm_conf("local", "", "");
  system("/bin/echo ready | /usr/bin/sudo /usr/bin/tee $status_file >/dev/null");
  $result = "success";
  $msg = $TEXT{'realm_left'} || "Returned to local accounts.";
  write_log($addon->{"name"}, "INFO", "Left realm; backend reset to local");
}

1;
