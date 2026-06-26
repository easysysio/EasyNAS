package EasyNAS::Controller::Disk;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("disk");
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

  ##### format #####
  if (defined $action && $action eq "format") {
   disk_format($self);
  }

###### clean_errs #####
  if (defined $action && $action eq "clean_errs") {
   clean_errs($self);
  }

 ###### healthmenu #####
 if (defined $action && $action eq "healthmenu") {
  my $disk=$self->param('disk');
  my %health=health_info();
  $self->stash(disk => $disk,
	       health => \%health,
               result => $result,
               msg => $msg);
  $self->render(template => 'easynas/disk_health');
  return;
 }

  ##### menu ######

  my %disks=disk_info();
  my %health=health_info();
  $self->stash(disks =>\%disks,
   	       health =>\%health,
               result => $result,
      	       msg => $msg );
  $self->render(template => 'easynas/disk'); 
}

###### format #######
sub disk_format($self) {

 my $disk = $self->param("disk");
 my $rc = system("/usr/bin/sudo /usr/sbin/wipefs -t brtfs -f -o 0x10040  $disk >/dev/null");
 
 if ($rc) {
  $result="fail";
  $msg=$TEXT{'disk_format_failed'};
 }
 else {
  $result="success";
  $msg=$TEXT{'disk_format_success'}; 
 }
 return;
}


####### clean_errs ######
sub clean_errs($self)
{
  my $disk=$self->param("disk");
  my $rc=system("/usr/bin/sudo /usr/sbin/btrfs device stat -z $disk");

  if ($rc) {
   $result="fail";
   $msg=$TEXT{'disk_clean_errs_failed'};
  }
  else {
   $result="success";
   $msg=$TEXT{'disk_clean_errs_success'};
  }

  return;
}


1;
