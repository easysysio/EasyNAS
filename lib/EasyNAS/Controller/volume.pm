package EasyNAS::Controller::Volume;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
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
 if (defined $action && $action eq "settings")
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
 my $user_perm=$self->param("user_perm");
 my $group_perm=$self->param("group_perm");
 my $others_perm=$self->param("others_perm");
 my $rc;
 my $permission=0;
 if ($vol eq '')
 { 
   $result="fail";
   $msg=$TEXT{'vol_no_vol_name'};
   return;
 }

 if ($fs eq '') 
 {
  $result="fail";
  $msg=$TEXT{'vol_no_fs_selected'};
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

 $rc = system("/usr/bin/sudo /sbin/btrfs subvolume create $mount_dir/$fs/$vol > /dev/null");
 if($rc ne 0)
 {
   $result="fail";
   $msg=$TEXT{'vol_created'};
 }
 else 
 {
   $rc = system("/usr/bin/sudo /usr/bin/chown $user:$group $mount_dir/$fs/$vol > /dev/null");
   $rc = system("/usr/bin/sudo /bin/chmod $permission $mount_dir/$fs/$vol > /dev/null");  
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
 my $user_perm=$self->param("user_perm");
 my $group_perm=$self->param("group_perm");
 my $others_perm=$self->param("others_perm");
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
 $rc = system("/usr/bin/sudo /usr/bin/chown $user:$group $mount_dir/$fs/$vol > /dev/null");
 $rc = system("/usr/bin/sudo /bin/chmod $permission $mount_dir/$fs/$vol > /dev/null");
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
 my $user_perm=$self->param("user_perm");
 my $group_perm=$self->param("group_perm");
 my $others_perm=$self->param("others_perm");
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
 
 $rc = system("/usr/bin/sudo /sbin/btrfs subvolume snapshot $mount_dir/$fs/$vol $mount_dir/$fs/$snapshot > /dev/null");
 if($rc ne 0)
 {
   $result="fail";
   $msg=$TEXT{'vol_failed_to_add_snapshot'};
 }
 else
 {
   $rc = system("/usr/bin/sudo /usr/bin/chown $user.$group $mount_dir/$fs/$snapshot > /dev/null");
   $rc = system("/usr/bin/sudo /bin/chmod $permission $mount_dir/$fs/$snapshot > /dev/null");
   $result="success";
   $msg=$TEXT{'vol_snapshot_created'};
 }
 return;
}


##### deletevol #####
sub deletevol($self) {
 my $vol=$self->param("vol");
 my $fs=$self->param("fs");
 my $cmount_dir;
 $cmount_dir = substr($mount_dir,1);
 my $rc = system("/usr/bin/sudo /sbin/btrfs subvolume delete $mount_dir/$fs/$vol > /dev/null");
 if ($rc ne 0)
 {
  $result="fail";
  $msg=$TEXT{'vol_faild_to_delete'};
 }
 else 
 {
  if (`/usr/bin/grep " $mount_dir/$fs/$vol " $conf_cron`)
  {   
    system("/usr/bin/sudo /usr/bin/sed -i '/.$cmount_dir.$fs.$vol /d' $conf_cron");
    system("/usr/bin/sudo /usr/bin/systemctl restart cron.service restart");
  }
  $result="success";
  $msg=$TEXT{'vol_deleted'};
 }
 return;
}

1;
