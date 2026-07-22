package EasyNAS::Controller::Mariadb;
use lib '/easynas/lib/EasyNAS/Controller';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("mariadb");
my $service = ($addon->{service});
my %TEXT=get_lang_text($addon->{'name'});

# System schemas the UI never lists or lets you drop.
my %system_db = map { $_ => 1 } qw(mysql information_schema performance_schema sys);

sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action');
  $msg="";
  $result="";
  $self->stash(addon => $addon,
                TEXT =>\%TEXT);

##### mariadbon #####
 if (defined($action) && $action eq "mariadbon") {
  `/usr/bin/sudo /usr/bin/systemctl start $service`;
  `/usr/bin/sudo /usr/bin/systemctl enable $service`;
  write_log($addon->{"name"},"INFO","MariaDB Service started");
 }

#### mariadboff #####
 if (defined($action) && $action eq "mariadboff") {
  `/usr/bin/sudo /usr/bin/systemctl stop $service`;
  `/usr/bin/sudo /usr/bin/systemctl disable $service`;
  write_log($addon->{"name"},"INFO","MariaDB Service stopped");
 }

##### create database #####
 if (defined($action) && $action eq "createdb") {
  createdb($self);
 }

##### delete database #####
 if (defined($action) && $action eq "deletedb") {
  deletedb($self);
 }

##### set root password #####
 if (defined($action) && $action eq "setrootpw") {
  setrootpw($self);
 }

##### set storage location #####
 if (defined($action) && $action eq "setstorage") {
  setstorage($self);
 }

##### menu ######
  my $mount_dir = get_mount_dir();
  my $active = get_service_status($service);
  # Server version straight from the client; empty when unavailable so the
  # template can hide the line.
  my $dbver=`/usr/bin/mysql --version 2>/dev/null`;
  chomp $dbver;
  $dbver = ($dbver =~ /\b([0-9]+\.[0-9]+\.[0-9]+)-MariaDB/i || $dbver =~ /Distrib ([0-9.]+)/i) ? $1 : "";
  # User databases (system schemas filtered out); only queryable when running.
  my @databases;
  if ($active) {
   foreach (`/usr/bin/sudo /usr/bin/mysql -N -B -e "SHOW DATABASES" 2>/dev/null`) {
    chomp;
    push @databases, $_ unless ($_ eq "" || $system_db{$_});
   }
  }
  # Current storage: our fstab bind line names <mount>/<fs>/<subvol>/mariadb ->
  # /var/lib/mysql. Empty $storage_vol means internal (on-root) storage.
  my $storage_vol="";
  foreach (`/bin/cat /etc/fstab 2>/dev/null`) {
   if (m{^(\S+)/mariadb\s+/var/lib/mysql\s.*easynas-mariadb-storage}) {
    my $p=$1; $p =~ s{^\Q$mount_dir\E/}{}; $storage_vol=$p; last;
   }
  }
  my %vol = vol_info();
  $self->stash(service_active => $active,
	       dbver => $dbver,
	       databases => \@databases,
	       volumes => \%vol,
	       storage_vol => $storage_vol,
	       result => $result,
	       msg => $msg);
  $self->render(template => 'easynas/mariadb');
}


##### setstorage #####
# Point MariaDB's data at an EasyNAS volume (survives firmware updates) or back
# to internal storage. The heavy lifting -- stop, migrate, bind-mount, persist,
# start -- is in startup/mariadb-storage.sh; here we just validate and dispatch.
sub setstorage($self) {
 my $sel=$self->param("radio_sel") // "";
 my $vol=$self->param("vol") // "";
 my $mount_dir=get_mount_dir();
 my $target;
 if ($sel eq "internal") {
  $target="internal";
 }
 elsif ($sel eq "vol" && $vol =~ m{^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$}) {
  $target="$mount_dir/$vol";
 }
 else {
  $result="fail"; $msg=$TEXT{'mariadb_bad_vol'}; return;
 }
 # LIST form: target is validated (literal "internal" or a whitelisted volume
 # path), so no shell parsing of user data.
 my $rc=system("/usr/bin/sudo","/easynas/startup/mariadb-storage.sh",$target);
 if ($rc==0) {
  write_log($addon->{"name"},"INFO","MariaDB storage set to $target");
  $result="success"; $msg=$TEXT{'mariadb_storage_saved'};
 } else {
  $result="fail"; $msg=$TEXT{'mariadb_storage_failed'};
 }
}


##### run_sql #####
# Feed one or more SQL statements to the local server as root over the unix
# socket (system-root -> root@localhost, no stored password needed). SQL is
# written to stdin via a list-form pipe -- never the command line -- so nothing
# sensitive lands in the process table or is re-parsed by a shell. Returns 1 on
# success (mysql exit 0), 0 otherwise.
sub run_sql {
 my ($sql)=@_;
 my $ok=open(my $mh,"|-","/usr/bin/sudo","/usr/bin/mysql");
 return 0 unless $ok;
 print $mh $sql;
 close($mh);
 return ($? == 0) ? 1 : 0;
}

##### sql_str #####
# Escape a value for a single-quoted SQL string literal (backslash first, then
# quote). Used only for the root password, which then travels on stdin.
sub sql_str {
 my ($s)=@_;
 $s =~ s/\\/\\\\/g;
 $s =~ s/'/\\'/g;
 return $s;
}


##### createdb #####
sub createdb($self) {
 my $name=$self->param("dbname");
 if (!get_service_status($service)) {
  $result="fail"; $msg=$TEXT{'mariadb_not_running'}; return;
 }
 # The name becomes a backtick-quoted identifier; whitelist so it can carry no
 # quoting or SQL of its own.
 if (!defined $name || $name !~ /^[A-Za-z0-9_]{1,64}$/) {
  $result="fail"; $msg=$TEXT{'mariadb_bad_dbname'}; return;
 }
 if ($system_db{$name}) {
  $result="fail"; $msg=$TEXT{'mariadb_bad_dbname'}; return;
 }
 if (run_sql("CREATE DATABASE IF NOT EXISTS `$name`;\n")) {
  write_log($addon->{"name"},"INFO","Database $name created");
  $result="success"; $msg=$TEXT{'mariadb_db_created'};
 } else {
  $result="fail"; $msg=$TEXT{'mariadb_db_failed'};
 }
}

##### deletedb #####
sub deletedb($self) {
 my $name=$self->param("dbname");
 if (!get_service_status($service)) {
  $result="fail"; $msg=$TEXT{'mariadb_not_running'}; return;
 }
 if (!defined $name || $name !~ /^[A-Za-z0-9_]{1,64}$/ || $system_db{$name}) {
  $result="fail"; $msg=$TEXT{'mariadb_bad_dbname'}; return;
 }
 if (run_sql("DROP DATABASE IF EXISTS `$name`;\n")) {
  write_log($addon->{"name"},"INFO","Database $name deleted");
  $result="success"; $msg=$TEXT{'mariadb_db_deleted'};
 } else {
  $result="fail"; $msg=$TEXT{'mariadb_db_failed'};
 }
}

##### setrootpw #####
# Set the MariaDB root@localhost password while KEEPING unix_socket auth, so the
# appliance's own `sudo mysql` management keeps working and the password is what
# TCP/native-password clients use. The password is SQL-escaped and reaches mysql
# only on stdin (via run_sql).
sub setrootpw($self) {
 my $p1=$self->param("password1");
 my $p2=$self->param("password2");
 if (!get_service_status($service)) {
  $result="fail"; $msg=$TEXT{'mariadb_not_running'}; return;
 }
 if (!defined $p1 || $p1 eq "") {
  $result="fail"; $msg=$TEXT{'mariadb_pw_empty'}; return;
 }
 if ($p1 ne $p2) {
  $result="fail"; $msg=$TEXT{'mariadb_pw_mismatch'}; return;
 }
 # Reject control characters / newlines (they can't be a real password and would
 # split the stdin statement); everything else is escaped by sql_str.
 if ($p1 =~ /[\x00-\x1f]/) {
  $result="fail"; $msg=$TEXT{'mariadb_pw_invalid'}; return;
 }
 my $esc=sql_str($p1);
 my $sql="ALTER USER 'root'\@'localhost' "
        ."IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$esc');\n"
        ."FLUSH PRIVILEGES;\n";
 if (run_sql($sql)) {
  write_log($addon->{"name"},"INFO","MariaDB root password changed");
  $result="success"; $msg=$TEXT{'mariadb_pw_changed'};
 } else {
  $result="fail"; $msg=$TEXT{'mariadb_pw_failed'};
 }
}

1;
