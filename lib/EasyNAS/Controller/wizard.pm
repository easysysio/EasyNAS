package EasyNAS::Controller::Wizard;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;

# The setup wizard: a new appliance's first share in four steps --
#   1 a user, 2 a filesystem on the free disks, 3 a volume on it,
#   4 a Samba share of the volume -- then 5, how to connect.
# Each step can also take something that already exists, or be skipped.
#
# The steps run the very functions the Users, Filesystem, Volume and Samba
# pages run (createuser, createfs, createvol, add_share), with the wizard's
# choices given to them as the form they expect, and read back their
# $result/$msg. So the checks and the commands are the same in both places.
#
# Sign-in lands here while setup_needed() (easynas.pm): until the wizard is
# finished or dismissed, and only while there's no data filesystem. The right
# menu opens it at any time.
#
# Each step is a POST that redirects to the next step's GET (so a reload
# never repeats one); what was picked so far is kept in the session.

my $addon = get_addon_info("wizard") || { name => "wizard", program => "wizard" };
my %TEXT = get_lang_text($addon->{'name'});

# The Samba add-on may not be installed; its page's controller is loaded
# with the others when it is.
sub samba_ready { return EasyNAS::Controller::Samba->can('add_share') ? 1 : 0; }

# Data filesystems (not the system's).
sub data_fs { my %fs = fs_info(); return sort grep { $_ ne 'ROOT' && $_ ne 'BOOT' } keys %fs; }

sub view ($self) {
  my $action = $self->param('action') // '';
  if ($self->req->method eq 'POST' && $action ne '') {
    my ($res, $msg, $next) = run_step($self, $action);
    return unless defined $next;        # finished: already sent on
    $self->flash(result => $res, msg => $msg) if defined $msg && $msg ne '';
    $self->redirect_to("/wizard?step=$next");
    return;
  }

  my $step = $self->param('step') // '';
  $step = 1 unless $step =~ /^[1-5]$/;
  my %stash = (
    addon   => $addon,
    TEXT    => \%TEXT,
    step    => $step,
    result  => $self->flash('result') // '',
    msg     => $self->flash('msg') // '',
    w_user  => $self->session('wizard_user')  // '',
    w_fs    => $self->session('wizard_fs')    // '',
    w_vol   => $self->session('wizard_vol')   // '',
    w_share => $self->session('wizard_share') // '',
    samba   => samba_ready(),
    host    => $self->req->url->to_abs->host // '',
    users => [], disks => [], filesystems => [], volumes => [],
  );
  if ($step == 1) {
    my %users = users_info();
    $stash{users} = [sort keys %users];
  }
  elsif ($step == 2) {
    my %disks = disk_info();
    $stash{disks} = [map { $disks{$_} } sort grep { ($disks{$_}[3] // '') eq 'disk_free' } keys %disks];
    $stash{filesystems} = [data_fs()];
  }
  elsif ($step == 3 || $step == 4) {
    $stash{filesystems} = [data_fs()];
    my %vols = vol_info();
    $stash{volumes} = [sort keys %vols];
  }
  $self->stash(%stash);
  $self->render(template => 'easynas/wizard');
}

# One step's POST: (result, message, the step to show next). No next step
# when the wizard is done and the answer already sent.
sub run_step ($self, $action) {
  my $mode = $self->param('mode') // 'new';

  if ($action eq 'finish' || $action eq 'dismiss') {
    setup_done();
    delete $self->session->{$_} for qw(wizard_user wizard_fs wizard_vol wizard_share);
    write_log("wizard","INFO", $action eq 'finish' ? "setup wizard finished" : "setup wizard closed");
    $self->redirect_to('/');
    return;
  }

  if ($action eq 'skip' || $action eq 'back') {
    my $from = $self->param('from') // '';
    $from = 1 unless $from =~ /^[1-5]$/;
    my $to = $action eq 'skip' ? $from + 1 : $from - 1;
    $to = 1 if $to < 1;
    $to = 5 if $to > 5;
    return ('', '', $to);
  }

  ##### 1: user #####
  if ($action eq 'user') {
    if ($mode eq 'existing') {
      my $name = $self->param('existing') // '';
      my %users = users_info();
      return ('fail', $TEXT{'wizard_pick_user'}, 1) unless exists $users{$name};
      $self->session(wizard_user => $name);
      return ('', '', 2);
    }
    my $name = $self->param('user_name') // '';
    my ($res, $msg) = call('EasyNAS::Controller::Users', \&EasyNAS::Controller::Users::createuser, $self,
      name => $name, desc => '', password1 => $self->param('password1') // '',
      password2 => $self->param('password2') // '', groups => [], admin => 0);
    return ('fail', $msg, 1) unless $res eq 'success';
    $self->session(wizard_user => $name);
    return ('success', $msg, 2);
  }

  ##### 2: filesystem #####
  if ($action eq 'fs') {
    if ($mode eq 'existing') {
      my $fs = $self->param('existing') // '';
      return ('fail', $TEXT{'wizard_pick_fs'}, 2) unless grep { $_ eq $fs } data_fs();
      $self->session(wizard_fs => $fs);
      return ('', '', 3);
    }
    my @disks = grep { /^[A-Za-z0-9]+$/ } @{$self->every_param('disks')};
    return ('fail', $TEXT{'no_disks_were_selected'} || 'Select a disk.', 2) unless @disks;
    return ('fail', $TEXT{'wizard_confirm_erase'}, 2) unless $self->param('erase');
    # Only disks nothing is on: the form lists those, but check again here.
    my %disks = disk_info();
    for (@disks) {
      return ('fail', $TEXT{'wizard_disk_not_free'}, 2) unless ($disks{$_}[3] // '') eq 'disk_free';
    }
    my $fs = $self->param('fs_name') // '';
    # One disk as is; two or more mirrored (btrfs keeps two copies of
    # everything, so any one disk can fail).
    my ($res, $msg) = call('EasyNAS::Controller::Filesystem', \&EasyNAS::Controller::Filesystem::createfs, $self,
      disks => \@disks, name => $fs, raid => (@disks > 1 ? 'raid1' : 'single'),
      mount => 'read&write', automount => 1, ssd => 0, defrag => 0, compress => '');
    return ('fail', $msg, 2) unless $res eq 'success';
    write_log("wizard","INFO","filesystem $fs created on ".join(' ', @disks));
    $self->session(wizard_fs => $fs);
    return ('success', $msg, 3);
  }

  ##### 3: volume #####
  if ($action eq 'vol') {
    if ($mode eq 'existing') {
      my $vol = $self->param('existing') // '';
      my %vols = vol_info();
      return ('fail', $TEXT{'wizard_pick_vol'}, 3) unless exists $vols{$vol};
      $self->session(wizard_vol => $vol);
      return ('', '', 4);
    }
    my $fs   = $self->param('fs') // '';
    my $name = $self->param('vol_name') // '';
    return ('fail', $TEXT{'wizard_pick_fs'}, 3) unless grep { $_ eq $fs } data_fs();
    # "Only <user>": that user owns it and nobody else gets in. "All users":
    # the users group shares it. With no user picked, root owns it and the
    # group shares it.
    my $user = $self->session('wizard_user') // '';
    $user = '' unless $user ne '' && getpwnam($user);
    my $only = ($self->param('access') // '') eq 'only' && $user ne '';
    my ($res, $msg) = call('EasyNAS::Controller::Volume', \&EasyNAS::Controller::Volume::createvol, $self,
      name => $name, fs => $fs, user => ($user ne '' ? $user : 'root'), group => get_group_default(),
      user_perm => 'read&write', group_perm => ($only ? 'deny' : 'read&write'), others_perm => 'deny');
    return ('fail', $msg, 3) unless $res eq 'success';
    $self->session(wizard_vol => "$fs/$name");
    return ('success', $msg, 4);
  }

  ##### 4: Samba share #####
  if ($action eq 'share') {
    return ('fail', $TEXT{'wizard_samba_missing'}, 4) unless samba_ready();
    my $vol = $self->param('vol') // '';
    my %vols = vol_info();
    return ('fail', $TEXT{'wizard_pick_vol'}, 4) unless exists $vols{$vol};
    my $share = $self->param('share_name') // '';
    my ($res, $msg) = call('EasyNAS::Controller::Samba', \&EasyNAS::Controller::Samba::add_share, $self,
      name => $share, vol => $vol, readonly => 'no', guest => 'no', browsable => 'yes', recycle => 'no');
    return ('fail', $msg, 4) unless $res eq 'success';
    EasyNAS::Controller::Samba::samba_start();
    $self->session(wizard_share => $share);
    return ('success', $msg, 5);
  }

  return ('', '', 1);
}

# Run another page's function with %form as its request parameters, and
# return its ($result, $msg). The parameters are set as captures, which a
# controller's param() and every_param() return ahead of the request's own.
sub call ($pkg, $fn, $self, %form) {
  no strict 'refs';
  ${"${pkg}::result"} = '';
  ${"${pkg}::msg"}    = '';
  my $captures = $self->stash->{'mojo.captures'} //= {};
  my %saved = map { $_ => [exists $captures->{$_}, $captures->{$_}] } keys %form;
  @$captures{keys %form} = values %form;
  $fn->($self);
  for (keys %saved) {
    if ($saved{$_}[0]) { $captures->{$_} = $saved{$_}[1] } else { delete $captures->{$_} }
  }
  return (${"${pkg}::result"} // '', ${"${pkg}::msg"} // '');
}

1;
