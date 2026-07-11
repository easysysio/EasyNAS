package EasyNAS::Controller::Logs;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $addon = get_addon_info("logs");
my %TEXT=get_lang_text($addon->{'name'});

# Viewable logs, whitelisted: the file choice comes from the query string and
# reaches a root shell command.
my %LOGS = (
 easynas => "/var/log/easynas/easynas.log",
 update  => "/var/log/easynas/update.log",
 balance => "/var/log/easynas/balance.log",
);

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $file =$self->param('file')  // "easynas";
  my $lines=$self->param('lines') // 200;
  $file  = "easynas" unless (exists $LOGS{$file});
  $lines = 200 unless ($lines =~ /^\d{1,4}$/ && $lines > 0);

  # Newest entries first.
  my @entries = reverse `/usr/bin/sudo /usr/bin/tail -n $lines $LOGS{$file} 2>/dev/null`;
  chomp @entries;

  $self->stash(addon => $addon,
               TEXT => \%TEXT,
               result => "", msg => "",
               file => $file, lines => $lines,
               logs => [sort keys %LOGS],
               entries => \@entries);
  $self->render(template => 'easynas/logs');
}

1;
