
# @FILE@
# Version @PROJECT_VERSION@
#
# @MYNAME_UC@ is free software: You can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# This file is part of @MYNAME_UC@ (c) created by @PROJECT_AUTHOR@ 2012-@YEAR@
#
# Homepage    : @PROJECT_URL@
# Sourceforge : @PROJECT_SF_URL@
#
#########################################################################

#### SVR_SAMBA ####
$TEXT{'samba'} = "SAMBA";
$TEXT{'samba_smb'} = "SMB";
$TEXT{'samba_nmb'} = "NMB";
$TEXT{'samba_workgroup'} = "Workgroup Name";
$TEXT{'samba_netbios'} = "NetBios Name";
$TEXT{'samba_not_null'} = "Samba settings can't be null";
$TEXT{'samba_name'} = "Share Name";
$TEXT{'samba_vol'} = "Volume Name";
$TEXT{'samba_path'} = "Path";
$TEXT{'samba_on_off'} = "ON / OFF";
$TEXT{'samba_settings'} = "Settings";
$TEXT{'samba_delete'} = "Delete";
$TEXT{'samba_shared_vol'} = "Shared Volumes";
$TEXT{'samba_delete_share'} = "Delete Share ?";
$TEXT{'samba_add_smb'} = "Add Samba Share";
$TEXT{'samba_share_name'} = "Share Name";
$TEXT{'samba_readonly'} = "Read Only";
$TEXT{'samba_allow_guest'} = "Allow Guest";
$TEXT{'samba_browsable'} = "Browsable";
$TEXT{'samba_recycle'} = "Recycle";
$TEXT{'samba_save'} = "Save";
$TEXT{'samba_reset'} = "Reset";
$TEXT{'samba_not_installed'} = "Samba not installed";
$TEXT{'samba_missing_name'} = "Share name was not entered"; 
$TEXT{'samba_share_exists'} = "Share name allready exists"; 
$TEXT{'samba_help'} = "
The SAMBA service allows you to share volumes with windows systems.<br>
The NMB service will allow to share the system name with windows computers.<br><br>
ON / OFF:<br>
SMB - start or stop the SAMBA service<br>
NMB - start or stop the NMB service<br><br>
Settings:<br>
WorkGroup Name - the windows network name.<br>
Netbios Name - the EasyNAS name in the windows network<br><br>
Shared Volumes:<br>
view and delete the volumes that have SAMBA share";
