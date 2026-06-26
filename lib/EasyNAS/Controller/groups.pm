package EasyNAS::Controller::Groups;
use lib '.';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("groups");
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

 ##### creategroup #####
 if (defined $action && $action eq "creategroup") {
  creategroup($self);
 }

 ##### deletegroup #####
 if (defined $action && $action eq "deletegroup") {
  deletegroup($self);
 }


 ##### creategroupmenu #####
  if (defined $action && $action eq "creategroupmenu") {
   $self->render(template => 'easynas/groups_create');
   return;
  }
 

 ##### menu #####
 
  my %groups=groups_info();
  $self->stash(groups =>\%groups);
  $self->stash(result => $result);
  $self->stash(msg => $msg);
  $self->render(template => 'easynas/groups');
}


##### creategroup #####
sub creategroup($self) {
 my $group=$self->param("group");
 my $rc;
 $rc=system("/usr/bin/sudo","/usr/sbin/groupadd", $group);
 if ($rc)
  {
   $result="fail";
   $msg=$TEXT{'groups_failed_to_add'};
  }
  else 
  {
   $result="success";
   $msg=$TEXT{'groups_added'};
  }
  return;
}


sub deletegroup($self) { 
 my $group=$self->param("group");
 my $rc;
 $rc=system("/usr/bin/sudo","/usr/sbin/groupdel", $group);
 if ($rc)
  {
   $result="fail";
   $msg=$TEXT{'groups_failed_to_delete'};
  }
  else
  {
   $result="success";
   $msg=$TEXT{'groups_deleted'};
  }
  return;
}


1;
