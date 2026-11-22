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

# Every change is a POST: the session cookie is SameSite=Lax, so a page on
# another site can make a signed-in browser GET this page -- a link that, as a
# GET, could create an administrator -- but not POST to it.
  my $post = ($self->req->method eq "POST");

##### createuser #####
  if ($post && defined $action && $action eq "createuser") {
   createuser($self);
  }

##### deleteuser #####
  if ($post && defined $action && $action eq "deleteuser") {
   deleteuser($self);
  }

##### changepassword #####
  if ($post && defined $action && $action eq "changepassword") {
   changepassword($self);
  }

#### changesettings #####
  if ($post && defined $action && $action eq "changesettings") {
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


##### account checks ######
# Names as useradd and the sign-in page accept them.
sub good_name { my ($n)=@_; return (defined $n && $n =~ /^[A-Za-z_][A-Za-z0-9_.-]{0,31}$/) ? 1 : 0; }

# The supplementary groups to give an account: the ticked ones that exist,
# plus the admin group when "Administrator" is ticked. As one -G list.
sub group_list($self) {
 my %known=groups_info();
 my @groups=grep { exists $known{$_} } @{$self->every_param("groups")};
 push @groups, get_admin_group() if $self->param("admin");
 return join(",", @groups);
}

# The admin group is created the first time someone is made an administrator.
sub ensure_admin_group {
 my $g=get_admin_group();
 return 1 if getgrnam($g);
 return system("/usr/bin/sudo","/usr/sbin/groupadd","--system",$g) == 0 ? 1 : 0;
}

# The description is the passwd comment field: no ":" or line breaks.
sub clean_desc { my ($d)=@_; $d //= ""; $d =~ s/[:\r\n]//g; return $d; }

# Write "name:password" to chpasswd and the password twice to smbpasswd on
# stdin, never on a command line or through a shell.
sub set_passwords {
 my ($name,$password)=@_;
 open(my $cp,"|-","/usr/bin/sudo","/usr/sbin/chpasswd") or return 'users_failed_to_change_password';
 print $cp "$name:$password\n";
 close($cp);
 return 'users_failed_to_change_password' if $? != 0;
 if (-f "/usr/bin/smbpasswd") {
  open(my $sp,"|-","/usr/bin/sudo","/usr/bin/smbpasswd","-s","-a",$name) or return 'users_failed_to_add_samba_user';
  print $sp "$password\n$password\n";
  close($sp);
  return 'users_failed_to_add_samba_user' if $? != 0;
 }
 return '';
}

# The web administrator is NOT a system user: its credential is the hashed
# line "admin:<$6$ crypt hash>" in /etc/easynas/admin.conf (see login.pm), so
# chpasswd would fail with "user admin does not exist". Rewrite that file
# instead. crypt() with a fresh $6$ salt produces the same SHA-512 format login
# re-derives, and the password stays inside Perl -- never on a command line or
# through a shell. '' when done, else the key of the error message. (Also used
# by the profile page.)
sub set_admin_password {
 my ($password)=@_;
 my @c=('.','/',0..9,'A'..'Z','a'..'z');
 my $salt='$6$'.join('',map { $c[int rand @c] } 1..16).'$';
 my $hash=crypt($password,$salt);
 return 'users_failed_to_change_password' if !defined $hash || $hash !~ /^\$6\$/;
 # Pipe to `sudo tee` with list args (no shell): the $-laden hash can't be
 # reinterpreted. tee writes admin.conf as root; then lock it down.
 open(my $t,"|-","/usr/bin/sudo","/usr/bin/tee","/etc/easynas/admin.conf") or return 'users_failed_to_change_password';
 print $t "admin:$hash\n";
 close($t);
 return 'users_failed_to_change_password' if $? != 0;
 system("/usr/bin/sudo","/usr/bin/chown","easynas:easynas","/etc/easynas/admin.conf");
 system("/usr/bin/sudo","/bin/chmod","600","/etc/easynas/admin.conf");
 write_log("users","INFO","Web admin password changed");
 return '';
}

##### createuser ######
sub createuser($self) {
 my $name=$self->param("name");
 my $desc=clean_desc($self->param("desc"));
 my $password1=$self->param("password1");
 my $password2=$self->param("password2");
 my $admin=$self->param("admin") ? 1 : 0;

 if (!$name)
    {
     $result="fail";
     $msg=$TEXT{'users_user_must_exist'};
     return;
    }
 if (!good_name($name))
    {
     $result="fail";
     $msg=$TEXT{'users_bad_name'} || "A user name starts with a letter and has only letters, digits, '.', '_' and '-'.";
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
 if ($admin && !ensure_admin_group())
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_add_user'};
     return;
    }

 # Local accounts: POSIX account + Samba (tdbsam) NT hash.
 my @cmd=("/usr/bin/sudo","/usr/sbin/useradd","-g",get_group_default(),"-d",get_mount_dir(),"-c",$desc);
 my $groups=group_list($self);
 push @cmd, "-G", $groups if $groups ne "";
 if (system(@cmd, "--", $name) != 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_add_user'};
     return;
    }
 if (my $err=set_passwords($name,$password1))
    {
     $result="fail";
     $msg=$TEXT{$err};
     return;
    }
 write_log("users","INFO","user $name created".($admin ? " as an administrator" : ""));
 $result="success";
 $msg=$TEXT{'users_created'};
 return;
}



###### deleteuser #######
sub deleteuser($self) {
  my $username = $self->param("username");
  my %users=users_info();
  # Only the accounts this page lists (no system or service accounts).
  unless (defined $username && exists $users{$username})
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_delete_user'};
     return;
    }

  if( -f "/usr/bin/smbpasswd" )
   {
    if (system("/usr/bin/sudo","/usr/bin/smbpasswd","-x",$username) != 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_delete_samba_user'};
     return;
    }
   }

    if (system("/usr/bin/sudo","/usr/sbin/userdel","-f",$username) != 0)
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_delete_user'};
     return;
    }
    write_log("users","INFO","user $username deleted");
    $result="success";
    $msg=$TEXT{'users_deleted'};
    return;
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

 # The web administrator isn't a system user (see set_admin_password).
 if ($name eq "admin")
    {
     if (my $err=set_admin_password($password1))
        {
         $result="fail";
         $msg=$TEXT{$err};
         return;
        }
     $result="success";
     $msg=$TEXT{'users_password_changed'};
     return;
    }

 my %users=users_info();
 unless (defined $name && exists $users{$name})
    {
     $result="fail";
     $msg=$TEXT{'users_failed_to_change_password'};
     return;
    }
 if (my $err=set_passwords($name,$password1))
    {
     $result="fail";
     $msg=$TEXT{$err};
     return;
    }

    $result="success";
    $msg=$TEXT{'users_password_changed'};
    return;
}


##### changesettings #####
sub changesettings($self) {
 my $name=$self->param("username");
 my $desc=clean_desc($self->param("desc"));
 my $admin=$self->param("admin") ? 1 : 0;
 my %users=users_info();
 unless (defined $name && exists $users{$name})
    {
     $result="fail";
     $msg=$TEXT{'users_settings_failed_to_save'};
     return;
    }
 my $was_admin=is_nas_admin($name);
 if ($admin && !ensure_admin_group())
    {
     $result="fail";
     $msg=$TEXT{'users_settings_failed_to_save'};
     return;
    }

 # -G replaces the whole supplementary list (an empty one clears it), so the
 # admin group stays only while "Administrator" is ticked.
 if (system("/usr/bin/sudo","/usr/sbin/usermod","-g",get_group_default(),"-G",group_list($self),
            "-d",get_mount_dir(),"-c",$desc,"--",$name) != 0)
    {
     $result="fail";
     $msg=$TEXT{'users_settings_failed_to_save'};
     return;
    }
 write_log("users","INFO","user $name made an administrator") if $admin && !$was_admin;
 write_log("users","INFO","user $name is no longer an administrator") if !$admin && $was_admin;
 $result="success";
 $msg=$TEXT{'users_settings_saved'};
 return;
}

1;
