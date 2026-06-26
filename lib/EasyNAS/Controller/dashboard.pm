package EasyNAS::Controller::Dashboard;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use XML::LibXML;
use easynas;


sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $username=$self->session('user');
  my $action=$self->param('action'); 
  my $addon = get_addon_info("dashboard");
  my %addons = get_addons();
  my %TEXT=get_lang_text($addon->{'name'});
  my %fs = fs_info();
  my %disks  = disk_info();
  my %vol    = vol_info();
  my %users  = users_info();
  my $updates= get_update_file();
  my $missing_update;
  my $dom;
  
  if ($username eq "admin") {
   if (-e $updates) {
    eval {  $dom = XML::LibXML->load_xml(location => $updates) };
    if (! $@) {
     if ($dom->findnodes('/stream/update-status/update-list/update')) {
	$missing_update=1;
     }
     else {
	$missing_update=0;
     }	
    }
   }
  }
  
  $self->render(template => 'easynas/dashboard', 
		addon => $addon,
		TEXT =>\%TEXT,
		missing_update => $missing_update,
		addons =>\%addons,
		filesystems => \%fs,
		disks => \%disks,
		fs_number => scalar(keys %fs ),
		disk_number => scalar(keys %disks),
		vol_number => scalar(keys %vol),
		user_number => scalar(keys %users));
}

1;
