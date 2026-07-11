package EasyNAS::Controller::Iscsi;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("iscsi");
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

##### iscsion #####
 if (defined($action) && $action eq "iscsion") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  write_log($addon->{"name"},"INFO","iSCSI target started");
 }

#### iscsioff #####
 if (defined($action) && $action eq "iscsioff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  write_log($addon->{"name"},"INFO","iSCSI target stopped");
 }

##### create menu #####
 if (defined($action) && $action eq "create") {
  my %vol = vol_info();
  $self->stash(volumes => \%vol);
  $self->render(template => 'easynas/iscsi_create');
  return;
 }

##### add target (backing file + LUN) #####
 if (defined($action) && $action eq "add") {
  my $target=$self->param("target");
  my $name=$self->param("name");
  my $vol=$self->param("vol");
  my $size=$self->param("size");
  my $size_type=$self->param("size_type") // "M";
  my $acl=$self->param("acl") // "";
  # All of these reach dd/tgt shell commands.
  if (!defined $target || $target !~ /^[A-Za-z0-9_.:-]{1,128}$/
      || !defined $name || $name !~ /^[A-Za-z0-9_.-]{1,64}$/
      || !defined $vol || $vol !~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$}
      || !defined $size || $size !~ /^\d{1,6}$/
      || $size_type !~ /^[MG]$/
      || ($acl ne "" && $acl !~ /^[0-9a-fA-F.:\/]{3,45}$/)) {
   $result="fail";
   $msg=$TEXT{'iscsi_bad_input'} || "Invalid target parameters.";
  }
  else {
   # Sparse backing file of the requested size on the chosen volume.
   my $err=`/usr/bin/sudo /usr/bin/dd if=/dev/zero of=$mount_dir/$vol/$name bs=1$size_type count=0 seek=$size 2>&1 >/dev/null`;
   if ($? != 0) {
    chomp $err;
    write_log($addon->{"name"},"ERROR","iscsi: dd backing file failed: $err");
    $result="fail";
    $msg=$TEXT{'iscsi_failed_create_disk'};
   }
   else {
    my $aclopt = ($acl ne "") ? $acl : "";
    $err=`/usr/bin/sudo /usr/sbin/tgt-setup-lun -n $target -d $mount_dir/$vol/$name $aclopt 2>&1 >/dev/null`;
    if ($? != 0) {
     chomp $err;
     write_log($addon->{"name"},"ERROR","iscsi: tgt-setup-lun failed: $err");
     $result="fail";
     $msg=$TEXT{'iscsi_failed_create_lun'};
    }
    else {
     `/usr/bin/sudo /usr/sbin/tgt-admin --dump | /usr/bin/sudo /usr/bin/tee $addon->{config} >/dev/null`;
     write_log($addon->{"name"},"INFO","iSCSI target $target created");
    }
   }
  }
 }

##### delete target #####
 if (defined($action) && $action eq "delete") {
  my $tid=$self->param("tid");
  if (defined $tid && $tid =~ /^\d{1,6}$/) {
   my $err=`/usr/bin/sudo /usr/sbin/tgt-admin --delete tid=$tid 2>&1 >/dev/null`;
   if ($? != 0) {
    chomp $err;
    write_log($addon->{"name"},"ERROR","iscsi: delete tid=$tid failed: $err");
    $result="fail";
    $msg=$TEXT{'iscsi_failed_delete'};
   }
   else {
    `/usr/bin/sudo /usr/sbin/tgt-admin --dump | /usr/bin/sudo /usr/bin/tee $addon->{config} >/dev/null`;
    write_log($addon->{"name"},"INFO","iSCSI target tid=$tid deleted");
   }
  }
 }

##### menu ######
  # Live targets from tgtadm: "Target <tid>: <iqn>" headers, then per-LUN
  # "Backing store path:" lines (skip LUN0's controller with path "None").
  my @targets;
  my ($tid,$name)=("","");
  foreach (`/usr/bin/sudo /usr/sbin/tgtadm --lld iscsi --op show --mode target 2>/dev/null`) {
   if    (/^Target (\d+):\s*(\S+)/)               { ($tid,$name)=($1,$2); }
   elsif (/Backing store path:\s*(\S+)/ && $1 ne "None" && $tid ne "") {
    push(@targets,{tid=>$tid,name=>$name,path=>$1});
   }
  }
  $self->stash(service_active => get_service_status($service),
	       targets => \@targets,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/iscsi');
}

1;
