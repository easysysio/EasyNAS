#! /usr/bin/perl -w 
#========================================================================
# check_update.sh
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
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2021
#
# Homepage    : https://www.easynas.org
#
#########################################################################

use lib '.';
use XML::LibXML;

##### Declaration ####
my $addons="/etc/easynas/addons/easynas.addons";
my $log_file="/var/log/easynas/easynas.log";
my $package;
my $dom;
my $fh;
my $timestamp=localtime();

###### write log ######
 open($fh, '>>', $log_file) or die $!;
 print $fh $timestamp." [SYSTEM] Checking EasyNAS updates\n";
 close $fh;

##### Capture Stats ######
# All external calls are bounded by timeouts so a slow or unreachable endpoint
# can never hang the update check.
my $version=`cat /etc/ImageVersion`;
my $ip=`curl -s --connect-timeout 5 --max-time 10 https://ifconfig.io/ip`;
chop($ip);
my $arc=`/usr/bin/uname -m`;
chop($arc);
my $uuid=`/usr/sbin/dmidecode 2>/dev/null | grep UUID`;
(undef,$serial)=split(" ",$uuid);
`curl -s --connect-timeout 5 --max-time 10 https://repo.easysys.io/api/stats.pl -H "Content-Type: application/x-www-form-urlencoded" -d "arc=$arc&ver=$version&ip=$ip&serial=$serial"`;

####### Refresh Repo #######
# EasyNAS ships two channel repos -- EasyNAS (stable) and EasyNAS_Beta
# (testing) -- with only the active channel enabled. Query updates from
# whichever is enabled instead of hardcoding the stable alias, so the check
# also works on testing images (where EasyNAS is disabled).
my $repo="EasyNAS";
foreach (`/usr/bin/sudo /usr/bin/zypper --quiet lr -E 2>/dev/null`) {
  if (/\bEasyNAS_Beta\b/) { $repo="EasyNAS_Beta"; last; }
}
`/usr/bin/sudo /usr/bin/zypper --quiet --gpg-auto-import-keys refresh`;
`/usr/bin/sudo /usr/bin/zypper --quiet --xmlout search easynas | /usr/bin/sudo /usr/bin/tee /etc/easynas/addons/easynas.addons`;
`/usr/bin/sudo /usr/bin/zypper --quiet --xmlout lu -a --repo $repo | /usr/bin/sudo /usr/bin/tee  /etc/easynas/easynas.updates`;

####### Core (firmware) image update #######
# Fetch the channel's per-arch core-image manifest (version/date/file/sha256)
# into easynas.core; the Firmware page reads this file (no live network call).
my $channel = ($repo eq "EasyNAS_Beta") ? "testing" : "stable";
`curl -s --connect-timeout 5 --max-time 15 https://repo.easysys.io/easynas/$channel/RAW/latest.$arc | /usr/bin/sudo /usr/bin/tee /etc/easynas/easynas.core >/dev/null`;

if (-e $addons) {
  open my $fh, '<', $addons;
  binmode $fh; # drop all PerlIO layers possibly created by a use open pragma
  $dom = XML::LibXML->load_xml(IO => $fh);
  foreach $addon ($dom->findnodes('/stream/search-result/solvable-list/solvable')) {
    $package=$addon->findvalue('./@name');
    $package =~ s/^\s+//;
    if ($package =~ /easynas/) 
    {
     `sudo /usr/bin/zypper --xmlout info $package | /usr/bin/tee /etc/easynas/addons/$package.addon`;
    }
  }
}

exit;
