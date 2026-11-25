package EasyNAS::Controller::Volume;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


# The outcome of the last action, also read by the setup wizard (wizard.pm),
# which runs the same create functions.
our $msg;
our $result;
my $addon = get_addon_info("volume");
my %TEXT=get_lang_text($addon->{'name'});
my $mount_dir=get_mount_dir();
my $conf_cron=get_conf_cron();

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action'); 
  $msg="";
  $result="";
  

  $self->stash(addon => $addon,
               TEXT =>\%TEXT);

##### createvol #######	     
 if (defined $action && $action eq "createvol")
 {
   createvol($self);
 }

##### savevol #####
 if (defined $action && $action eq "savevol")
 {
   savevol($self);
 }

####### deletevol ######
 if (defined $action && $action eq "deletevol") 
 {
  deletevol($self);
 }

####### createsnapshot ######
 if (defined $action && $action eq "createsnapshot")
 {
  createsnapshot($self);
 }

 

 ###### createvolmenu #######
 if (defined $action && $action eq "createvolmenu") 
 {
   my %users=users_info();
   my %groups=groups_info();
   my %fs=fs_info();
   
   if (keys %fs) {
    $self->stash(users => \%users,
	        groups => \%groups,
		filesystems => \%fs);
    $self->render(template => 'easynas/volume_create');
    return;
   }
   else {
    $result="fail";
    $msg=$TEXT{'vol_no_fs'};
   }
 }


 ###### createsnapshotmenu #######
 if (defined $action && $action eq "createsnapshotmenu")
 { 
   my %users=users_info();
   my %groups=groups_info();
   my $vol=$self->param("vol");
   my $fs=$self->param("fs");
   $self->stash(users => \%users,
                groups => \%groups,
		vol => $vol,
                fs => $fs);
   $self->render(template => 'easynas/volume_create_snapshot');
   return;
 }

##### settings #####
 if (defined $action && $action eq "settingsmenu")
 {
  my %users=users_info();
  my %groups=groups_info();
  my $vol=$self->param("vol");
  my $fs=$self->param("fs");
  my $location;
  my $dir;
  my $userp;
  my $groupp;
  my $otherp;
  my $uowner;
  my $gowner;
  my $userid;
  my $groupid;
  my $dirname = "$mount_dir/$fs/$vol";
  my $perm    = sprintf '%04o', (stat($dirname))[2] & 07777;

  ### get current permmision ###
    if (substr($perm, 1, 1) eq 7 || substr($perm, 1, 1) eq 6 )
    {
	$userp = "read&write";
    }
    if (substr($perm, 1, 1) eq 5 || substr($perm, 1, 1) eq 4 )
    {
	$userp = "read";
    }
    if (substr($perm, 1, 1) eq 0 )
    {
	$userp = "deny";
    }
    if (substr($perm, 2, 1) eq 7 || substr($perm, 2, 1) eq 6 )
    {
	$groupp = "read&write";
    }
    if (substr($perm, 2, 1) eq 5 || substr($perm, 2, 1) eq 4  )
    {
	$groupp = "read";
    }
    if (substr($perm, 2, 1) eq 0 )
    {
	$groupp = "deny";
    }
    if (substr($perm, 3, 1) eq 7 || substr($perm, 3, 1) eq 6)
    {
	$otherp = "read&write";
    }
    if (substr($perm, 3, 1) eq 5 || substr($perm, 3, 1) eq 4 )
    {
	$otherp = "read";
    }
    if (substr($perm, 3, 1) eq 0 )
    {
	$otherp = "deny";
    }

    ### get current owner ###
    $userid  = (stat($dirname))[4];
    $groupid = (stat($dirname))[5];
    $uowner  = (getpwuid $userid)[0];
    $gowner  = (getgrgid $groupid)[0];


  $self->stash(vol =>$vol,
  	       fs =>$fs,
       	       users => \%users,
               groups => \%groups,
       	       uowner => $uowner,
	       gowner => $gowner,
       	       userp => $userp,
	       groupp => $groupp,
	       otherp => $otherp);
  $self->render(template => 'easynas/volume_settings');
  return;
 
 }

##### menu #######
  my %volumes=vol_info();
  $self->stash(volumes =>\%volumes);
  $self->stash(result => $result);
  $self->stash(msg => $msg);	
  $self->render(template => 'easynas/volume');
}

########### createvol ###############
sub createvol($self) {
 my $vol=$self->param("name");
 my $fs=$self->param("fs");
 my $user=$self->param("user");
 my $group=$self->param("group");
 my $user_perm=$self->param("user_perm") // "";
 my $group_perm=$self->param("group_perm") // "";
 my $others_perm=$self->param("others_perm") // "";
 my $rc;
 my $permission=0;
 if (!defined $vol || $vol eq '')
 { 
   $result="fail";
   $msg=$TEXT{'vol_no_vol_name'};
   return;
 }

 if (!defined $fs || $fs eq '') 
 {
  $result="fail";
  $msg=$TEXT{'vol_no_fs_selected'};
  return;
 }
 # The names become a path for root commands: keep them to safe shapes, and
 # the owner to accounts that exist.
 if ($vol !~ /^[A-Za-z0-9_][A-Za-z0-9._-]{0,63}$/ || $fs !~ /^[A-Za-z0-9_-]{1,64}$/)
 {
  $result="fail";
  $msg=$TEXT{'vol_bad_name'} || "A volume name has letters, digits, '.', '_' and '-', and starts with a letter, digit or '_'.";
  return;
 }
 $user  = "root" if (!defined $user  || $user  eq "");
 $group = "root" if (!defined $group || $group eq "");
 if (!getpwnam($user) || !getgrnam($group))
 {
  $result="fail";
  $msg=$TEXT{'vol_bad_owner'} || "The owner must be an existing user and group.";
  return;
 }
 if ($user_perm eq "read")
 {
  $permission = $permission+500;
 }
 if ($user_perm eq "read&write")
 {
  $permission = $permission+700;
 }
 if ($group_perm eq "read")
 {
  $permission = $permission+50;
 }
 if ($group_perm eq "read&write")
 {
  $permission = $permission+70;
 }
 if ($others_perm eq "read")
 {
  $permission = $permission+5;
 }
 if ($others_perm eq "read&write")
 {
  $permission = $permission+7;
 } 

 my ($ok,$out)=root_do('vol','create',$fs,$vol);
 if(!$ok)
 {
   write_log("volume","ERROR","volume $fs/$vol not created: $out");
   $result="fail";
   $msg=$TEXT{'vol_not_created'} || "The volume was not created. Is the filesystem mounted, and is the name free?";
 }
 else 
 {
   ($ok,$out)=root_do('vol','owner',$fs,$vol,$user,$group,sprintf("%03d",$permission));
   write_log("volume","ERROR","volume $fs/$vol: owner not set: $out") unless $ok;
   write_log("volume","INFO","volume $fs/$vol created");
   $result="success";
   $msg=$TEXT{'vol_created'};

 }
 return;
}

########### savevol #############
sub savevol($self) {
 my $vol=$self->param("vol");
 my $fs=$self->param("fs");
 my $user=$self->param("user");
 my $group=$self->param("group");
 my $user_perm=$self->param("user_perm") // "";
 my $group_perm=$self->param("group_perm") // "";
 my $others_perm=$self->param("others_perm") // "";
 my $rc;
 my $permission=0;
 if ($user_perm eq "read")
 {
  $permission = $permission+500;
 }
 if ($user_perm eq "read&write")
 {
  $permission = $permission+700;
 }
 if ($group_perm eq "read")
 {
  $permission = $permission+50;
 }
 if ($group_perm eq "read&write")
 {
  $permission = $permission+70;
 }
 if ($others_perm eq "read")
 {
  $permission = $permission+5;
 }
 if ($others_perm eq "read&write")
 {
  $permission = $permission+7;
 }
 $user  = "root" if (!defined $user  || $user  eq "");
 $group = "root" if (!defined $group || $group eq "");
 my ($ok,$out)=root_do('vol','owner',$fs,$vol,$user,$group,sprintf("%03d",$permission));
 if (!$ok) {
  write_log("volume","ERROR","volume $fs/$vol: owner not set: $out");
  $result="fail";
  $msg=$TEXT{'vol_not_saved'} || "The volume's owner and permissions were not changed.";
  return;
 }
 $result="success";
 $msg=$TEXT{'vol_saved'};
 return;
}

########### createsnapshot ###############
sub createsnapshot($self) {
 my $vol=$self->param("vol");
 my $fs=$self->param("fs");
 my $snapshot=$self->param("name");
 my $user=$self->param("user");
 my $group=$self->param("group");
 my $user_perm=$self->param("user_perm") // "";
 my $group_perm=$self->param("group_perm") // "";
 my $others_perm=$self->param("others_perm") // "";
 my $rc;
 my $permission=0;
 if ($snapshot eq '')
 {
   $result="fail";
   $msg=$TEXT{'vol_no_snapshot_name'};
   return;
 }

 if ($user_perm eq "read")
 {
  $permission = $permission+500;
 }
 if ($user_perm eq "read&write")
 {
  $permission = $permission+700;
 }
 if ($group_perm eq "read")
 {
  $permission = $permission+50;
 }
 if ($group_perm eq "read&write")
 {
  $permission = $permission+70;
 }
 if ($others_perm eq "read")
 {
  $permission = $permission+5;
 }
 if ($others_perm eq "read&write")
 {
  $permission = $permission+7;
 }
 
 $user  = "root" if (!defined $user  || $user  eq "");
 $group = "root" if (!defined $group || $group eq "");
 my ($ok,$out)=root_do('vol','snapshot',$fs,$vol,$snapshot);
 if(!$ok)
 {
   write_log("volume","ERROR","snapshot $fs/$snapshot of $vol not made: $out");
   $result="fail";
   $msg=$TEXT{'vol_failed_to_add_snapshot'};
 }
 else
 {
   ($ok,$out)=root_do('vol','owner',$fs,$snapshot,$user,$group,sprintf("%03d",$permission));
   write_log("volume","ERROR","snapshot $fs/$snapshot: owner not set: $out") unless $ok;
   $result="success";
   $msg=$TEXT{'vol_snapshot_created'};
 }
 return;
}


##### deletevol #####
sub deletevol($self) {
 my $vol=$self->param("vol");
 my $fs=$self->param("fs");
 my ($ok,$out)=root_do('vol','delete',$fs,$vol);
 if (!$ok)
 {
  write_log("volume","ERROR","volume $fs/$vol not deleted: $out");
  $result="fail";
  $msg=$TEXT{'vol_faild_to_delete'};
 }
 else 
 {
  # Its jobs in easynas.cron (snapshots, ...) go with it.
  my $cron=root_read($conf_cron);
  my $kept=join('', grep { !/ \Q$mount_dir\/$fs\/$vol\E / } split /^/, $cron // "");
  if (defined $cron && $kept ne $cron && root_write($conf_cron,$kept))
  {
    service_ctl('restart','cron.service');
  }
  $result="success";
  $msg=$TEXT{'vol_deleted'};
 }
 return;
}

1;
