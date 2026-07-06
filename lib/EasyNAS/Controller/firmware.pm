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
  }
  my $action=$self->param('action'); 
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

#### Update #####
 if (defined $action && $action eq "update") {
  update($self);
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
	       updates => \%updates);	
  $self->render(template => 'easynas/firmware'); 
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

##### update #####
sub update($self) {
 my $package=$self->param('package');
 # Only allow sane package names -- $package is fed to a shell command.
 if (!defined $package || $package !~ /^[A-Za-z0-9._+-]+$/) {
  $result="fail";
  $msg=$TEXT{'firmware_update_failed'};
  return;
 }
 my $rc = system("/usr/bin/sudo /usr/bin/zypper -n update $package > /dev/null");
 if ($rc) {
  $result="fail";
  $msg=$TEXT{'firmware_update_failed'};
 }
 else {
  $result="success";
  $msg=$TEXT{'firmware_update_success'};
  # New code is on disk but the running daemon still has the old modules
  # loaded. Restart the app so the update takes effect -- delayed and detached
  # so this HTTP response is delivered before the service bounces.
  if ($package =~ /^easynas/) {
   system("/bin/sh -c '/bin/sleep 2; /usr/bin/sudo /usr/bin/systemctl restart easynas.service' >/dev/null 2>&1 &");
  }
 }
 write_update_list();
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
