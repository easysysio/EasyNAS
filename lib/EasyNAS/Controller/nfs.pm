package EasyNAS::Controller::Nfs;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("nfs");
my $service = ($addon->{service});
my %TEXT=get_lang_text($addon->{'name'});

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action');
  my $mount_dir=get_mount_dir();
  my $rc;
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

##### nfson #####
 if (defined($action) && $action eq "nfson") {
  service_ctl('start','rpcbind.service');
  service_ctl('enable','rpcbind.service');
  service_ctl('start',$service);
  service_ctl('enable',$service);
  write_log($addon->{"name"},"INFO","NFS Service started");
 }

#### nfsoff #####
 if (defined($action) && $action eq "nfsoff") {
  service_ctl('stop',$service);
  service_ctl('disable',$service);
  service_ctl('stop','rpcbind.service');
  service_ctl('disable','rpcbind.service');
  write_log($addon->{"name"},"INFO","NFS Service stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "createmenu") {
  my %vol = vol_info();
  $self->stash(volumes => \%vol);
  $self->render(template => 'easynas/nfs_create');
  return;
 }

##### add share #####
 if (defined($action) && $action eq "add") {
  my $vol=$self->param("vol") // "";
  my $per=$self->param("per") // "";
  my $path="$mount_dir/$vol";
  if ($vol !~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9._-]+$} || $vol =~ /\.\./ || $per !~ /^(?:rw|ro)$/) {
   $result="fail";
   $msg=$TEXT{'nfs_bad_input'} || "Pick a volume from the list.";
  }
  elsif ((root_read($addon->{config}) // "") =~ /^\Q$path\E\s/m) {
   $result="fail";
   $msg=$TEXT{'nfs_exists'};
  }
  # Ownership belongs to the volume (set in Volume settings); NFS has no
  # per-share identity mapping, so the export just serves the directory
  # with whatever owner/group/permissions the volume carries.
  elsif (!root_append($addon->{config},"$path *($per,sync,no_subtree_check)\n")) {
   $result="fail";
   $msg=$TEXT{'nfs_failed'} || "The share could not be saved.";
  }
  else {
   write_share_marker($path,"nfs","$path *($per,sync,no_subtree_check)");
   root_do('nfs','reexport');
   if (get_service_status($service)) {
    $rc=service_ctl('restart',$service) ? 0 : 1;
   }
   write_log($addon->{"name"},"INFO","NFS share was added");
  }
 }

##### delete share #####
 if (defined($action) && $action eq "delete") {
  my $vol=$self->param("vol") // "";
  my $fs=$self->param("fs") // "";
  my $path="$mount_dir/$fs/$vol";
  my $conf=($fs =~ /^[A-Za-z0-9_-]+$/ && $vol =~ /^[A-Za-z0-9._-]+$/ && $vol !~ /^\.\.?$/)
           ? root_read($addon->{config}) : undef;
  if (!defined $conf
      || !root_write($addon->{config}, join('', grep { !/^\Q$path\E\s/ } split /^/, $conf))) {
   $result="fail";
   $msg=$TEXT{'nfs_failed'} || "The share could not be saved.";
  }
  else {
   remove_share_marker($path,"nfs");
   root_do('nfs','reexport');   # -ra: the deleted share is withdrawn too
   if (get_service_status($service)) {
    service_ctl('reload',$service);
   }
   write_log($addon->{"name"},"INFO","NFS share was deleted");
  }
 }

##### menu ######
  my $service_active=get_service_status($service);
  my @shares;
  my $path;
  my $fs;
  my $vol;
  my @nfs=grep { /^\Q$mount_dir\E\// } root_lines($addon->{config});
  foreach (@nfs)
  {
   ($path,undef)=split(" ",$_);
   (undef,undef,$fs,$vol)=split("/",$path);
   my $owner=`/usr/bin/stat -c '%U:%G' "$path" 2>/dev/null`;
   chomp $owner;
   push(@shares,{path=>$path,fs=>$fs,vol=>$vol,owner=>$owner});
  }
  $self->stash(service_active => $service_active,
	       shares => \@shares,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/nfs');

}


1;
