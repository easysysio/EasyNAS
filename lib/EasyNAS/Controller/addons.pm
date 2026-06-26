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

 ##### addonslist #####
 if ($action eq "addonslist") {
  my $group=$self->param('group');
  my %addons=addons_info();
  $self->stash(group => $group,
               addons => \%addons);
  $self->render(template => 'easynas/addons_list');
  return;
 }

 ##### menu #####
  
 my %addons=addons_info();
 my $package;
 my $lang=0;
 my $srv=0;
 my $app=0;
 my $fs=0;
 my $stg=0;
 my $mm=0;
 foreach $package (keys %addons) {
  if ($package =~ /easynas-lang/) 
  {
   $lang++;
  }
  if ($package =~ /easynas-srv/)
  {
   $srv++;
  }
  if ($package =~ /easynas-app/)
  {
   $app++;
  }
  if ($package =~ /easynas-stg/)
  {
   $stg++;
  }
  if ($package =~ /easynas-fs/)
  {
   $fs++;
  }
  if ($package =~ /easynas-mm/)
  {
   $mm++;
  }
 }
 $self->stash(result => $result,
               msg => $msg,
               fs => $fs,
               mm => $mm,
               srv => $srv,
               lang => $lang,
               stg => $stg,
	       app => $app );
 $self->render(template => 'easynas/addons');
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
