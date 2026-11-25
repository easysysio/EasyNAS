package EasyNAS::Controller::Addons;
use lib '.';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use XML::LibXML;
use easynas;


my $msg;
my $result;
my $addon = get_addon_info("addons");
my %TEXT=get_lang_text($addon->{'name'});

# Icon fallback for addons whose .easynas ships with the subpackage (so it's
# absent until installed). Lets the grid show the real icon before install.
# Keep in sync with the addons/*.easynas <icon> fields.
my %addon_icon = (
 ftp     => "fa-file",              files  => "fa-folder-open",
 nfs     => "fa-brands fa-linux",   rsyncd => "fa-refresh",
 samba   => "fa-brands fa-windows", ssh    => "fa-terminal",
 tftp    => "fa-file-code",         dlna   => "fa-file-video",
 lxc     => "fa-desktop",           mariadb => "fa-database",
 radius  => "fa-circle",            iscsi  => "fa-external-link",
);

# Flag per language add-on, keyed by its package name (easynas-lang-<name>).
# The images ship with the core package in public/images, so a language that
# isn't installed yet gets its flag too. Each lang/*/iso.txt names the same
# image, but under the language's display name ("Simplified Chinese"), which
# doesn't match the package name.
my %lang_flag = (
 german     => "flag_germany.png", polish  => "flag_poland.png",
 portuguese => "flag_brasil.png",  chinese => "flag_china.png",
);



sub view ($self) {
  if (!($self->session('is_auth'))) {
        $self->redirect_to('login');
  }
  my $action=$self->param('action') // "";

  # Progress for the update banner every page shows while the queue runs (see
  # layouts/default.html.ep): a percentage from zypper's step counters in
  # update.log -- "Retrieving package ... (n/m)" is the download half (0-50%),
  # "( n/m) Installing:" the install half (50-100%). The worker appends to the
  # log, so the last counters in it are the running op's.
  if ($action eq "progress") {
    my $state = get_update_state();
    my ($pct,$phase) = (0,"");
    if ($state eq "updating") {
      my $log = "";
      if (open(my $fh, '<', '/var/log/easynas/update.log')) { local $/; $log = <$fh> // ""; close $fh; }
      my ($r_n,$r_m,$i_n,$i_m);
      while ($log =~ /Retrieving(?: package)?:?\s+\S+\s+\(\s*(\d+)\/(\d+)\)/g) { ($r_n,$r_m)=($1,$2); }
      while ($log =~ /\(\s*(\d+)\/(\d+)\)\s+Installing:/g)                    { ($i_n,$i_m)=($1,$2); }
      if    (defined $i_n && $i_m) { $pct = 50 + int($i_n / $i_m * 50); $phase = "installing";  }
      elsif (defined $r_n && $r_m) { $pct = int($r_n / $r_m * 50);      $phase = "downloading"; }
      else                         { $pct = 3;                          $phase = "preparing";   }
      $pct = 99 if ($pct > 99);   # 100% only when the state flips off "updating"
    }
    $self->render(json => { state => $state, percent => $pct, phase => $phase });
    return;
  }

  $msg="";
  $result="";
  $self->stash( addon => $addon,
                TEXT =>\%TEXT);

 ##### install addon #####
 if ($action eq "install_addon") {
  install_addon($self);
 }
 
 ##### delete addon #####
 if ($action eq "delete_addon") {
  delete_addon($self);
 }


#### update addon #####
 if ($action eq "update_addon") {
  update_addon($self);
 }

#### update all addons #####
 if ($action eq "update_all") {
  update_all($self);
 }

#### check for updates (refresh button) #####
 if ($action eq "check_updates") {
  check_updates($self);
 }

 ##### menu (QNAP-style grid: updates on top, then by category) #####
 my %addons=addons_info();               # package -> [name, group, desc, status, version]
 my %upd=addon_updates();                # package -> new version (from easynas.updates)
 my @updates;                            # addons with an available update
 my %by_cat;                             # category -> [addon tiles]
 foreach my $package (sort keys %addons) {
  my ($name,$group,$desc,$status,$ver)=@{$addons{$package}};
  my $installed=(defined $status && $status eq "up-to-date") ? 1 : 0;
  my $info=get_addon_info($name) || {};
  # Icons are stored WITHOUT the "fa" family prefix (as in the .easynas files,
  # e.g. "fa-refresh" or "fa-brands fa-windows"); the template prepends "fa ".
  # Installed -> the addon's own .easynas icon; not installed -> the fallback
  # map; language addons default to a flag icon; otherwise a generic icon.
  my $icon=($info->{icon} && $info->{icon} ne "") ? $info->{icon}
          : ($addon_icon{$name} // ($group eq "lang" ? "fa-flag" : "fa-puzzle-piece"));
  # Description for the (i) modal: prefer the curated, translated about_*
  # text (main catalog -- present even when the addon isn't installed, and
  # the same text its own page shows) over the terse zypper summary.
  $desc=$TEXT{"about_$name"} if (defined $TEXT{"about_$name"} && $TEXT{"about_$name"} ne "");
  # A language addon shows its country flag (dimmed until installed).
  my $flag=($group eq "lang") ? ($lang_flag{$name} // "") : "";
  # Category = the package group code (fs/mm/srv/stg/lang); the template maps it
  # to a friendly label (File Sharing / Multimedia / Service / Storage).
  my $cat = $group;
  my $tile={ pkg=>$package, name=>$name, icon=>$icon, flag=>$flag, cat=>$cat,
             version=>$ver, desc=>$desc, installed=>$installed,
             program=>($info->{program}//""), newver=>($upd{$package}//"") };
  # Installed with an update -> Updates section; otherwise (installed-current or
  # not-installed) -> its category.
  if ($installed && $upd{$package}) { push @updates,$tile; }
  else                              { push @{$by_cat{$cat}},$tile; }
 }
 # The base easynas package itself gets its own "easynas" category tile: always
 # installed, updatable, but no install/remove (it's the core).
 my $ever=`/usr/bin/rpm -q --qf '%{VERSION}-%{RELEASE}' easynas 2>/dev/null`;
 chomp $ever;
 if ($ever ne "") {
  my $etile={ pkg=>"easynas", name=>"EasyNAS", icon=>"fa-server", flag=>"", cat=>"easynas",
              version=>$ever, desc=>($TEXT{'about_easynas'}//""), installed=>1, core=>1,
              program=>"", newver=>($upd{"easynas"}//"") };
  if ($upd{"easynas"}) { push @updates,$etile; }
  else                 { push @{$by_cat{"easynas"}},$etile; }
 }
 # Per-package queue state (installing/updating/waiting) for the tile badges;
 # the page auto-refreshes while anything is queued.
 my %qstate = queue_state();
 $self->stash(result => $result,
              msg => $msg,
              updates => \@updates,
              by_cat => \%by_cat,
              qstate => \%qstate,
              qactive => (scalar keys %qstate ? 1 : 0));
 $self->render(template => 'easynas/addons');
}

############## addon_updates ##############
# Which easynas packages have an update, from the list check_update.pl writes
# (zypper lu --xmlout). Returns package -> new edition.
sub addon_updates {
 my %u;
 my $file=get_update_file();
 return %u unless (-e $file);
 my $dom;
 eval { $dom = XML::LibXML->load_xml(location => $file) };
 return %u if ($@ || !$dom);
 foreach my $up ($dom->findnodes('/stream/update-status/update-list/update')) {
  my $name=$up->findvalue('./@name');
  $u{$name}=$up->findvalue('./@edition');
 }
 return %u;
}

############## active_channel_repo ##############
# The enabled EasyNAS channel repo (stable "EasyNAS" or testing "EasyNAS_Beta").
sub active_channel_repo {
 my $repo="EasyNAS";
 foreach (`/usr/bin/sudo /usr/bin/zypper --quiet lr -E 2>/dev/null`) {
  if (/\bEasyNAS_Beta\b/) { $repo="EasyNAS_Beta"; last; }
 }
 return $repo;
}

############## queue helpers ##############
# The addon install/update queue (see startup/addon-worker.sh). enqueue_op
# appends one op in click order; start_worker kicks the (single) drainer.
sub enqueue_op {
 my ($op,$package)=@_;
 return unless ($op eq "install" || $op eq "update");
 return unless (defined $package && $package =~ /^easynas(-[a-z0-9-]{1,64})?$/);
 # LIST form: op is literal, package validated -- no shell, no injection.
 system("/usr/bin/sudo","/easynas/startup/addon-worker.sh","enqueue",$op,$package);
}
sub start_worker {
 system("/usr/bin/sudo","/usr/bin/systemd-run","--collect","/easynas/startup/addon-worker.sh");
}

# Per-package queue state for the grid: package -> "installing"/"updating"
# (the one running now) or "waiting" (still queued). Empty when idle.
sub queue_state {
 my %st;
 if (open(my $c,'<','/run/easynas/addonq.cur')) {
  my $l=<$c>; close $c;
  if (defined $l && $l=~/^(\w+)\t(\S+)/) { $st{$2}=($1 eq 'install')?'installing':'updating'; }
 }
 if (open(my $q,'<','/run/easynas/addonq')) {
  while (my $l=<$q>) { $st{$2}||='waiting' if ($l=~/^(\w+)\t(\S+)/); }
  close $q;
 }
 return %st;
}

############## refresh_update_list ##############
# Regenerate /etc/easynas/addons/easynas.updates from the live rpmdb so the pending-
# update count (dashboard banner + sidebar badge) recomputes immediately after
# an addon action, instead of waiting for the 6-hourly check_update.pl.
sub refresh_update_list {
 my $repo=active_channel_repo();
 `/usr/bin/sudo /usr/bin/zypper --quiet --xmlout lu -a --repo $repo | /usr/bin/sudo /usr/bin/tee /etc/easynas/addons/easynas.updates >/dev/null`;
}


############## check_updates ##############
# The "Check for updates" button. Pull fresh metadata for the active channel
# and recompute the pending-update list NOW, instead of waiting for the
# 6-hourly check_update.pl. Runs the same three channel-scoped zypper calls
# that check_update.pl uses -- refresh (new metadata), search (surfaces newly
# published add-ons in the grid), lu (regenerates easynas.updates) -- so a few
# seconds, not a full-system refresh. Synchronous: view() then renders the grid
# already reflecting the check. The template disables the button while the
# install/update queue is active, so this never races the worker's zypper lock.
sub check_updates($self) {
 my $repo=active_channel_repo();
 my ($rc,$out)=zypper_run("--quiet","--gpg-auto-import-keys","refresh",$repo);
 if ($rc != 0) {
  # Say why (an unreachable channel, a lock) instead of "checked" over the
  # old list: the list below is then not news.
  write_log("addons","ERROR","check for updates: zypper refresh $repo failed: ".($out =~ s/\s+/ /gr));
  my $r=zypper_reason($out);
  $result="fail";
  $msg=(($rc >> 8) == 7)
     ? ($TEXT{'addons_check_locked'} || "The package manager is busy. Check again when the running install or update has finished.")
     : ($TEXT{'addons_check_failed'} || "Could not check the update channel for updates.").($r ne '' ? " (zypper: $r)" : '');
  return;
 }
 `/usr/bin/sudo /usr/bin/zypper --quiet --xmlout search easynas | /usr/bin/sudo /usr/bin/tee /etc/easynas/addons/easynas.addons >/dev/null`;
 refresh_update_list();
 $result="success";
 $msg=$TEXT{'addons_checked'} || "Checked for updates.";
}

############## update_all ##############
# Queue an update for every package that has one, in order -- the worker runs
# them one at a time. No page message: the grid badges + banner show progress.
sub update_all($self) {
 my %upd=addon_updates();
 foreach my $pkg (sort keys %upd) { enqueue_op("update",$pkg); }
 start_worker();
 $result="";
 $msg="";
}

############# install addon ###############
# Queue the install; the worker (startup/addon-worker.sh) processes the queue
# one op at a time in click order. The page returns immediately -- the grid
# shows this tile "installing" (or "waiting" behind another op) and the global
# banner shows overall progress; both refresh until the queue drains.
sub install_addon($self) {
 my $package=$self->param("package");
 # The package name reaches a root command -- whitelist its shape.
 unless (defined $package && $package =~ /^easynas-[a-z0-9-]{1,64}$/) {
  $result="fail";
  $msg=$TEXT{'addons_not_installed'};
  return;
 }
 enqueue_op("install",$package);
 start_worker();
 $result="";
 $msg="";
 return;
}


############# delete addon ###############
sub delete_addon($self) {
 my $package=$self->param("package");
 my $addons_update_dir=get_addons_update_dir();
 my @info;
 my $info1;
 my $info2;
 my $rc;
 my $deleted=0;
 $rc = `sudo /usr/bin/zypper -n remove $package`;
 @info=`sudo /usr/bin/zypper info $package`;
 foreach(@info)
  {
   ($info1,$info2) = split /:/,$_;
   if ($info1 =~ "Installed" && $info2 =~ "No")
   {
     $deleted=1
    }
   }
 if ($deleted)
 {
  `/usr/bin/sudo /usr/bin/zypper --xmlout info $package | /usr/bin/sudo /usr/bin/tee $addons_update_dir/$package.addon`;
  refresh_update_list();
  $result="success";
  $msg=$TEXT{'addons_deleted'};
 }
 else
 {
  $result="fail";
  $msg=$TEXT{'addons_not_deleted'};
 }
 return;

}


############## update_addon ##############
# Queue an update. Same queue as install -- one op at a time, click order.
# The base easynas restarts easynas.service on update, but the worker runs in
# its own transient unit and survives that, so it needs no special casing.
sub update_addon($self) {
 my $package=$self->param("package");
 unless (defined $package && $package =~ /^easynas(-[a-z0-9-]{1,64})?$/) {
  $result="fail";
  $msg=$TEXT{'addons_not_updated'};
  return;
 }
 enqueue_op("update",$package);
 start_worker();
 $result="";
 $msg="";
 return;
}


1;
