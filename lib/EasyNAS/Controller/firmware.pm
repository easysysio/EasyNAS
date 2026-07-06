package EasyNAS::Controller::Firmware;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use XML::LibXML;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("firmware");
my %TEXT=get_lang_text($addon->{'name'});

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
        return;
  }
  my $action=$self->param('action');

  # Lightweight status endpoint: the global update banner polls this while an
  # update runs so the page can refresh itself when it finishes.
  if (defined $action && $action eq "status") {
    $self->render(text => update_state());
    return;
  }

  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

#### Update #####
 if (defined $action && $action eq "update") {
  update($self);
 }

#### Reboot #####
 if (defined $action && $action eq "reboot") {
  reboot_system($self);
 }

#### Refresh #####
 if (defined $action && $action eq "refresh") {
  refresh($self);
 }


##### Menu ######
  my $dom="";
  my $updates="/etc/easynas/easynas.updates";
  my %updates;
  my $update;
  my $package;
  my $desc;
  my $new_ver;
  my $old_ver;
  if (-e $updates) {
   $dom = XML::LibXML->load_xml(location => $updates);
   foreach $update ($dom->findnodes('/stream/update-status/update-list/update')) {
    $package=$update->findvalue('./@name');
    $desc=$update->findvalue('./summary');
    $new_ver=$update->findvalue('./@edition');
    $old_ver=$update->findvalue('./@edition-old');
    $updates{$package}=[$package,$desc,$old_ver,$new_ver];
   }
  }
  else {
   $result="fail";
   $msg=$TEXT{'firmware_noupdate'};
  }
 
  $self->stash(result => $result,
               msg => $msg,
	       update_state => update_state(),
	       updates => \%updates);
  $self->render(template => 'easynas/firmware');
}

# Background update progress: "updating" / "ready" (reboot to apply) / "failed".
my $update_status="/etc/easynas/update.status";
sub update_state {
 open(my $fh,'<',$update_status) or return "";
 my $s=<$fh>; close $fh;
 chomp $s if defined $s;
 return $s // "";
}

# The EasyNAS channel repo is either EasyNAS (stable) or EasyNAS_Beta (testing);
# only one is enabled per image. Query updates from whichever is enabled instead
# of hardcoding the stable alias, so this also works on a testing image.
sub active_repo {
 my $repo="EasyNAS";
 foreach (`/usr/bin/sudo /usr/bin/zypper --quiet lr -E 2>/dev/null`) {
  if (/\bEasyNAS_Beta\b/) { $repo="EasyNAS_Beta"; last; }
 }
 return $repo;
}

sub write_update_list {
 my $repo=active_repo();
 system("/usr/bin/sudo /usr/bin/zypper --quiet -x lu -a --repo $repo | /usr/bin/sudo /usr/bin/tee /etc/easynas/easynas.updates >/dev/null");
}

##### update (whole system) #####
# Upgrade the OS and every EasyNAS package together with 'zypper dup', so the
# appliance is fully consistent after an update. If the root is btrfs with
# snapper-zypp-plugin, dup auto-creates a bootable pre/post snapshot, so a bad
# update can be rolled back by booting the previous snapshot from GRUB (see
# docs/btrfs-snapshots-design.md). We do NOT hot-restart the service -- the user
# reboots afterward so a new kernel/OS/app all take effect at once.
#
# dup is long, so run it detached and track progress in update.status; the page
# shows a Reboot button when it reaches "ready".
sub update($self) {
 system("/bin/echo updating | /usr/bin/sudo /usr/bin/tee $update_status >/dev/null");
 # --allow-vendor-change: the image mixes vendors (base openSUSE + the KIWI
 # build repo Virtualization:Appliances + EasyNAS), and dup otherwise stops on
 # a vendor-change problem and -- being non-interactive -- cancels. Allowing it
 # lets dup consolidate onto the enabled repos. --replacefiles handles the
 # occasional file conflict on a full upgrade.
 system("/usr/bin/nohup /bin/sh -c '"
       ."/usr/bin/sudo /usr/bin/zypper -n --gpg-auto-import-keys dup --allow-vendor-change --replacefiles "
       ."&& echo ready | /usr/bin/sudo /usr/bin/tee $update_status "
       ."|| echo failed | /usr/bin/sudo /usr/bin/tee $update_status"
       ."' >/var/log/easynas/update.log 2>&1 &");
 $result="success";
 $msg=$TEXT{'firmware_updating'} || "Updating the system in the background. When it finishes, reboot to apply.";
 write_update_list();
 return;
}

##### reboot #####
sub reboot_system($self) {
 system("/bin/echo | /usr/bin/sudo /usr/bin/tee $update_status >/dev/null");   # clear state
 system("/bin/sh -c '/bin/sleep 2; /usr/bin/sudo /usr/bin/systemctl reboot' >/dev/null 2>&1 &");
 $result="success";
 $msg=$TEXT{'firmware_rebooting'} || "Rebooting to apply the update...";
 return;
}

#####  Refresh #####
sub refresh($self) {
 # Pull fresh repo metadata, then rebuild the update list from the active repo.
 system("/usr/bin/sudo /usr/bin/zypper --quiet --gpg-auto-import-keys refresh >/dev/null 2>&1");
 write_update_list();
 $result="success";
 $msg=$TEXT{'firmware_refreshed'};
 return;
}



1;
