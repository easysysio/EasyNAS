package EasyNAS::Controller::Users;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("users");
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

##### createuser #####
  if (defined $action && $action eq "createuser") {
   createuser($self);
  }

##### deleteuser #####
  if (defined $action && $action eq "deleteuser") {
   deleteuser($self);
  }

##### changepassword #####
  if (defined $action && $action eq "changepassword") {
   changepassword($self);
  }


#### changesettings #####
  if (defined $action && $action eq "changesettings") {
   changesettings($self);
  }

##### createusermenu #####
  if (defined $action && $action eq "createusermenu") {
   my %groups=groups_info();
   $self->stash(groups => \%groups);
   $self->render(template => 'easynas/users_create');
   return;
  }


##### passwordmenu #####
  if (defined $action && $action eq "passwordmenu") {
   my $user=$self->param("username");
   $self->stash(username => $user);
   $self->render(template => 'easynas/users_password');
   return;
  }


##### settingsmenu #####
  if (defined $action && $action eq "settingsmenu") {
   my $user=$self->param("username");
   my %groups=groups_info();
   my %users=users_info();
   $self->stash(username => $user,
   		groups => \%groups,
		users => \%users);
   $self->render(template => 'easynas/users_settings');
   return;
  }


##### menu ######

  my %users=users_info();
  $self->stash(users =>\%users);
  $self->stash(result => $result);
  $self->stash(msg => $msg);
  $self->render(template => 'easynas/users'); 

}


##### createuser ######
sub createuser($self) {
 my $name=$self->param("name");
 my $desc=$self->param("desc");
 my $password1=$self->param("password1");
 my $password2=$self->param("password2");
 my @groups=$self->param("groups");
 my $mount_dir=get_mount_dir;
 my $group_default=get_group_default;
 my $groups;
 my $rc;

 foreach(@groups)
    {
	$groups=$groups.$_.",";
    }
    chop($groups);

 if (!$name)
    {
     $result="fail";
     $msg=$TEXT{'users_user_must_exist'};
     return;
    }
 if (!$password1)
    {
     $result="fail";
     $msg=$TEXT{'users_password_must_exist'};
     return;
    }
 if ($password1 ne $password2) 
    {
     $result="fail";
     $msg=$TEXT{'users_passwords_do_no_match'};
     return;
    }


 # Local accounts: POSIX account + Samba (tdbsam) NT hash.
 $rc = system("/usr/bin/sudo /usr/sbin/useradd -g $group_default -G \"$groups\" -d $mount_dir -c \"$desc\" $name");
 if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_add_user'};
     return;
    }
 $rc = system("/usr/bin/echo $name:$password1 | /usr/bin/sudo /usr/sbin/chpasswd");
 if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_change_password'};
     return;
    }
 if( -f "/usr/bin/smbpasswd" )
    {
     $rc = system("/usr/bin/echo -e \"$password1\n$password1\" | /usr/bin/sudo /usr/bin/smbpasswd -s -a $name >/dev/null");
     if ($rc ne 0)
        {
         $result="fail";
         $msg=$TEXT{'users_failed_to_add_samba_user'};
         return;
        }
    }

    $result="success";
    $msg=$TEXT{'users_created'};
    return;
}



###### deleteuser #######
sub deleteuser($self) {
  my $username = $self->param("username");
  my $rc;

  if( -f "/usr/bin/smbpasswd" )
   {
    $rc = system("/usr/bin/sudo /usr/bin/smbpasswd -x $username >/dev/null");
    if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_delete_samba_user'};
     return;
    }
   }

    $rc = system("/usr/bin/sudo /usr/sbin/userdel -f $username");
    if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_delete_user'};
     return;
    }
    else
    {
     $result="success";
     $msg=$TEXT{'users_deleted'};
     return;
    }
}


##### changepassword #####
sub changepassword($self) {
 my $name=$self->param("username");
 my $password1=$self->param("password1");
 my $password2=$self->param("password2");
 my $rc;

 if (!$password1)
    {
     $result="fail";
     $msg=$TEXT{'users_password_must_exist'};
     return;
    }
 if ($password1 ne $password2)
    {
     $result="fail";
     $msg=$TEXT{'users_passwords_do_no_match'};
     return;
    }

 # The web administrator is NOT a system user: its credential is the hashed
 # line "admin:<$6$ crypt hash>" in /etc/easynas/admin.conf (see login.pm),
 # so chpasswd would fail with "user admin does not exist". Rewrite that file
 # instead. crypt() with a fresh $6$ salt produces the same SHA-512 format
 # login re-derives, and the password stays inside Perl -- never on a command
 # line or through a shell.
 if ($name eq "admin")
    {
     my @c=('.','/',0..9,'A'..'Z','a'..'z');
     my $salt='$6$'.join('',map { $c[int rand @c] } 1..16).'$';
     my $hash=crypt($password1,$salt);
     if (!defined $hash || $hash !~ /^\$6\$/)
        {
         $result="fail";
         $msg=$TEXT{'users_failed_to_change_password'};
         return;
        }
     # Pipe to `sudo tee` with list args (no shell): the $-laden hash can't be
     # reinterpreted. tee writes admin.conf as root; then lock it down.
     my $ok=open(my $t,"|-","/usr/bin/sudo","/usr/bin/tee","/etc/easynas/admin.conf");
     if (!$ok) { $result="fail"; $msg=$TEXT{'users_failed_to_change_password'}; return; }
     print $t "admin:$hash\n";
     close($t);
     if ($? != 0) { $result="fail"; $msg=$TEXT{'users_failed_to_change_password'}; return; }
     system("/usr/bin/sudo","/usr/bin/chown","easynas:easynas","/etc/easynas/admin.conf");
     system("/usr/bin/sudo","/bin/chmod","600","/etc/easynas/admin.conf");
     write_log("users","INFO","Web admin password changed");
     $result="success";
     $msg=$TEXT{'users_password_changed'};
     return;
    }

 # Feed "user:password" to chpasswd on stdin via list-form open (no shell),
 # so a password containing spaces, $, ` or ; can't break or inject.
 my $ok=open(my $cp,"|-","/usr/bin/sudo","/usr/sbin/chpasswd");
 if (!$ok) { $result="fail"; $msg=$TEXT{'users_failed_to_change_password'}; return; }
 print $cp "$name:$password1\n";
 close($cp);
 if ($? != 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_change_password'};
     return;
    }
 if( -f "/usr/bin/smbpasswd" )
    {
     my $sok=open(my $sp,"|-","/usr/bin/sudo","/usr/bin/smbpasswd","-s","-a",$name);
     if ($sok) { print $sp "$password1\n$password1\n"; close($sp); }
     if (!$sok || $? != 0)
        {
         $result="fail";
         $msg=$TEXT{'users_failed_to_add_samba_user'};
         return;
        }
    }

    $result="success";
    $msg=$TEXT{'users_password_changed'};
    return;
}


##### changesettings #####
sub changesettings($self) {
 my $name=$self->param("username");
 my $desc=$self->param("desc");
 my @groups=$self->param("groups");
 my $mount_dir=get_mount_dir;
 my $group_default=get_group_default;
 my $groups;
 my $rc;

 foreach(@groups)
    {
	$groups = $groups.$_.",";
    }
    chop($groups);

    $rc = system("/usr/bin/sudo /usr/sbin/usermod -g $group_default -G \"$groups\" -d $mount_dir -c \"$desc\" $name");
    if ($rc ne 0)
    {
     $result="fail";
     $msg=$TEXT{'users_settings_failed_to_save'};

    }
    else
    {
     $result="success";
     $msg=$TEXT{'users_settings_saved'};
    }
    return;
}

1;
