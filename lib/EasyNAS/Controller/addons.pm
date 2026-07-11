package EasyNAS::Controller::Addons;
use lib '.';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use XML::LibXML;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("addons");
my %TEXT=get_lang_text($addon->{'name'});

# Icon fallback for addons whose .easynas ships with the subpackage (so it's
# absent until installed). Lets the grid show the real icon before install.
# Keep in sync with the addons/*.easynas <icon> fields.
my %addon_icon = (
 afp     => "fa-brands fa-apple",   ftp    => "fa-file",
 nfs     => "fa-brands fa-linux",   rsyncd => "fa-refresh",
 samba   => "fa-brands fa-windows", ssh    => "fa-terminal",
 tftp    => "fa-file-code",         dlna   => "fa-file-video",
 plex    => "fa-film",              lxc    => "fa-desktop",
 mariadb => "fa-file-text",         radius => "fa-circle",
 iscsi   => "fa-external-link",
);


sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action'); 
  $msg="";
  $result="";
  $self->stash( addon => $addon,
                TEXT =>\%TEXT);

 ##### install addon #####
 if ($action eq "install_addon") {
  install_addon($self);
 }
 
 ##### delete addon #####
 if ($action eq "delete_addon") {
  delete_addon($self);
 }


#### update addon #####
 if ($action eq "update_addon") {
  update_addon($self);
 }

#### update all addons #####
 if ($action eq "update_all") {
  update_all($self);
 }

 ##### menu (QNAP-style grid: updates on top, then by category) #####
 my %addons=addons_info();               # package -> [name, group, desc, status, version]
 my %upd=addon_updates();                # package -> new version (from easynas.updates)
 my @updates;                            # addons with an available update
 my %by_cat;                             # category -> [addon tiles]
 # Flag image per installed language (keyed by lower-cased name), so language
 # addons render their country flag instead of a generic icon.
 my %lang_flag;
 foreach my $l (get_lang_list()) {
  $lang_flag{lc $l->{name}} = $l->{flag} if ($l->{flag});
 }
 foreach my $package (sort keys %addons) {
  my ($name,$group,$desc,$status,$ver)=@{$addons{$package}};
  my $installed=(defined $status && $status eq "up-to-date") ? 1 : 0;
  my $info=get_addon_info($name) || {};
  # Icons are stored WITHOUT the "fa" family prefix (as in the .easynas files,
  # e.g. "fa-refresh" or "fa-brands fa-windows"); the template prepends "fa ".
  # Installed -> the addon's own .easynas icon; not installed -> the fallback
  # map; language addons default to a flag icon; otherwise a generic icon.
  my $icon=($info->{icon} && $info->{icon} ne "") ? $info->{icon}
          : ($addon_icon{$name} // ($group eq "lang" ? "fa-flag" : "fa-puzzle-piece"));
  # A language addon shows its country flag image when we know it (installed).
  my $flag=($group eq "lang") ? ($lang_flag{lc $name} // "") : "";
  # Category = the package group code (fs/mm/srv/stg/lang); the template maps it
  # to a friendly label (File Sharing / Multimedia / Service / Storage).
  my $cat = $group;
  my $tile={ pkg=>$package, name=>$name, icon=>$icon, flag=>$flag, cat=>$cat,
             version=>$ver, desc=>$desc, installed=>$installed,
             program=>($info->{program}//""), newver=>($upd{$package}//"") };
  # Installed with an update -> Updates section; otherwise (installed-current or
  # not-installed) -> its category.
  if ($installed && $upd{$package}) { push @updates,$tile; }
  else                              { push @{$by_cat{$cat}},$tile; }
 }
 # The base easynas package itself gets its own "easynas" category tile: always
 # installed, updatable, but no install/remove (it's the core).
 my $ever=`/usr/bin/rpm -q --qf '%{VERSION}-%{RELEASE}' easynas 2>/dev/null`;
 chomp $ever;
 if ($ever ne "") {
  my $etile={ pkg=>"easynas", name=>"EasyNAS", icon=>"fa-server", flag=>"", cat=>"easynas",
              version=>$ever, desc=>"", installed=>1, core=>1,
              program=>"", newver=>($upd{"easynas"}//"") };
  if ($upd{"easynas"}) { push @updates,$etile; }
  else                 { push @{$by_cat{"easynas"}},$etile; }
 }
 $self->stash(result => $result,
              msg => $msg,
              updates => \@updates,
              by_cat => \%by_cat);
 $self->render(template => 'easynas/addons');
}

############## addon_updates ##############
# Which easynas packages have an update, from the list check_update.pl writes
# (zypper lu --xmlout). Returns package -> new edition.
sub addon_updates {
 my %u;
 my $file="/etc/easynas/easynas.updates";
 return %u unless (-e $file);
 my $dom;
 eval { $dom = XML::LibXML->load_xml(location => $file) };
 return %u if ($@ || !$dom);
 foreach my $up ($dom->findnodes('/stream/update-status/update-list/update')) {
  my $name=$up->findvalue('./@name');
  $u{$name}=$up->findvalue('./@edition');
 }
 return %u;
}

############## active_channel_repo ##############
# The enabled EasyNAS channel repo (stable "EasyNAS" or testing "EasyNAS_Beta").
sub active_channel_repo {
 my $repo="EasyNAS";
 foreach (`/usr/bin/sudo /usr/bin/zypper --quiet lr -E 2>/dev/null`) {
  if (/\bEasyNAS_Beta\b/) { $repo="EasyNAS_Beta"; last; }
 }
 return $repo;
}

############## refresh_update_list ##############
# Regenerate /etc/easynas/easynas.updates from the live rpmdb so the pending-
# update count (dashboard banner + sidebar badge) recomputes immediately after
# an addon action, instead of waiting for the 6-hourly check_update.pl.
sub refresh_update_list {
 my $repo=active_channel_repo();
 `/usr/bin/sudo /usr/bin/zypper --quiet --xmlout lu -a --repo $repo | /usr/bin/sudo /usr/bin/tee /etc/easynas/easynas.updates >/dev/null`;
}

############## run_bg_update ##############
# Update EasyNAS packages in a transient systemd unit (own cgroup): updating the
# base easynas restarts easynas.service, which would otherwise kill this process
# mid-transaction. $pkg empty => update the whole channel; else that one package.
#
# Addon/app updates are INSTANT and need NO reboot, so unlike the firmware track
# this never sets update.status="ready" (which the layout renders as a "reboot
# to apply" banner). On success it refreshes easynas.updates and clears
# update.status, so both the "update running" spinner and the "updates
# available" message disappear; on failure it leaves "failed" for the banner.
sub run_bg_update {
 my ($pkg)=@_;
 my $repo=active_channel_repo();
 my $target = ($pkg && $pkg ne "") ? $pkg : "--repo $repo";
 system("/bin/echo updating | /usr/bin/sudo /usr/bin/tee /etc/easynas/update.status >/dev/null");
 system("/usr/bin/sudo /usr/bin/systemd-run --collect --unit=easynas-update "
       ."/bin/sh -c '"
       ."/usr/bin/zypper -n --gpg-auto-import-keys update $target "
       .">/var/log/easynas/update.log 2>&1 "
       ."&& { /usr/bin/zypper --quiet --xmlout lu -a --repo $repo "
       ."| /usr/bin/tee /etc/easynas/easynas.updates >/dev/null; "
       ."/bin/rm -f /etc/easynas/update.status; } "
       ."|| echo failed | /usr/bin/tee /etc/easynas/update.status"
       ."' >/dev/null 2>&1");
}

############## update_all ##############
# Update every EasyNAS package from the active channel (detached; no reboot).
sub update_all($self) {
 run_bg_update("");
 $result="success";
 $msg=$TEXT{'addons_updating'} || "Updating add-ons in the background. The status banner shows progress.";
}

############# install addon ###############
# Installs run detached in a transient systemd unit, like updates: the page
# returns immediately and the global banner (update.status + update.log)
# shows live progress on every page. On success the unit refreshes the
# catalog/update files so the grid reflects the new state on reload.
sub install_addon($self) {
 my $package=$self->param("package");
 my $addons_update_dir=get_addons_update_dir();
 # The package name reaches a root shell command -- whitelist its shape.
 unless (defined $package && $package =~ /^easynas-[a-z0-9-]{1,64}$/) {
  $result="fail";
  $msg=$TEXT{'addons_not_installed'};
  return;
 }
 my $repo=active_channel_repo();
 system("/bin/echo updating | /usr/bin/sudo /usr/bin/tee /etc/easynas/update.status >/dev/null");
 system("/usr/bin/sudo /usr/bin/systemd-run --collect --unit=easynas-install "
       ."/bin/sh -c '"
       ."/usr/bin/zypper -n --gpg-auto-import-keys install $package "
       .">/var/log/easynas/update.log 2>&1 "
       ."&& { /usr/bin/zypper --xmlout info $package "
       ."| /usr/bin/tee $addons_update_dir/$package.addon >/dev/null; "
       ."/usr/bin/zypper --quiet --xmlout lu -a --repo $repo "
       ."| /usr/bin/tee /etc/easynas/easynas.updates >/dev/null; "
       ."/bin/rm -f /etc/easynas/update.status; } "
       ."|| echo failed | /usr/bin/tee /etc/easynas/update.status"
       ."' >/dev/null 2>&1");
 $result="success";
 $msg=$TEXT{'addons_installing_bg'} || "Installing in the background. The status banner shows progress.";
 return;
}


############# delete addon ###############
sub delete_addon($self) {
 my $package=$self->param("package");
 my $addons_update_dir=get_addons_update_dir();
 my @info;
 my $info1;
 my $info2;
 my $rc;
 my $deleted=0;
 $rc = `sudo /usr/bin/zypper -n remove $package`;
 @info=`sudo /usr/bin/zypper info $package`;
 foreach(@info)
  {
   ($info1,$info2) = split /:/,$_;
   if ($info1 =~ "Installed" && $info2 =~ "No")
   {
     $deleted=1
    }
   }
 if ($deleted)
 {
  `/usr/bin/sudo /usr/bin/zypper --xmlout info $package | /usr/bin/sudo /usr/bin/tee $addons_update_dir/$package.addon`;
  refresh_update_list();
  $result="success";
  $msg=$TEXT{'addons_deleted'};
 }
 else
 {
  $result="fail";
  $msg=$TEXT{'addons_not_deleted'};
 }
 return;

}


############## update_addon ##############
sub update_addon($self) {
 my $package=$self->param("package");
 my $addons_update_dir=get_addons_update_dir();
 my @info;
 my $info1;
 my $info2;
 my $rc;
 my $updated=0;
 # The base easynas package restarts easynas.service on update, which would
 # kill this request -- run it detached (like update_all). Regular addons
 # update in place, so keep them synchronous for immediate feedback.
 if ($package eq "easynas") {
  run_bg_update("easynas");
  $result="success";
  $msg=$TEXT{'addons_updating'} || "Updating in the background. The status banner shows progress.";
  return;
 }
 $rc = `sudo /usr/bin/zypper -n update $package`;
 @info=`sudo /usr/bin/zypper info $package`;
 foreach(@info)
  {
   ($info1,$info2) = split /:/,$_;
   if ($info1 =~ "Status" && $info2 =~ "up-to-date")
   {
     $updated=1
    }
   }
 if ($updated) {
  `/usr/bin/sudo /usr/bin/zypper --xmlout info $package | /usr/bin/sudo /usr/bin/tee $addons_update_dir/$package.addon`;
  refresh_update_list();   # clear this addon from the pending-update count
  $result="success";
  $msg=$TEXT{'addons_updated'};
 }
 else
 {
  $result="fail";
  $msg=$TEXT{'addons_not_updated'};
 }

return;
}


1;
