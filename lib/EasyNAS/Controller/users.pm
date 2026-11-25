package EasyNAS::Controller::Users;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


# The outcome of the last action, also read by the setup wizard (wizard.pm),
# which runs the same create functions.
our $msg;
our $result;
our $ADMIN_CONF_DIR = "/etc/easynas";   # tests point it elsewhere
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
 return 1 if getgrnam(get_admin_group());
 my ($ok)=root_do('group','add-admins');
 return $ok;
}

# The description is the passwd comment field: no ":", line breaks or other
# control characters, and not too long.
sub clean_desc { my ($d)=@_; $d //= ""; $d =~ s/[:\x00-\x1f\x7f]//g; return substr($d,0,128); }

# The account's password and Samba's, through the root helper: on stdin,
# never on a command line or through a shell. '' when done, else the key of
# the error message.
sub set_passwords {
 my ($name,$password)=@_;
 return 'users_failed_to_change_password' if !defined $password || $password =~ /[\x00\r\n]/;
 my ($ok,$st)=root_feed("$password\n",'user','password',$name);
 return '' if $ok;
 return $st == 3 ? 'users_failed_to_add_samba_user' : 'users_failed_to_change_password';
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
 # easynas makes its files in /etc/easynas (conf-perms.sh): write a 0600 temp file next to
 # admin.conf and rename it over, so a failed write never leaves it half-done.
 my $conf="$ADMIN_CONF_DIR/admin.conf";
 my $tmp="$conf.new.$$";
 my $old=umask(077);
 my $ok=open(my $t,'>',$tmp);
 umask($old);
 return 'users_failed_to_change_password' unless $ok;
 $ok=(print $t "admin:$hash\n");
 $ok=close($t) && $ok;
 $ok=$ok && chmod(0600,$tmp) && rename($tmp,$conf);
 unless ($ok) { unlink $tmp; return 'users_failed_to_change_password'; }
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
 my ($ok,$out)=root_do('user','add',$name,$desc,group_list($self));
 if (!$ok)
    {
     write_log("users","ERROR","user $name not created: $out");
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

    # The helper takes it out of Samba too.
    my ($ok,$out)=root_do('user','delete',$username);
    if (!$ok)
    {
     write_log("users","ERROR","user $username not deleted: $out");
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
 my ($ok,$out)=root_do('user','set',$name,$desc,group_list($self));
 if (!$ok)
    {
     write_log("users","ERROR","user $name not changed: $out");
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
