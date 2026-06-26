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
# Homepage    : https://www.easynas.org
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
our @EXPORT    = qw( get_mount_dir get_conf_cron get_addons_file get_update_file get_categories mounted 
                     get_group_default get_conf_webui get_conf_hosts  get_lang_list get_addons_update_dir 
		     get_lang_text get_service_status get_menu get_addons get_addon_info 
		     write_log easynas_info addons_info fs_info vol_info users_info groups_info 
                     disk_info health_info networks_info);

############# Declarations #####################
my $authentication_enable = 1;
my $demo_site   = "demo.easynas.org";
my $lang_default="en-en";
my $group_default = "users";
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

######## easynas_info #######
sub easynas_info
{
 my $imageversion=`/usr/bin/cat /etc/ImageVersion`;
 my $arc=`/usr/bin/uname -m`;
 my $version;
 my %easynas;
 my $uuid;
 my $serial;
 (undef,$version)=split("-",$imageversion);	
 $uuid=`/usr/sbin/dmidecode | grep UUID`;
 (undef,$serial)=split(" ",$uuid);
 $easynas{'version'}=$version;
 $easynas{'arc'}=$arc;
 $easynas{'serial'}=$serial;
 return(%easynas);
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
        $lang=`/usr/bin/cat $lang_conf`;
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
        `echo "en-en" | /usr/bin/sudo /usr/bin/tee $lang_conf`;
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
 unless(-e $log_file) {
    #Create the file if it doesn't exist
    `sudo touch $log_file`;
    `sudo chown easynas.easynas $log_file`;
 }
 open($FH, '>>', $log_file) or die $!;
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
    
    if ((`/usr/bin/sudo /bin/mount | /usr/bin/grep "$mount_dir/$fs"` eq "") && ($fs ne "ROOT"))
    {
        $result="UnMounted";
    }
    return $result;
}    

######## get_service_status ########
sub get_service_status
{
    my $service=$_[0];
    if (`/usr/bin/sudo /usr/bin/systemctl status $service | /usr/bin/grep "Active: active"` eq "")
    {
        return 0;
    }
    else {
        return 1;
    }
} 

########### get_compress_status ##########
sub get_compress_status
{
 my $fs=$_[0];
 my $compress="none";
 if (`/usr/bin/sudo /usr/bin/mount | /usr/bin/grep "$mount_dir/$fs" | /usr/bin/grep "compress=zlib"`)
  {
   $compress="better";
  }
  elsif (`/usr/bin/sudo /usr/bin/mount | /usr/bin/grep "$mount_dir/$fs" | /usr/bin/grep "compress=lzo"`)
  {
   $compress="faster";
  }
  return($compress);
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
        $lang=`/usr/bin/cat $lang_conf`;
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
        `echo "en-en" | /usr/bin/sudo /usr/bin/tee $lang_conf`;
        return "en-en";
    }
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
                if ($line =~ /<enable>/i)
		{
 		    $addon_enable = $line;
		    $addon_enable =~ s|<.?enable>||g;
                    $addon_enable = substr($addon_enable, 1);
                    chop($addon_enable);
		    print $addon_enable;
 		}
	    }
	    ### push collected infos in %addons
   	     $addons{$addon_name}={enable=>$addon_enable, name=>$addon_name, description=>$addon_description, icon=>$addon_icon, version=>$addon_version, author=>$addon_author, type=>$addon_type, program=>$addon_program, config=>$addon_config, config2=>$addon_config2, clients=>$addon_clients, secrets=>$addon_secrets, service=>$addon_service};

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
	}
    }
 closedir(DIR);
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
 my @info;
 my $info1;
 my $info2;
 my $version;
 my $status;
 my $desc;
 if (-e $addons_file) {
  open my $fh, '<', $addons_file;
  binmode $fh; # drop all PerlIO layers possibly created by a use open pragma
  $dom = XML::LibXML->load_xml(IO => $fh);
 }
 foreach $addon ($dom->findnodes('/stream/search-result/solvable-list/solvable')) {
  $package=$addon->findvalue('./@name');
  $package =~ s/^\s+//;
  (undef,$group,$name)=split("-",$package);
  @info=`cat $addons_update_dir/$package.addon`;
  foreach(@info)
  {
   ($info1,$info2) = split /:/,$_;
   if ($info1 =~ "Version") 
   {
    $version=$info2;
   }
   if ($info1 =~ "Status") 
   {
    $status=$info2;
   }
   if ($info1 =~ "Summary") 
   {
    $desc=$info2;
   }
  }
  if ($package ne "easynas") {
   $addons{$package}=[$name,$group,$desc,$status,$version];
  }
 }
 
 return(%addons);
}

######## users_info ###########
sub users_info
{
  my @userlist = `/usr/bin/cat /etc/passwd`;
  my $username;
  my $groups;
  my $desc;
  my %users;
  my $uid;
  foreach (@userlist)
    {
        ($username,undef,$uid,undef,$desc,undef,undef) = split(/:/,$_);
        $groups = `/usr/bin/sudo /usr/bin/id -Gn $username`;
        if (($uid > 999 ) && ($uid < 6500))
        {
            $users{$username}=[$uid,$username,$desc,$groups];
        }
    }
   return(%users);
}


######### groups_info ##########
sub groups_info
{
    my @grouplist = `/usr/bin/cat /etc/group` ;
    my %groups;
    my $groupname;
    my $gid;
    foreach (@grouplist)
    {
        ($groupname,undef,$gid) = split(/:/,$_);
        if (($gid eq 100) || ($gid > 999 ) && ($gid < 2000) && ($groupname ne 'easynas'))
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
	    print "write ".$write_errs
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
            if ($fs eq "ROOT") {
             $dir="/";
            }
            else {
             $dir=$mount_dir."/".$fs;
            }
	}

       if ($_ =~ m/ Some devices missing/)
       {
        $health = "degraded";
       }
      
       if ($_ =~ m/devid/)
       {
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
       $filesystems{$fs}=[$uuid,$health,$size,$used,$free,$percentage,$devices,$path,$mounted,$raid,get_compress_status($fs)];
    }
    return (%filesystems);
}


########################### Main ############################

#check_env;

1;
