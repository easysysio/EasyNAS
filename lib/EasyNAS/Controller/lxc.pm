package EasyNAS::Controller::Lxc;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use lib '/easynas/lib/EasyNAS/Controller';
use easynas;

my $msg;
my $result;
my $addon = get_addon_info("lxc");
my %TEXT=get_lang_text($addon->{'name'});

my %systems;
my @systems;
my $name;
my $state;
my $ip;

###### Get Systems List #######
@systems=`/usr/bin/lxc-ls --fancy`;
foreach (@systems) {
 ($name,$state,undef,undef,$ip,undef)=split(" ",$_);
 if ($name ne "NAME") {
  $systems{$name}=[$name,$state,$ip];
 }
}

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action'); 
  $msg="";
  $result="";
  
  if (defined $action && $action eq "terminal" )
  {
    system("sudo /usr/bin/ttyd -p 8080 -o -W bash &");
    $self->redirect_to('http://192.168.64.39:8080/'); 
    return;
  }  

  $self->render(template => 'easynas/lxc', 
	        addon => $addon,
                TEXT =>\%TEXT,
		systems => \%systems,
                result => $result,
                msg => $msg
		);
}

1;
