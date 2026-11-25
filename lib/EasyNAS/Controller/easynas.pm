#! /usr/bin/perl -w 
#
# easynas.pm
# 
# EasyNAS is free software: You can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2017
#
# Homepage    : https://easynas.org
# Sourceforge : https://sourceforge.net/projects/easynas/
#
#########################################################################

package easynas;

use strict;
use warnings;
use File::Path qw( make_path );
use Exporter;
use Number::Bytes::Human qw(format_bytes parse_bytes);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();
our @EXPORT    = qw( get_mount_dir get_conf_cron get_addons_file get_update_file get_update_count get_categories mounted
                     get_group_default get_conf_webui get_conf_hosts  get_lang_list get_addons_update_dir 
		     get_lang_text get_service_status get_menu get_addons get_addon_info 
		     write_log easynas_info addons_info fs_info vol_info users_info groups_info
                     disk_info health_info networks_info cpu_info memory_info
                     write_share_marker remove_share_marker rediscover_shares
                     get_update_state raid_status
                     set_current_lang get_admin_group is_nas_admin
                     setup_needed setup_done zypper_run zypper_reason service_ctl
                     root_read root_lines root_write root_append drop_block get_block);

############# Declarations #####################
my $authentication_enable = 1;
my $demo_site   = "demo.easynas.org";
my $lang_default="en-en";
my $group_default = "users";
# NAS accounts made administrators on the Users page are members of this
# system group (a gid below 1000, so the Groups page never lists it).
my $admin_group = "easynas-admins";
my %compress = ( 'no'=>'None','lzo'=>'Faster','zlib'=>'Better');
my %mount_options = ( 'rw'=>'Read&Write','ro'=>'ReadOnly');


############# Configuration dirs ###############
my $addons_dir = "/easynas/addons";
my $lang_dir= "/easynas/lang";
my $conf_dir= "/etc/easynas";
my $log_dir= "/var/log/easynas";
my $mount_dir = "/mnt";
my $addons_update_dir = $conf_dir."/addons";

##########  Configuration files ############
my $lang_conf=$conf_dir."/easynas.lang";
my $conf_cron="/etc/cron.d/easynas.cron";
my $conf_roles=$conf_dir."/easynas.roles";
my $conf_cert  = $conf_dir."/easynas.pem";
my $conf_hosts = "/etc/hosts";
my $conf_webui = "/usr/lib/systemd/system/easynas.service";
my $log_file = $log_dir."/easynas.log";
my $addons_file= $addons_update_dir."/easynas.addons";
my $update_file = $conf_dir."/easynas.updates";

# get_addons() cache. The addon catalog (~25 files under $addons_dir) is parsed
# on every page render -- often several times (get_menu/get_addon_info call it) --
# but only changes when an addon is installed/removed. In the persistent daemon
# this cache survives across requests; it is keyed on the directory mtime so it
# self-invalidates the moment an addon file is added or deleted.
my %addons_cache;        # the last parsed catalog
my $addons_cache_mtime;  # $addons_dir mtime the cache was built from

######## easynas_info #######
sub easynas_info
{
 my $arc=`/usr/bin/uname -m`;
 my $version;
 my %easynas;
 my $uuid;
 my $serial;
 # Display the installed easynas package's version-release -- this always
 # includes the build number (the RPM release) and is accurate even if
 # /etc/ImageVersion is stale. Fall back to parsing /etc/ImageVersion
 # ("EasyNAS-<version>-<release>") when the package isn't queryable, e.g. when
 # running from a source checkout.
 $version=`/usr/bin/rpm -q --qf '%{VERSION}-%{RELEASE}' easynas 2>/dev/null`;
 if ($? != 0 || $version eq "" || $version =~ /not installed/) {
   my $imageversion=`/usr/bin/cat /etc/ImageVersion 2>/dev/null`;
   (undef,$version)=split("-",$imageversion,2);
 }
 chomp($version);
 $uuid=`/usr/sbin/dmidecode | grep UUID`;
 (undef,$serial)=split(" ",$uuid);
 $easynas{'version'}=$version;
 $easynas{'arc'}=$arc;
 $easynas{'serial'}=$serial;
 return(%easynas);
}


######## cpu_info #######
sub cpu_info
{
 my %cpu;
 my $model;
 my $cores;
 my $load1;
 my $load5;
 my $load15;
 my $usage=0;
 my @stat1;
 my @stat2;
 my $total1=0;
 my $total2=0;
 my $idle1;
 my $idle2;

 $model=`/usr/bin/grep -m1 'model name' /proc/cpuinfo | /usr/bin/cut -d: -f2`;
 $model =~ s/^\s+|\s+$//g;
 if ($model eq "") {
  $model=`/usr/bin/uname -m`;
  chomp($model);
 }
 $cores=`/usr/bin/grep -c ^processor /proc/cpuinfo`;
 chomp($cores);
 ($load1,$load5,$load15)=split(" ",`/usr/bin/cat /proc/loadavg`);

 ### usage from two /proc/stat samples 0.25s apart:
 ### fields after the cpu label are user nice system idle iowait irq ...
 @stat1=split(" ",`/usr/bin/grep -m1 '^cpu ' /proc/stat`);
 select(undef,undef,undef,0.25);
 @stat2=split(" ",`/usr/bin/grep -m1 '^cpu ' /proc/stat`);
 shift(@stat1);
 shift(@stat2);
 $total1 += $_ foreach @stat1;
 $total2 += $_ foreach @stat2;
 $idle1=$stat1[3]+($stat1[4] || 0);
 $idle2=$stat2[3]+($stat2[4] || 0);
 if (($total2-$total1) > 0) {
  $usage=int(100*(($total2-$total1)-($idle2-$idle1))/($total2-$total1));
 }

 $cpu{'model'}=$model;
 $cpu{'cores'}=$cores;
 $cpu{'load1'}=$load1;
 $cpu{'load5'}=$load5;
 $cpu{'load15'}=$load15;
 $cpu{'usage'}=$usage;
 return(%cpu);
}


######## memory_info #######
sub memory_info
{
 my %memory;
 my $total=0;
 my $available=0;
 my $swap_total=0;
 my $swap_free=0;
 my $used;
 my @meminfo=`/usr/bin/cat /proc/meminfo`;

 ### /proc/meminfo values are in kB
 foreach (@meminfo)
 {
  if ($_ =~ /^MemTotal:/) {
   (undef,$total)=split(" ",$_);
  }
  if ($_ =~ /^MemAvailable:/) {
   (undef,$available)=split(" ",$_);
  }
  if ($_ =~ /^SwapTotal:/) {
   (undef,$swap_total)=split(" ",$_);
  }
  if ($_ =~ /^SwapFree:/) {
   (undef,$swap_free)=split(" ",$_);
  }
 }
 $used=$total-$available;
 $memory{'total'}=format_bytes($total*1024);
 $memory{'used'}=format_bytes($used*1024);
 $memory{'available'}=format_bytes($available*1024);
 $memory{'percentage'}=0;
 if ($total > 0) {
  $memory{'percentage'}=int($used/$total*100);
 }
 $memory{'has_swap'}=0;
 $memory{'swap_percentage'}=0;
 if ($swap_total > 0) {
  $memory{'has_swap'}=1;
  $memory{'swap_total'}=format_bytes($swap_total*1024);
  $memory{'swap_used'}=format_bytes(($swap_total-$swap_free)*1024);
  $memory{'swap_percentage'}=int(($swap_total-$swap_free)/$swap_total*100);
 }
 return(%memory);
}


######## networks_info #######
sub networks_info
{   
 my %networks;
 my @nmcli;
 my $nmcli;
 my $device;
 my $type;
 my $hwaddr;
 my $mtu;
 my $state;
 my $ipv4;
 my $ip;
 my $subnet;
 my $gateway;
 my $dns1;
 my $dns2;
 my $domain;
 my $method;
 my @interfaces = `ls /sys/class/net | /usr/bin/grep -v lo`;
 foreach (@interfaces)
    {
        $device=$_;
	chomp($device);
        @nmcli = `/usr/bin/sudo /usr/bin/nmcli device show $device `;
        foreach (@nmcli)
	{
	 if ($_ =~ /GENERAL.TYPE:/s) {
            (undef,$type) = split(" ",$_);
         }
	 if ($_ =~ /GENERAL.HWADDR:/s) {
            (undef,$hwaddr) = split(" ",$_);
         }
	 if ($_ =~ /GENERAL.MTU:/s) {
            (undef,$mtu) = split(" ",$_);
         }
	 if ($_ =~ /GENERAL.STATE:/s) {
            (undef,undef,$state) = split(" ",$_);
         }
	 if ($_ =~ /IP4.ADDRESS/s) {
            (undef,$ipv4) = split(" ",$_);
	    ($ip,$subnet)=split("/",$ipv4);
         }
	 if ($_ =~ /IP4.GATEWAY/s) {
            (undef,$gateway) = split(" ",$_);
         }
	 if ($_ =~ /IP4.DNS.1./s) {
            (undef,$dns1) = split(" ",$_);
         }
	 if ($_ =~ /IP4.DNS.2./s) {
            (undef,$dns2) = split(" ",$_);
         }
	 if ($_ =~ /IP4.DOMAIN/s) {
            (undef,$domain) = split(" ",$_);
         }
	}
      $nmcli = `/usr/bin/sudo /usr/bin/nmcli -f ipv4.method con show $device `;
      (undef,$method)=split(" ",$nmcli);
      $networks{$device}=[$device,$type,$state,$ipv4,$ip,$subnet,$gateway,$dns1,$dns2,$domain,$method];
      $device="";
      $type="";
      $state="";
      $ipv4="";
      $ip="";
      $subnet="";
      $gateway="";
      $dns1="";
      $dns2="";
      $domain="";
      $method="";
     }
 return(%networks);
}       



############# get_mount_dir ####################
sub get_mount_dir
{
 return($mount_dir);
}

########### get_group_default ###########
sub get_group_default
{
 return($group_default);
}

############# get_admin_group ###############
sub get_admin_group
{
 return($admin_group);
}

############# is_nas_admin ###############
# 1 when the NAS account $user is an administrator: a member of the admin
# group. Read from the group database on every call, so taking the flag away
# (or deleting the account) counts at once.
sub is_nas_admin
{
 my ($user)=@_;
 return 0 unless defined $user && $user ne '';
 my @g = getgrnam($admin_group);
 return 0 unless @g;
 return (grep { $_ eq $user } split(' ', $g[3] // '')) ? 1 : 0;
}

############# zypper_run ###############
# Run zypper (as root, never interactive) and return (exit status as
# system() gives it, what it printed). Its messages say why it failed --
# "Valid metadata not found at specified URL", a lock -- which a page can then
# show instead of a bare "failed". List arguments, no shell.
sub zypper_run
{
 my @args = @_;
 require IPC::Open3;
 my ($in, $fh, $out);
 my $pid = eval { IPC::Open3::open3($in, $fh, undef, '/usr/bin/sudo', '/usr/bin/zypper', '--non-interactive', @args) };
 return (255 << 8, "zypper did not start: $@") unless $pid;
 close $in;
 { local $/; $out = <$fh> // ''; }
 close $fh;
 waitpid($pid, 0);
 return ($?, $out);
}

# The last few lines zypper printed, for a page message.
sub zypper_reason
{
 my ($out) = @_;
 my @l = grep { /\S/ && !/^(Retrieving|Building|Loading|Reading|Refreshing|Repository .* is up to date)/ } split /\n/, ($out // '');
 my $r = join(' ', @l[ ($#l > 2 ? $#l - 2 : 0) .. $#l ]);
 $r =~ s/\s+/ /g;
 return substr($r, 0, 300);
}

############# setup_needed ###############
# 1 while the appliance looks new: the setup wizard (wizard.pm) hasn't been
# finished or dismissed, and there is no data filesystem yet. The admin's
# sign-in lands on the wizard then. An appliance set up before the wizard
# existed has a filesystem, so it never sees it unasked.
my $wizard_done = "$conf_dir/wizard.done";
sub setup_needed
{
 return 0 if -e $wizard_done;
 my %fs = fs_info();
 return (grep { $_ ne 'ROOT' && $_ ne 'BOOT' } keys %fs) ? 0 : 1;
}

# Mark the wizard finished (or dismissed): sign-in goes to the dashboard.
sub setup_done
{
 open(my $fh, '>', $wizard_done) or return 0;
 print $fh time(), "\n";
 close $fh;
 return 1;
}

############# get_conf_cron ###############
sub get_conf_cron
{
 return($conf_cron);
}

############# get_addons_file ###############
sub get_addons_file
{
 return($addons_file);
}

############# get_addons_update_dir ###############
sub get_addons_update_dir
{
 return($addons_update_dir);
}

############# get_update_file ###############
sub get_update_file
{
 return($update_file);
}

############# get_update_count ###############
# Number of pending EasyNAS package updates (base + addons), from the list
# check_update.pl writes. Count OCCURRENCES with grep -o, not lines (-c):
# zypper --xmlout emits the whole update list on a single line, so a line
# count reports "1" no matter how many updates are pending.
sub get_update_count
{
 # Count "<update " occurrences natively -- this runs on every page render, so
 # avoid forking grep|wc (two processes) each time in the single-process daemon.
 open(my $fh,'<',$update_file) or return 0;
 local $/;                       # slurp
 my $xml=<$fh>;
 close $fh;
 my $c=()=($xml =~ /<update /g); # count matches in list context
 return $c;
}

############# get_conf_hosts ################
sub get_conf_hosts
{
 return($conf_hosts);
}


########### get_conf_webui ############
sub get_conf_webui
{
 return($conf_webui);
}


######### get_lang #########
sub get_lang
{
    my $lang;
    if (-e $lang_conf )
    {
        # Read the one-line lang code natively instead of forking cat.
        open(my $fh,'<',$lang_conf) or return "en-en";
        $lang=<$fh>;
        close $fh;
        $lang="" unless defined $lang;
        chomp($lang);
        if (-e $lang_dir."/".$lang."/iso.txt")
        {
            return $lang;
        }
        else
        {
            return "en-en";
        }
    }
    else
    {
        write_lang("en-en");
        return "en-en";
    }
}


########### check_env ###########
sub check_env
{
  if ( !-e $lang_conf) {
   open(FH, '>', $lang_conf) or die $!;
   print FH $lang_default;
   close(FH);
  }

}

########### write_log ###########
sub write_log
{
 my $addon=$_[0];
 my $type=$_[1];
 my $message=$_[2];
 my $timestamp=localtime();
 my $FH;
 # '>>' makes the file when it isn't there: /var/log/easynas is easynas's
 # (startup/firstboot.sh), so no root is needed.
 open($FH, '>>', $log_file) or return;
 print $FH $timestamp." "."[$addon]"." ".$type." ".$message."\n";
 close $FH;
}


########## get_addon_info ##########
sub get_addon_info
{
    my $addon = $_[0];
    my %addons = get_addons();
    return($addons{$addon});
}


####### mounted ########
sub mounted
{   
    my $fs = $_[0];
    my $result="Mounted";
    
    # Match the exact mountpoint ("on <dir> type"), not a prefix -- a bare
    # grep for /mnt/Data also matches /mnt/Data2's mount line.
    if ((`/usr/bin/sudo /bin/mount | /usr/bin/grep " on $mount_dir/$fs type "` eq "") && ($fs ne "ROOT"))
    {
        $result="UnMounted";
    }
    return $result;
}    

######## get_service_status ########
# 1 while the unit runs. Reading a unit's state needs no root (and no shell).
sub get_service_status
{
    my $service=$_[0];
    return 0 unless defined $service && $service =~ /^[A-Za-z0-9][A-Za-z0-9@._-]*$/;
    return system('/usr/bin/systemctl','is-active','--quiet',$service) == 0 ? 1 : 0;
}

######## service_ctl ########
# Start/stop/restart/restart-later/reload/enable/disable systemd units, as
# root, through the root helper (startup/easynas-root), which only touches
# units EasyNAS manages. 1 when every one of them did it.
sub service_ctl
{
    my ($action, @units) = @_;
    my $ok = 1;
    for my $u (@units) {
        $ok = 0 if system('/usr/bin/sudo', '/easynas/startup/easynas-root', 'service', $action, $u) != 0;
    }
    return $ok;
}

# The config files the root daemons read (smb.conf, /etc/exports, rsyncd.conf,
# RADIUS clients, DLNA, TFTP) are read and changed through the root helper,
# which checks what a change adds (startup/easynas-root "file"). No shell: the
# text goes through a pipe.
my $ROOT_HELPER = '/easynas/startup/easynas-root';

# The file's text; '' when it doesn't exist, undef when it can't be read.
sub root_read
{
    my ($path) = @_;
    open(my $fh, '-|', '/usr/bin/sudo', $ROOT_HELPER, 'file', 'read', $path) or return undef;
    local $/;
    my $s = <$fh>;
    close $fh;
    return $? == 0 ? ($s // '') : undef;
}

# Its lines, as backticks gave them.
sub root_lines
{
    my $s = root_read(@_);
    return () unless defined $s && $s ne '';
    return split /^/, $s;
}

# Replace the file with $text (or, with 'append', add $text at its end).
# 1 when done; 0 when the helper refused it or failed (it says why in the
# web server's log).
sub root_write
{
    my ($path, $text, $op) = @_;
    open(my $fh, '|-', '/usr/bin/sudo', $ROOT_HELPER, 'file', $op // 'write', $path) or return 0;
    print $fh $text;
    close $fh;
    return $? == 0 ? 1 : 0;
}
sub root_append { return root_write($_[0], $_[1], 'append') }

# A sed '/start/,/end/' range over $text: the lines from one matching $start
# through the next one matching $end (to the end when none does), every time.
# drop_block is the text without them, get_block the first such range.
sub drop_block
{
    my ($text, $start, $end) = @_;
    my ($out, $in) = ('', 0);
    for my $l (split /^/, $text // '') {
        if ($in) { $in = 0 if $l =~ $end; next }
        if ($l =~ $start) { $in = 1; next }
        $out .= $l;
    }
    return $out;
}
sub get_block
{
    my ($text, $start, $end) = @_;
    my ($out, $in) = ('', 0);
    for my $l (split /^/, $text // '') {
        if ($in) { $out .= $l; last if $l =~ $end; next }
        if ($l =~ $start) { $in = 1; $out .= $l }
    }
    return $out;
}

########### get_compress_status ##########
# The live compression algorithm of a mounted filesystem, from /proc/mounts:
# "zstd", "lzo", "zlib", or "none" -- the same raw-algo vocabulary the settings
# page parses, translated to a label by the templates (fs_optimized/fs_faster/
# fs_better/fs_none). Native read, no forks (this runs once per filesystem per
# list render). The mountpoint is matched as an exact field, not a prefix, so
# /mnt/Data never matches /mnt/Data2's line. The kernel may report a level
# suffix ("compress=zstd:3") -- capture stops at the ":".
sub get_compress_status
{
 my $fs=$_[0];
 open(my $mf,'<','/proc/mounts') or return "none";
 while (my $l=<$mf>) {
  my (undef,$mp,undef,$opts)=split(' ',$l);
  next unless (defined $mp && $mp eq "$mount_dir/$fs");
  close $mf;
  return ($opts =~ /(?:^|,)compress(?:-force)?=(\w+)/) ? $1 : "none";
 }
 close $mf;
 return "none";
}


######## Raid Status ##########
    
sub raid_status
{   
    my $raid;
    my $null;
    my $result; 
    my $fs=$_[0];
    my @fs_df;
    my $dir;
    if ($fs eq "ROOT") {
     $dir="/";
    }
    else {
     $dir=$mount_dir."/".$fs;
    }
    @fs_df=`sudo /sbin/btrfs fi df $dir | grep "Data" `;
    foreach (@fs_df) {
        ($null,$raid,$null,$null)=split(/ /,$_);
    }
    chop($raid);
    if ($raid eq "single") {
        $result="JBOD";
    }
    else {
        $result=$raid;
    }
    return $result;
}



######## current_lang ########
sub current_lang
{
    my $lang;
    if (-e $lang_conf )
    {
        # Read the one-line lang code natively; current_lang is called several
        # times per render, so forking cat each time is pure waste.
        open(my $fh,'<',$lang_conf) or return "en-en";
        $lang=<$fh>;
        close $fh;
        $lang="" unless defined $lang;
        chomp($lang);
        if (-e $lang_dir."/".$lang."/iso.txt")
        {
            return $lang;
        }
        else
        {
            return "en-en";
        }
    }
    else
    {
        write_lang("en-en");
        return "en-en";
    }
}


######## set_current_lang ########
# Persist the UI language (the directory code, e.g. "en-en"). Validated against
# the shape AND an existing lang dir before it reaches the shell.
sub set_current_lang
{
    my $lang=shift;
    return unless defined $lang && $lang =~ /^[a-z]{2}-[a-z]{2}$/;
    return unless -f $lang_dir."/".$lang."/iso.txt";
    write_lang($lang);
}

# The language file is the web interface's own (easynas owns /etc/easynas,
# see startup/firstboot.sh): written directly, no root needed.
sub write_lang
{
    my ($lang)=@_;
    open(my $fh,'>',$lang_conf) or return;
    print $fh "$lang\n";
    close $fh;
}


########### lang_list #############
sub get_lang_list
{
 my $file;
 my $lang;
 my $flag;
 my @lang_list;
 
 opendir (DIR, $lang_dir) or die "Error";
 while ($file = readdir(DIR))
 {
  if ($file ne "." && $file ne ".." && -f "$lang_dir/$file/iso.txt")
  {
    ($lang,$flag) = split(",",`/usr/bin/cat $lang_dir/$file/iso.txt`);
    push(@lang_list,{name=>$lang,symbol=>$file,flag=>$flag});
  }
 }
 close(DIR);
 return @lang_list;
}



########## get_lang_text ###########

sub get_lang_text
{
    my $addon=$_[0];
    my $file;
    our %TEXT;

    ### load default language stings ###
    if (current_lang() ne $lang_default)
    {
	opendir (DIR, $lang_dir."/".$lang_default) or die "Error";
	while ($file = readdir(DIR))
	{
	    if ($file ne "iso.txt" && $file ne "." && $file ne ".." )
	    {
		require "$lang_dir/$lang_default/$file";
	    }
	}
	close(DIR);
    }

    ### load selected language string #####
    opendir (DIR, $lang_dir."/".current_lang() ) or die "Error";
    while ($file = readdir(DIR))
    {
	if ($file ne "iso.txt" && $file ne "." && $file ne ".." )
	{
	    require "$lang_dir/".current_lang()."/$file";
	}
    }
    close(DIR);

    # The language files are UTF-8 but are read as bytes (they have no "use
    # utf8"), and Mojolicious encodes what a page outputs as UTF-8, so every
    # letter outside ASCII went out encoded twice and showed as two or three
    # garbage characters. Decode each string once; strings from files loaded
    # on an earlier call (require loads a file only once) are already text.
    foreach my $v (values %TEXT) {
	utf8::decode($v) unless utf8::is_utf8($v);
    }
    return(%TEXT);
}


######### get_menu ###########
sub get_menu 
{
 my @menu;
 my %addons=get_addons();
 my $addons_by_type;
 my $addon;
 my $type;

 foreach $addon (sort keys %addons) {
  if (($addons{$addon}{type} ne "") and ($addons{$addon}{enable} ne "false")) {
   push @{ $addons_by_type->{$addons{$addon}{type}}},{name=>$addons{$addon}{description},icon=>$addons{$addon}{icon},program=>$addons{$addon}{program}};
  }
 }

 foreach $type (sort keys %$addons_by_type)
    {           
     push(@menu,{type=>$type,addons=>$addons_by_type->{$type}});
    }           
 return(@menu);
}



######### get_addons  #########

sub get_addons
{
    my $file;
    my $line;
    my $type;
    my %addons;
    my $addons_by_type;
    my $addon_enable;
    my $addon_name;
    my $addon_description;
    my $addon_icon;
    my $addon_version;
    my $addon_author;
    my $addon_type;
    my $addon_config;
    my $addon_config2;
    my $addon_clients;
    my $addon_secrets;
    my $addon_service;
    my $addon_program;
    my $addon_access;

    # Serve from cache while the addon dir is unchanged (see %addons_cache).
    my $mtime = (stat($addons_dir))[9];
    if (defined $mtime && defined $addons_cache_mtime && $mtime == $addons_cache_mtime) {
        return %addons_cache;
    }

     opendir (DIR, $addons_dir) or die $!;
     while ($file = readdir(DIR))
     {
 	if (($file ne ".") && ($file ne ".."))
	{
	    $addon_enable="true";
	    $addon_name="";
	    $addon_description="";
            $addon_icon="";
            $addon_version="1.0";
            $addon_author="Author";
            $addon_type="";
            $addon_config="";
            $addon_config2="";
            $addon_clients="";
            $addon_secrets="";
            $addon_service="";
            $addon_program="";
            $addon_access="";
	    open(FR, "$addons_dir/$file") or die $!;
	    while ($line = <FR>)
	    {
		if ($line =~ /<name>/i)
		{
		    $addon_name = $line;
		    $addon_name =~ s|<.?name>||g;
		    $addon_name = substr($addon_name, 1);
		    chop($addon_name);
		}
		if ($line =~ /<description>/i)
		{
		    $addon_description = $line;
		    $addon_description =~ s|<.?description>||g;
		    $addon_description =~ s/^\s+|\s+$//g;
		}
		if ($line =~ /<icon>/i)
                {
                    $addon_icon = $line;
                    $addon_icon =~ s|<.?icon>||g;
                    $addon_icon =~ s/^\s+|\s+$//g;
                }

		if ($line =~ /<version>/i)
		{
		    $addon_version = $line;
		}
		if ($line =~ /<type>/i)
		{
		    $addon_type = $line;
		    $addon_type =~ s|<.?type>||g;
		    $addon_type = substr($addon_type, 1);
		    chop($addon_type);
		}
		if ($line =~ /<author>/i)
		{
		    $addon_author = $line;
		    $addon_author =~ s|<.?author>||g;
		    $addon_author = substr($addon_author, 1);
		    chop($addon_author);
		}
		if ($line =~ /<program>/i)
		{
		    $addon_program = $line;
		    $addon_program =~ s|<.?program>||g;
		    $addon_program = substr($addon_program, 1);
		    chop($addon_program);
		}
		if ($line =~ /<config>/i)
		{
		    $addon_config = $line;
		    $addon_config =~ s|<.?config>||g;
		    $addon_config = substr($addon_config, 1);
		    chop($addon_config);
		}
		if ($line =~ /<config2>/i)
		{
		    $addon_config2 = $line;
		    $addon_config2 =~ s|<.?config2>||g;
		    $addon_config2 = substr($addon_config2, 1);
		    chop($addon_config2);
		}
		if ($line =~ /<clients>/i)
		{
		    $addon_clients = $line;
		    $addon_clients =~ s|<.?clients>||g;
		    $addon_clients = substr($addon_clients, 1);
		    chop($addon_clients);
		}
		if ($line =~ /<secrets>/i)
		{
		    $addon_secrets = $line;
		    $addon_secrets =~ s|<.?secrets>||g;
		    $addon_secrets = substr($addon_secrets, 1);
		    chop($addon_secrets);
		}
		### systemd service files
		if ($line =~ /<service>/i)
		{
		    $addon_service = $line;
		    $addon_service =~ s|<.?service>||g;
		    $addon_service = substr($addon_service, 1);
		    chop($addon_service);
		}
		### who may open it: "user" = signed-in NAS users too (the file
		### manager); anything else, or nothing, = the administrator only
		if ($line =~ /<access>/i)
		{
		    $addon_access = $line;
		    $addon_access =~ s|<.?access>||g;
		    $addon_access =~ s/^\s+|\s+$//g;
		}
                if ($line =~ /<enable>/i)
		{
 		    $addon_enable = $line;
		    $addon_enable =~ s|<.?enable>||g;
                    $addon_enable = substr($addon_enable, 1);
                    chop($addon_enable);
 		}
	    }
	    ### push collected infos in %addons
   	     $addons{$addon_name}={enable=>$addon_enable, name=>$addon_name, description=>$addon_description, icon=>$addon_icon, version=>$addon_version, author=>$addon_author, type=>$addon_type, program=>$addon_program, config=>$addon_config, config2=>$addon_config2, clients=>$addon_clients, secrets=>$addon_secrets, service=>$addon_service, access=>$addon_access};

	    close(FR);

	    ### Undefine variables for next run
	    undef($addon_name);
	    undef($addon_description);
	    undef($addon_icon);
	    undef($addon_version);
	    undef($addon_author);
	    undef($addon_type);
	    undef($addon_config);
	    undef($addon_config2);
	    undef($addon_clients);
	    undef($addon_secrets);
	    undef($addon_service);
	    undef($addon_program);
	    undef($addon_access);
	}
    }
 closedir(DIR);
 # Cache the parse, keyed on the dir mtime captured above.
 %addons_cache = %addons;
 $addons_cache_mtime = $mtime;
 return(%addons);
}


########## addons_info #########
sub addons_info
{
 my %addons;
 my $addon;
 my $fh;
 my $dom;
 my $package;
 my $name;
 my $group;
 my $version;
 my $status;
 my $desc;

 ### The catalog (regenerated by check_update.pl via `zypper search easynas`)
 ### only enumerates the available addon packages. Installed state and version
 ### are read straight from rpm -- always accurate and independent of whether
 ### an update check has run or of the zypper info text format.
 return(%addons) unless (-e $addons_file);
 open $fh, '<', $addons_file;
 binmode $fh; # drop all PerlIO layers possibly created by a use open pragma
 eval { $dom = XML::LibXML->load_xml(IO => $fh) };
 close($fh);
 return(%addons) if ($@ || !$dom);

 foreach $addon ($dom->findnodes('/stream/search-result/solvable-list/solvable')) {
  $package=$addon->findvalue('./@name');
  $package =~ s/^\s+|\s+$//g;
  next if ($package eq "" || $package eq "easynas");
  (undef,$group,$name)=split("-",$package);
  $desc=$addon->findvalue('./@summary');

  $version=`/usr/bin/rpm -q --qf '%{VERSION}-%{RELEASE}' $package 2>/dev/null`;
  if ($? == 0) {
   $status="up-to-date";
   $desc=`/usr/bin/rpm -q --qf '%{SUMMARY}' $package 2>/dev/null` if ($desc eq "");
  }
  else {
   $version="";
   $status="not installed";
  }

  $addons{$package}=[$name,$group,$desc,$status,$version];
 }

 return(%addons);
}

# "updating" while the add-on install/update queue runs (startup/addon-worker.sh
# writes it), else "". Read by the layout so every page shows a banner.
sub get_update_state
{
  open(my $fh, '<', $conf_dir."/update.status") or return "";
  my $s = <$fh>;
  close $fh;
  chomp $s if defined $s;
  return $s // "";
}

######## users_info ###########
sub users_info
{
  my %users;
  # Human accounts are uid 1000+; skip the service and nobody accounts.
  foreach (`/usr/bin/getent passwd`)
    {
        my ($username,undef,$uid,undef,$desc) = split(/:/,$_);
        next unless defined $uid;
        next if ($username eq 'easynas' || $username eq 'nobody');
        if (($uid >= 1000) && ($uid < 65000))
        {
            # The admin group shows as the Administrator flag, not as a group.
            my $groups = join(' ', grep { $_ ne $admin_group }
                                   split(' ', `/usr/bin/id -Gn $username 2>/dev/null`));
            $users{$username}=[$uid,$username,$desc,$groups,is_nas_admin($username)];
        }
    }
   return(%users);
}


######### groups_info ##########
sub groups_info
{
    my %groups;
    # Keep the "users" primary group (gid 100) plus the local range; skip the
    # easynas service group.
    foreach (`/usr/bin/getent group`)
    {
        my ($groupname,undef,$gid) = split(/:/,$_);
        next unless defined $gid;
        next if ($groupname eq 'easynas');
        if (($gid == 100) || (($gid >= 1000) && ($gid < 65000)))
        {
           $groups{$groupname}=[$gid,$groupname];
        }
    }
  return(%groups);
}


#### disk_info ######

sub disk_info
{
    my $disk;
    my $disk_name;
    my %disks;
    my $type;
    my $status;
    my $size;
    my $presize;
    my $model;
    my @sysmon;
    my @disks = `/usr/bin/sudo /usr/sbin/smartctl --scan`;


    foreach (@disks)
    {
	($disk,undef,$type,undef,undef,undef)=split(" ", $_);
	(undef,undef,$disk_name)=split("/",$disk);
	@sysmon = `/usr/bin/sudo /usr/sbin/smartctl -i  $disk`; 
	foreach (@sysmon) 
	{
	  if ($_ =~ /User Capacity/s) {
	    (undef,undef,undef,undef,$size,$presize) = split(" ",$_);
	  }
	  if ($_ =~ /Device Model/s) {
	    (undef,undef,$model) = split(" ",$_);
	  }
	  if ($_ =~ /Product/s) {
            (undef,$model) = split(" ",$_);
          }
	}

        if (index(`/usr/bin/sudo /usr/bin/mount | grep "on / "`,$disk) != -1) 
        {
         $status="disk_system"; 
        }
	else 
	{
	  if (`/usr/bin/sudo /sbin/btrfs filesystem show | /usr/bin/grep $disk`)
 	  {
	   $status="disk_used";
	  }
	  else
	  {
  	   $status="disk_free";
	  }
	}
        $disks{$disk_name}=[$disk_name,$type,$size.$presize,$status,$model];
	$type="";
	$size="";
	$presize="";
	$status="";
	$model="";
    }
    return(%disks);
}


########## health info ##########
sub health_info
{
 my $disk;
 my $health;
 my %health;
 my @sysmon;
 my @errors;
 my $write_errs="NA";
 my $read_errs="NA";
 my $flush_errs="NA";
 my $corruption_errs="NA";
 my $generation_errs="NA";
 my @disks = `/usr/bin/sudo /usr/sbin/smartctl --scan`;
 foreach (@disks)
    {
        ($disk,undef,undef,undef,undef,undef)=split(" ", $_);
        @sysmon = `/usr/bin/sudo /usr/sbin/smartctl -H  $disk`;
        $health="disk_bad";
        foreach (@sysmon)
        {
          if (($_ =~ /PASSED/s) or ($_ =~ /OK/s)) {
            $health="disk_good";
          }
        }
        @errors=`/usr/bin/sudo /sbin/btrfs device stat $disk`;
	foreach (@errors)
        {
          if ($_ =~ /write_io_errs/)
          {
            (undef,$write_errs) = split(" ",$_);
          }
	  if ($_ =~ /read_io_errs/)
          {
            (undef,$read_errs) = split(" ",$_);
          }
	  if ($_ =~ /flush_io_errs/)
          {
            (undef,$flush_errs) = split(" ",$_);
          }
	  if ($_ =~ /corruption_errs/)
          {
            (undef,$corruption_errs) = split(" ",$_);
          }
	  if ($_ =~ /generation_errs/)
          {
            (undef,$generation_errs) = split(" ",$_);
          }

        }
        $health{$disk}=[$health,$write_errs,$read_errs,$flush_errs,$corruption_errs,$generation_errs];
        $write_errs="NA";
	$read_errs="NA";
	$flush_errs="NA";
	$corruption_errs="NA";
	$generation_errs="NA";
     }

 return(%health);
}




########## vol_info ##########
sub vol_info
{
  my %fs=fs_info();
  my %volumes;
  my @vol_info;
  my @vols_info;
  my $id;
  my $du;
  my $vol;
  my $size;
  my $fs;

  foreach $fs (keys %fs)
  {
   if ($fs ne "ROOT") {
    @vols_info = `sudo /sbin/btrfs subvolume list $mount_dir/$fs`;
    foreach (@vols_info)
    { 
      @vol_info=split(' ',$_);
      $vol=$vol_info[8];
      $id=$vol_info[1];
      if ($vol ne "@") {
       $du = `/usr/bin/sudo /usr/bin/du -h -a $mount_dir/$fs/$vol | /usr/bin/tail -1`;
       ($size,undef) = split(" ",$du);
       $volumes{$fs."/".$vol}=[$id,$vol,$fs,$size];
      }
    }
   }
  }
 return(%volumes);
}


############ fs_info ###########
sub fs_info
{
 my $fs;
 my $uuid;
 my $health;
 my $mounted;
 my $path;
 my $raid;
 my $size;
 my $used;
 my $free;
 my $percentage;
 my $devices;
 my $devcount;
 my $missing;
 my %filesystems;
 my $dir;
 my @filesystem_list = `/usr/bin/sudo /sbin/btrfs filesystem show`;
 my @usage;
 foreach (@filesystem_list)
    {
	### List by LABEL ?
	if($_ =~ m/Label:/)
	{
	    (undef,$fs,undef,$uuid)=split(" ", $_);
	    chop($fs);
	    $fs = substr($fs, 1);
            $health = "good";
            $devcount = 0;
            $missing = 0;
            if ($fs eq "ROOT") {
             $dir="/";
            }
            else {
             $dir=$mount_dir."/".$fs;
            }
	}

       # A device is missing if btrfs says so, or if a devid line itself is
       # flagged "missing" (some versions list it that way instead).
       if ($_ =~ m/missing/i)
       {
        $missing = 1;
       }

       if ($_ =~ m/devid/)
       {
        $devcount++;
        (undef,undef,undef,undef,undef,undef,undef,$path) = split(' ',$_);
       }


       if($_ =~ m/Total/)
       {
	(undef,undef,$devices,undef,undef,undef,undef) = split(' ',$_);
       } 

	if (mounted($fs) eq "Mounted")

        {
           $mounted="Mounted";
	   $raid=raid_status($fs);
	   @usage=`/usr/bin/sudo /sbin/btrfs filesystem usage $dir`;
       foreach (@usage)
       {
        if($_ =~ m/Device size:/)
        {
         (undef,undef,$size) = split(' ',$_);
        }
        if($_ =~ m/Used:\s/)
        {
         (undef,$used) = split(' ',$_);
        }
        if($_ =~ m/Free \(/)
        {
         (undef,undef,undef,$free) = split(' ',$_);
        }
       }

   	}
        else
        {
           $mounted="UnMounted";
	   $raid='';
	   $size="";
	   $free=""; 
	   $used=""; 
        }
	
       if (parse_bytes($size) > 0) {
        $percentage=(int((parse_bytes($used))/(parse_bytes($size))*100));
       }
       else {
	$percentage=0;
       }
       # Degraded when a device is flagged missing, or fewer devices are present
       # than the filesystem expects (Total devices). Recomputed every line; the
       # last line of the fs block (with the full devid count) is what's stored.
       $health = ($missing || (defined $devices && $devices ne "" && $devcount < $devices))
                 ? "degraded" : "good";
       $filesystems{$fs}=[$uuid,$health,$size,$used,$free,$percentage,$devices,$path,$mounted,$raid,get_compress_status($fs)];
    }

 # Second pass -- refine health with the two extra signals the appliance cares
 # about beyond a missing device:
 #   (1) any btrfs I/O/corruption error counter on a member disk ("disk_errors")
 #   (2) fewer disks than the RAID profile is meant to run on ("insufficient")
 # A missing device ("degraded", set above) is the most severe and wins over both.
 # Both checks need a mountpoint to probe, so unmounted volumes keep their
 # first-pass health.
 my %raid_min = ( RAID0=>2, RAID1=>2, RAID10=>4, RAID5=>3, RAID6=>4,
                  RAID1C3=>3, RAID1C4=>4 );        # JBOD/single/DUP default to 1
 foreach my $fs (keys %filesystems)
    {
     next if ($filesystems{$fs}[1] eq "degraded");     # already critical
     next unless ($filesystems{$fs}[8] eq "Mounted");  # need a mount to probe
     my $d = ($fs eq "ROOT") ? "/" : $mount_dir."/".$fs;

     # (1) Disk errors: any non-zero *_errs counter across the member devices.
     my $err = 0;
     foreach (`/usr/bin/sudo /sbin/btrfs device stats $d 2>/dev/null`)
        {
         if (/_errs\s+(\d+)/ && $1 > 0) { $err = 1; last; }
        }
     if ($err) { $filesystems{$fs}[1] = "disk_errors"; next; }

     # (2) Under-provisioned RAID: fewer disks than the profile expects. When
     # not degraded the present-device count equals Total devices ([6]).
     my $need = $raid_min{ $filesystems{$fs}[9] } // 1;
     my $have = $filesystems{$fs}[6];
     if (defined $have && $have ne "" && $have < $need)
        {
         $filesystems{$fs}[1] = "insufficient";
        }
    }
    return (%filesystems);
}


######## Share markers ########
# A shared volume records its share definition INSIDE itself
# (<vol>/.easynas/<type>.share) so shares survive an OS reinstall and travel
# with the data. rediscover_shares() rebuilds the live server config from the
# markers of the currently-mounted volumes -- no external backup needed.

sub write_share_marker
{
 my ($vol_path,$type,$content)=@_;
 return unless (-d $vol_path);
 open(my $fh,'|-','/usr/bin/sudo',$ROOT_HELPER,'share-marker','write',$vol_path,$type) or return;
 print $fh $content;
 close($fh);
}

sub remove_share_marker
{
 my ($vol_path,$type)=@_;
 system('/usr/bin/sudo',$ROOT_HELPER,'share-marker','remove',$vol_path,$type);
}

sub rediscover_shares
{
 my %vol=vol_info();
 my $mount_dir=get_mount_dir();
 my $v;
 my $path;
 my $marker;
 my $content;
 my $name;
 foreach $v (keys %vol)
 {
  $path="$mount_dir/$v";

  ### Samba: the marker is the smb.conf section (#### name #### ... )
  # The markers are in the volume, which its users can write: the helper
  # adds only what a share section of EasyNAS's own may hold.
  $marker="$path/.easynas/smb.share";
  if (-f $marker && open(my $mf, '<', $marker))
  {
   $content=do { local $/; <$mf> } // "";
   close $mf;
   ($name)=$content =~ /^#### ([A-Za-z0-9._-]+) ####/;
   my $conf=root_read('/etc/samba/smb.conf');
   if ($name && defined $conf && $conf !~ /^#### \Q$name\E ####\s*$/m)
   {
    root_append('/etc/samba/smb.conf',$content)
      or write_log("samba","WARNING","the share marker in $path was not taken: see the web server log");
   }
  }

  ### NFS: the marker is the /etc/exports line
  $marker="$path/.easynas/nfs.share";
  if (-f $marker && open(my $mf, '<', $marker))
  {
   $content=<$mf> // "";
   close $mf;
   chomp($content);
   my $conf=root_read('/etc/exports');
   if ($content ne "" && defined $conf && index($conf,$content) < 0)
   {
    root_append('/etc/exports',"$content\n")
      or write_log("nfs","WARNING","the share marker in $path was not taken: see the web server log");
   }
  }
 }
 `/usr/bin/sudo /usr/sbin/exportfs -a 2>/dev/null`;
 service_ctl('reload','smb.service') if get_service_status('smb.service');
}


########################### Main ############################

#check_env;

1;
