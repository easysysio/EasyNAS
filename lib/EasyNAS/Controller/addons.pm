package EasyNAS::Controller::Addons;
use lib '.';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use XML::LibXML;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("addons");
my %TEXT=get_lang_text($addon->{'name'});


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
 foreach my $package (sort keys %addons) {
  my ($name,$group,$desc,$status,$ver)=@{$addons{$package}};
  my $installed=(defined $status && $status eq "up-to-date") ? 1 : 0;
  my $info=get_addon_info($name) || {};
  my $icon=($info->{icon} && $info->{icon} ne "") ? $info->{icon} : "fa fa-puzzle-piece";
  # Category = the package group code (fs/mm/srv/stg/lang); the template maps it
  # to a friendly label (File Sharing / Multimedia / Service / Storage).
  my $cat = $group;
  my $tile={ pkg=>$package, name=>$name, icon=>$icon, cat=>$cat,
             version=>$ver, desc=>$desc, installed=>$installed,
             program=>($info->{program}//""), newver=>($upd{$package}//"") };
  # Installed with an update -> Updates section; otherwise (installed-current or
  # not-installed) -> its category.
  if ($installed && $upd{$package}) { push @updates,$tile; }
  else                              { push @{$by_cat{$cat}},$tile; }
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

############## update_all ##############
# Update every EasyNAS package from the active channel. Runs in a transient
# systemd unit (own cgroup): updating the base easynas restarts easynas.service,
# which would otherwise kill this process mid-transaction. Progress shows via
# the global update banner (update.status).
sub update_all($self) {
 my $repo="EasyNAS";
 foreach (`/usr/bin/sudo /usr/bin/zypper --quiet lr -E 2>/dev/null`) {
  if (/\bEasyNAS_Beta\b/) { $repo="EasyNAS_Beta"; last; }
 }
 system("/bin/echo updating | /usr/bin/sudo /usr/bin/tee /etc/easynas/update.status >/dev/null");
 system("/usr/bin/sudo /usr/bin/systemd-run --collect --unit=easynas-update "
       ."/bin/sh -c '"
       ."/usr/bin/zypper -n --gpg-auto-import-keys update --repo $repo "
       .">/var/log/easynas/update.log 2>&1 "
       ."&& echo ready | /usr/bin/tee /etc/easynas/update.status "
       ."|| echo failed | /usr/bin/tee /etc/easynas/update.status"
       ."' >/dev/null 2>&1");
 $result="success";
 $msg=$TEXT{'addons_updating'} || "Updating add-ons in the background. The status banner shows progress.";
}

############# install addon ###############
sub install_addon($self) {
 my $package=$self->param("package");
 my $addons_update_dir=get_addons_update_dir();
 my @info;
 my $info1;
 my $info2;
 my $rc; 
 my $installed=0;
 $rc = `sudo /usr/bin/zypper -n install $package`;
 @info=`sudo /usr/bin/zypper info $package`;
 foreach(@info)
 {
   ($info1,$info2) = split /:/,$_;
   if ($info1 =~ "Installed" && $info2 =~ "Yes")
   {
    $installed=1
   }
 }
 if ($installed)
 {
  $result="success";
  $msg=$TEXT{'addons_installed'};
  `/usr/bin/sudo /usr/bin/zypper --xmlout info $package | /usr/bin/sudo /usr/bin/tee $addons_update_dir/$package.addon`;
 }
 else
 {
  $result="fail";
  $msg=$TEXT{'addons_not_installed'};
 }
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
