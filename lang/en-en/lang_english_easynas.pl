
# lang_english_easynas.pl
# Version 1.2.0
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
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2022
#
# Homepage    : https://www.easynas.org
#
#########################################################################


$TEXT{'easynas'} = "EasyNAS";
$TEXT{'yariv'} = "Yariv Hakim";
$TEXT{'please_wait'} = "Please Wait....";
$TEXT{'not_authorized'} = "You are not authorize to use this function";
$TEXT{'edit'} = "Edit";
$TEXT{'delete'} = "Delete";
$TEXT{'about'} = "About";
$TEXT{'save'} = "Save";
$TEXT{'reset'} = "Reset";
$TEXT{'create'} = "Create";
$TEXT{'add'} = "Add";
$TEXT{'easynas_url'} = "https://www.easynas.org";
$TEXT{'running'} = "Running on";
$TEXT{'close'} = "Close";

#### Types ####
$TEXT{'storage'} = "Storage";
$TEXT{'system'} = "System";
$TEXT{'sharing'} = "File Sharing";
$TEXT{'services'} = "Services";
$TEXT{'multimedia'} = "Multimedia";
$TEXT{'realm'} = "Realm";


#####   Login #####
$TEXT{'login'} = "Login";
$TEXT{'login_to_easynas'} = "Login to EasyNAS";
$TEXT{'login_username'} = "User Name";
$TEXT{'login_password'} = "Password";
$TEXT{'login_remember_me'} = "Remember me";

######  Dashboard ######
$TEXT{'dashboard'} = "Dashboard";
$TEXT{'dashboard_view_details'} = "View Details";
$TEXT{'dashboard_drives'} = "Drives";
$TEXT{'dashboard_filesystems'} = "File Systems";
$TEXT{'dashboard_users'} = "Users";
$TEXT{'dashboard_volumes'} = "Volumes";
$TEXT{'dashboard_disk'} = "Disk";
$TEXT{'dashboard_filesystem'} = "File System";
$TEXT{'dashboard_failed'} = "Failed";
$TEXT{'dashboard_used'} = "Used";
$TEXT{'dashboard_system'} = "System";
$TEXT{'dashboard_free'} = "Free";
$TEXT{'dashboard_good'} = "Good";
$TEXT{'dashboard_degreded'} = "Degraded";
$TEXT{'dashboard_update_available'} = "New updates available";
$TEXT{'dashboard_click_here'} = " click here to update";

#### Search ####
$TEXT{'search'} = "Search";

#### System Info ####
$TEXT{'sysinfo'} = "System Info";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "Vendor";
$TEXT{'model'} = "Model";
$TEXT{'cache_size'} = "Cache Size";
$TEXT{'speed'} = "Speed";
$TEXT{'os'} = "OS";
$TEXT{'architecture'} = "Architecture";
$TEXT{'firmware'} = "Firmware";
$TEXT{'filesystem'} = "File System";
$TEXT{'memory'} = "Memory";
$TEXT{'total_memory'} = "Total Memory";
$TEXT{'free_memory'} = "Free Memory";
$TEXT{'total_swap_memory'} = "Total Swap Memory";
$TEXT{'free_swap_memory'} = "Free Swap Memory";

#### Settings ####
$TEXT{'settings'} = "Settings"; 
$TEXT{'settings_date_time'} = "Date / Time";
$TEXT{'settings_cert'} = "Certificate";
$TEXT{'settings_repo'} = "Repository";
$TEXT{'settings_hostname'} = "Hostname";
$TEXT{'settings_port'} = "Port";
$TEXT{'settings_save'} = "Save";
$TEXT{'settings_reset'} = "Reset";
$TEXT{'settings_bad_port'} = "Bad System Port";
$TEXT{'settings_saved'} = "New Settings were saved. Restart might be required for the settings to take effect.";

$TEXT{'change_settings_in_progress'} = "Change Settings in Progress....";
$TEXT{'cert_details'} = "Certificate Details";
$TEXT{'no_cert'} = "No Certificate found";
$TEXT{'bad_cert'} = "Bad Certificate";
$TEXT{'upload'} = "Upload";
$TEXT{'error_updating_date'} = "Error updating Date / Time";
$TEXT{'error_settings_demo'} = "Can not change settings in a demo site";
$TEXT{'enabled'} = "Enabled";
$TEXT{'disabled'} = "Disabled";
$TEXT{'enable'} = "Enable";
$TEXT{'disable'} = "Disable";

#### User Profile ####
$TEXT{'user_profile'} = "User Profile";


#### Backup ####
$TEXT{'backup_restore'} = "Backup & Restore";
$TEXT{'backup'} = "Backup";
$TEXT{'restore'} = "Restore";
$TEXT{'file_name'} = "File Name";
$TEXT{'backup_failed'} = "Backup Failed";
$TEXT{'backup_completed'} = "Backup completed successfully";
$TEXT{'restore_failed'} = "Restore Failed";
$TEXT{'testore_completed'} = "Restore Completed";

#### Network settings ####
$TEXT{'network_setting'} = "Network Settings";
$TEXT{'network_interface'} = "Interface";
$TEXT{'network_type'} = "Type";
$TEXT{'network_state'} = "State";
$TEXT{'network_speed'} = "Speed";
$TEXT{'network_connection_type'} = "Connection Type";
$TEXT{'network_ip'} = "IP Address";
$TEXT{'network_subnet'} = "Subnet Mask";
$TEXT{'network_gateway'} = "Gateway";
$TEXT{'network_dns1'} = "Primary DNS";
$TEXT{'network_dns2'} = "Secondary DNS";
$TEXT{'network_domain'} = "Domain";
$TEXT{'network_actions'} = "Actions";
$TEXT{'network_edit'} = "Edit";
$TEXT{'network_static'} = "Static";
$TEXT{'network_dhcp'} = "DHCP";
$TEXT{'network_saved'} = "IP address changed";
$TEXT{'network_failed_to_save'}="Failed to change IP settings";
$TEXT{'network_manager_down'}="Network Manager is down";
$TEXT{'network_settings_can_not_change'}="Network settings can not be changed";
$TEXT{'network_click_here_to_activate'} = "Click here to activate";

$TEXT{'error_ip_demo'} = "Can't change IP in a demo site";
$TEXT{'network_restart'} = "Restart EasyNAS server for the changes to take place.";


#### Scheduler ##########
$TEXT{'scheduler'} = "Scheduler";
$TEXT{'snapshots'} = "Snapshots";
$TEXT{'syncs'} = "Remote Syncs";
$TEXT{'scrubs'} = "File Systems Scrub";
$TEXT{'powers'} = "Power Control";
$TEXT{'create_sc'} = "Create Schedule";
$TEXT{'schedule_snapshot'} = "Schedule Snapshot";
$TEXT{'schedule_sync'} = "Schedule Remote Sync";
$TEXT{'schedule_scrub'} = "Schedule Scrub";
$TEXT{'schedule_power'} = "Schedule Power Control";
$TEXT{'no_vol_selected'} = "No Volume was selected";
$TEXT{'sc_exists'} = "Schedule name already exists";
$TEXT{'control_type'} = "Control Type";
$TEXT{'error_restarting_sc'} = "Error restarting scheduler";
$TEXT{'delete_sc'} = "Delete Schedule";
$TEXT{'error_deleting_sc'} = "Error deleting scheduler";
$TEXT{'update_sc'} = "Update Schedule"; 
$TEXT{'sc_name'} = "Schedule Name";
$TEXT{'remote_system'} = "Remote System";
$TEXT{'time'} = "Time";
$TEXT{'date'} = "Date";
$TEXT{'day_of_week'} = "Day of week";
$TEXT{'sc'} = "SCHEDULE";
$TEXT{'scs'} = "Schedules";
$TEXT{'sc_name'} = "Name";
$TEXT{'sc_task'} = "Task";
$TEXT{'vol_name'} = "Volume Name";
$TEXT{'fs_name'} = "File System Name";
$TEXT{'fs_delete'} = "Delete File System";
$TEXT{'weekday'} = "WeekDay";
$TEXT{'delete_sc?'} = "Are you sure you want to delete the schedule ?";

### NETWORK ###
$TEXT{'network_settings'} = "Network Settings";
$TEXT{'network_interfaces'} = "Network Interface";
$TEXT{'interface'} = "Interface";
$TEXT{'state'} = "State";
$TEXT{'broadcast'} = "Broadcast";
$TEXT{'net_mask'} = "Mask";
$TEXT{'hardware_mac'} = "MAC-Address";
$TEXT{'dhcp'} = "DHCP";
$TEXT{'static'} = "Static";
$TEXT{'ip_address'} = "IP-Address";
$TEXT{'subnet_mask'} = "Subnet Mask";
$TEXT{'gateway'} = "Gateway";
$TEXT{'domain'} = "Domain";
$TEXT{'pri_dns'} = "Primary DNS";
$TEXT{'sec_dns'} = "Secondary DNS";
$TEXT{'state_up'} = "Up";
$TEXT{'state_down'} = "Down";
$TEXT{'error_ip_demo'} = "Can't change IP in a demo site";
$TEXT{'network_restart'} = "Restart EasyNAS server for the changes to take place.";

#### Realm ####
$TEXT{'computers'} = "Computers";
$TEXT{'computers_manager'} = "Computers Manager";


#### Monitor ####
$TEXT{'cpu'} = "CPU";
$TEXT{'memory'} = "Memory";
$TEXT{'disk_io'} = "Disk IO";
$TEXT{'network_band'} = "Network Bandwitdh";


#### Power Managment ####
$TEXT{'power_management'} = "Power Management";
$TEXT{'shutdown_restart'} = "Shutdown / Restart";
$TEXT{'error_restart_demo'} = "Can't Restart in a demo site";
$TEXT{'restart_system'} = "Restarting System......";
$TEXT{'error_shutdown_demo'} = "Can't Shutdown in a demo site";
$TEXT{'shutdown_system'} = "Shuting Down System.....";
$TEXT{'execute_immediately'} = "Execute system Restart/Shutdown immediately.";
$TEXT{'restart'} = "Restart";
$TEXT{'shutdown'} = "Shutdown";
$TEXT{'close_service'} = "Closing Services.....";
$TEXT{'close_fs'} = "Unmounting File Systems.....";
$TEXT{'restart_are_u_sure'} = "Are you sure you want to restart ?";
$TEXT{'restart_help'} = "You are about to Restart EasyNAS<br>
                         Please save all your files and close open services<br><br>
			 Press Restart when ready";
$TEXT{'shutdown_help'} = "You are about to Shutdown EasyNAS<br>
                         Please save all your files and close open services<br><br>
                         Press Shutdown when ready";

#### Firmware ####
$TEXT{'firmware'} = "Firmware";
$TEXT{'firmware_name'} = "Name"; 
$TEXT{'firmware_desc'} = "Description"; 
$TEXT{'firmware_new'} = "New Version";
$TEXT{'firmware_current'} = "Current Version";
$TEXT{'firmware_actions'} = "Actions";
$TEXT{'firmware_update_r_u_sure'} = "Are you sure you want to update ?";
$TEXT{'firmware_update'} = "Update";
$TEXT{'firmware_update_available'} = "New updates available";
$TEXT{'firmware_here'} = " click here to update";
$TEXT{'firmware_refresh'} = "Refresh";
$TEXT{'firmware_refreshed'} = "Repositories refreshed";
$TEXT{'firmware_noupdate'} = "No Updates Available";
$TEXT{'firmware_update_success'} = "Update Finished Succesfuly";
$TEXT{'firmware_update_failed'} = "Update Failed";

#### Addons #####
$TEXT{'addons'} = "Addons";
$TEXT{'addons_sharing'} = "File Sharing";
$TEXT{'addons_storage'} = "Storage&Backup";
$TEXT{'addons_multimedia'} = "Multimedia";
$TEXT{'addons_services'} = "Services";
$TEXT{'addons_lang'} = "Language";
$TEXT{'addons_other'} = "Other Apps";
$TEXT{'addons_name'} = "Addon Name";
$TEXT{'addons_version'} = "Version";
$TEXT{'addons_update'} = "Update";
$TEXT{'addons_delete'} = "Delete";
$TEXT{'addons_status'} = "Status";
$TEXT{'addons_desc'} = "Description";
$TEXT{'addons_actions'} = "Actions";
$TEXT{'addons_install'} = "Install";
$TEXT{'addons_delete'} = "Delete";
$TEXT{'addons_update'} = "Update";
$TEXT{'addons_install?'} = "Install Addon ?";
$TEXT{'addons_update?'} = "Update Addon ?";
$TEXT{'addons_delete?'} = "Delete Addon ?";
$TEXT{'addons_info'} = "Information";
$TEXT{'addons_installed'} = "Addon installed successfully";
$TEXT{'addons_not_installed'} = "Error installing addon";
$TEXT{'addons_deleted'} = "Addon deleted successfully";
$TEXT{'addons_not_deleted'} = "Error deleting Addon";
$TEXT{'addons_updated'} = "Addon updated successfully";
$TEXT{'addons_not_updated'} = "Error updating addon";
$TEXT{'addons_close'} = "Close";


$TEXT{'firmware_upgrade'} = "Firmware Upgrade";
$TEXT{'lang'} = "Language";
$TEXT{'other_apps'} = "Other Apps";
$TEXT{'component'} = "Component";
$TEXT{'author'} = "Author";
$TEXT{'version'}="Version";
$TEXT{'current_version'}="Current Version";
$TEXT{'new_version'}="New Version";
$TEXT{'package_name'} = "Package Name";
$TEXT{'update'} = "Update";
$TEXT{'refresh'} = "Refresh";
$TEXT{'refresh_failed'} = "Refresh Failed";
$TEXT{'installed_version'} = "Installed Version";
$TEXT{'current_version'} = "Current Version";
$TEXT{'install_addon'} = "Install Addon";
$TEXT{'uninstall_addon'} = "UnInstall Addon";
$TEXT{'upgrade_addon'} = "Upgrade Addon";
$TEXT{'check_for_update'} = "Check for Update";
$TEXT{'cheking_firmware_availble'} = "Checking for available firmware: ";
$TEXT{'latest_firmware'} = "Your system is already in the latest firmware available";
$TEXT{'download_latest_version_here'} = "Download latest version from <a href=http://www.easynas.org/download target=New_Page>here</a>";
$TEXT{'upgrade_in_progress'} = "Upgrade In progress.........";
$TEXT{'downloading_firmware'} = "Downloading firmware.......";
$TEXT{'installing_new_firmware'} = "Installing new firmware......";
$TEXT{'firmware_upgraded'}="Firmware Upgraded";
$TEXT{'error_upgrading'}="Error Upgrading, please try again later";
$TEXT{'error_connecting'}="Error Connecting to EasyNAS repository, please try again later";
$TEXT{'failed_to_refresh_repo'}="Failed to refresh EasyNAS repository. Try again later";
$TEXT{'failed_to_install_addon'} = "Failed to install addon";
$TEXT{'refresh_repo'}="Refresh Repository";
$TEXT{'failed_to_delete_addon'} = "Failed to delete addon";
$TEXT{'install_addon?'} = "Install Addon ?";
$TEXT{'update_addon?'} = "Update Addon ?";
$TEXT{'delete_addon?'} = "Delete Addon ?";
$TEXT{'update_all'} = "Update All";
$TEXT{'firmware_refreshed'} = "Repositories refreshed";
$TEXT{'firmware_not_refreshed'} = "Error Refreshing Repositories";

#### Disk ####
$TEXT{'disk_manager'} = "Disk Manager";
$TEXT{'disk'} = "Disk";
$TEXT{'disk_size'} = "Size";
$TEXT{'disk_status'} = "Status";
$TEXT{'disk_type'} = "Type";
$TEXT{'disk_health'} = "Health";
$TEXT{'disk_model'} = "Model";
$TEXT{'disk_serial'} = "Serial";
$TEXT{'disk_firmware'} = "Firmware";
$TEXT{'disk_actions'} = "Actions";
$TEXT{'disk_free'} = "Free";
$TEXT{'disk_used'} = "Used";
$TEXT{'disk_system'} = "System";
$TEXT{'disk_bad'} = "Bad";
$TEXT{'disk_good'} = "Good";
$TEXT{'disk_format'} = "Format";
$TEXT{'disk_settings'} = "Settings";
$TEXT{'disk_format_success'} = "Disk Formatted Succesfully";
$TEXT{'disk_format_failed'} = "Disk Format Failed";
$TEXT{'disk_write_io_errs'} = "Write IO Errors";
$TEXT{'disk_read_io_errs'} = "Read IO Errors";
$TEXT{'disk_flush_io_errs'} = "Flush IO Errors";
$TEXT{'disk_corruption_errs'} = "Corruptions Errors";
$TEXT{'disk_generation_errs'} = "Generation Errors";
$TEXT{'disk_clean_errs'} = "Clean Errors";
$TEXT{'disk_clean_errs_success'} = "Errors Cleaned";
$TEXT{'disk_clean_errs_failed'} = "Errors Failed to Clean";
$TEXT{'disk_close'} = "Close";

#### File System ####
$TEXT{'fs'} = "File System";
$TEXT{'fs_create'} = "Create File System";
$TEXT{'fs_name'} = "File System Name";
$TEXT{'fs_raid_level'} = "Raid Level";
$TEXT{'fs_compression'} = "Compression";
$TEXT{'fs_ssd_optimization'} = "SSD Optimization";
$TEXT{'fs_auto_defrag'} = "Auto Defrag";
$TEXT{'fs_auto_mount'} = "Audo Mount";
$TEXT{'fs_add'} = "Add Filesystem";
$TEXT{'fs_reset'} = "Reset";
$TEXT{'fs_used'} = "Used";
$TEXT{'fs_status'} = "Status";
$TEXT{'fs_drives'} = "Drives";
$TEXT{'fs_health'} = "Health";
$TEXT{'fs_readonly'} = "Read Only";
$TEXT{'fs_read&write'} = "Read & Write";
$TEXT{'fs_filesystem_contain_vol'} = "File System Contain Volumes";
$TEXT{'fs_failed_changing_label'} = "File System label could not be changed";
$TEXT{'fs_name_changed'} = "File System name was changed";
$TEXT{'fs_umount_first'} = "Filesystem need to be unmounted before changing the name";
$TEXT{'fs_failed_formating_disk'} = "Failed Formating Disks";
$TEXT{'fs_failed_creating_dir'} = "Failed Creating Directory";
$TEXT{"fs_failed_mounting"} = "Failed Mounting Filesystem";
$TEXT{'fs_mounted'} = "File System Mounted";
$TEXT{'fs_size'} = "Size";
$TEXT{'fs_better'} = "Better";
$TEXT{'fs_faster'} = "Faster";
$TEXT{'fs_optimized'} = "Optimized";
$TEXT{'fs_none'} = "None";
$TEXT{'fs_mount'} = "Mount";
$TEXT{'fs_unmount'} = "Unmount";
$TEXT{'fs_delete?'} = "Delete Filesystem ?";
$TEXT{'fs_change_settings'} = "Change Settings";

$TEXT{'cancel'} = "Cancel";
$TEXT{'resume'} = "Resume";
$TEXT{'snapshot'} = "Snapshot";
$TEXT{'filesystems'} = "File Systems";
$TEXT{'fs_manager'} = "File System Manager";
$TEXT{'better'} = "Better";
$TEXT{'faster'} = "Faster";
$TEXT{'none'} = "None";
$TEXT{'health'} = "Health";
$TEXT{'good'} = "Good";
$TEXT{'degreded'} = "Degraded";
$TEXT{'remove_hd'} = "Remove HD";
$TEXT{'replace_hd'} = "Replace HD";
$TEXT{'source_hd'} = "Source HD";
$TEXT{'target_hd'} = "Target HD";
$TEXT{'failed_to_remove_hd'} = "Failed to remove HD";
$TEXT{'fs_hd_removed'} = "HD removed succesfully";
$TEXT{'fs_hd_added'} = "HD added succesfully";
$TEXT{'fs_hd_replaced'} = "HD replaced succesfully";
$TEXT{'fs_failed_to_replace'} = "Failed to replace HD";
$TEXT{'add_hd'} = "Add HD";
$TEXT{'failed_to_add_HD'} = "Failed to add HD";
$TEXT{'repair_hd'} = "Repair HD";
$TEXT{'fs_need_to_be_unmounted'} = "File System need to be unmounted";
$TEXT{'fs_need_to_be_mounted'} = "File System need to be mounted";
$TEXT{'check&repair_hd'} = "Check & Repair HD";
$TEXT{'create_fs'} = "Create File System";
$TEXT{'fs_deleted'} = "File System Deleted Succesfuly";
$TEXT{'no_disks_were_selected'} = "No Disks were selected";
$TEXT{'no_fs_name_was_entered'} = "No File System name was entered";
$TEXT{'reserved_fs'} = "ROOT is a reserved name";
$TEXT{'raid_0_require_two'} = "Raid 0 requires at least two drives";
$TEXT{'raid_1_require_two'} = "Raid 1 requires at least two drives";
$TEXT{'raid_10_require_four'} = "Raid 10 requires at least four drives";
$TEXT{'raid_5_require_three'} = "Raid 5 requires at least three drives";
$TEXT{'raid_6_require_four'} = "Raid 6 requires at least four drives";
$TEXT{'raid_the_same'} = "Raid level is the same, no action required.";
$TEXT{'raid_require_force'} = "Moving between Raid level will reduce integrity, you must force this change.";
$TEXT{'failed_creating_directory'} = "Failed creating a directory.";
$TEXT{'failed_creating_fs'} = "Failed creating a file system.";
$TEXT{'failed_mounting_fs'} = "Failed mounting a file system.";
$TEXT{'mount_fs'} = "Mount File System";
$TEXT{'unmount_fs'} = "Unmount File System";
$TEXT{'fs_failed_unmounting_fs'} = "Failed unmounting a file system.";
$TEXT{'no_free_disk'} = "No Free Disks Available";
$TEXT{'raid_profile'} = "Raid Profile";
$TEXT{'compression'} = "Compression";
$TEXT{'disks'} = "Disks";
$TEXT{'ssd_optimization'} = "SSD Optimization";
$TEXT{'auto_mount'} = "Auto Mount";
$TEXT{'auto_defrag'} = "Auto Defrag";
$TEXT{'mount_option'} = "Mount Options";
$TEXT{'file_system_name'} = "File System Name";
$TEXT{'fs_raidlevel'} = "Raid Level";
$TEXT{'raid_profile'} = "Raid Profile";
$TEXT{'force_raid_change'} = "Force Raid Change";
$TEXT{'change_raid'} = "Change Raid";
$TEXT{'fs_change_name'} = "Change Name";
$TEXT{'fs_mount_options'} = "Mount Options";
$TEXT{'fs_disks'} = "Disks";
$TEXT{'number'} = "Number";
$TEXT{'disk'} = "Disk";
$TEXT{'total_size'} = "Total Size";
$TEXT{'status'} = "Status";
$TEXT{'remove_hd?'} = "Are you sure you want to remove the hardisk ?";
$TEXT{'repair_hd?'} = "Are you sure you want to repair the hardisk ?";
$TEXT{'check_repair_complete'} = "Check & Repair completed";
$TEXT{'add_hd'} = "Add Hard Disk";
$TEXT{'no_free_disks_available'} = "No Free Disks Available";
$TEXT{'drives'} = "Drives";
$TEXT{'fs_limit'} = "File System Quota Limit";
$TEXT{'0_no_limit'} = "(Enter 0 for no limits)";
$TEXT{'failed_limit'} = "Failed limiting quota on filesystem";
$TEXT{'filesystem_contain_vol'} = "File System Contain Volumes";
$TEXT{'filesystem_not_changed'} = "File System name was not changed";
$TEXT{'fs_created'} = "File System successfuly Created";

$TEXT{'fs_jbod_info'} = "JBOD, which stands for just a bunch of disks, is a type of multilevel configuration for disks. It refers to a collection of disks in an array combined as one logical volume.";
$TEXT{'fs_raid0_info'} = "RAID 0 (also known as a stripe set or striped volume) splits data evenly across two or more disks, without parity information, redundancy, or fault tolerance. Since RAID 0 provides no fault tolerance or redundancy, the failure of one drive will cause the entire array to fail, due to data being striped across all disks.";
$TEXT{'fs_raid1_info'} = "RAID 1 consists of an exact copy (or mirror) of a set of data on two or more disks; a classic RAID 1 mirrored pair contains two disks. This configuration offers no parity, striping, or spanning of disk space across multiple disks";
$TEXT{'fs_raid5_info'} = "RAID 5 consists of block-level striping with distributed parity. Parity information is distributed among the drives. It requires that all drives but one be present to operate. Upon failure of a single drive, subsequent reads can be calculated from the distributed parity such that no data is lost.RAID 5 requires at least three disks.";
$TEXT{'fs_raid6_info'} = "RAID 6 extends RAID 5 by adding another parity block; thus, it uses block-level striping with two parity blocks distributed across all member disks.";

#### Volumes ####
$TEXT{'vol_manager'} = "Volume Manager";
$TEXT{'vol_create'} = "Create Volume";
$TEXT{'vol_name'} = "Volume Name";
$TEXT{'vol_filesystem'} = "File System";
$TEXT{'vol_user_owner'} = "User Owner";
$TEXT{'vol_group_owner'} = "Group Owner";
$TEXT{'vol_no_vol_name'} = "No Volume name was entered";
$TEXT{'vol_no_fs_selected'} = "No File System was selected";
$TEXT{'vol_created'} = "Volume Created Succesfuly";
$TEXT{'vol_id'} = "ID";
$TEXT{'vol_size'} = "Size";
$TEXT{'vol_fs'} = "File System";
$TEXT{'vol_actions'} = "Actions";
$TEXT{'vol_delete'} = "Delete Volume";
$TEXT{'vol_delete?'} = "Are you sure you want to delete the volume ?";
$TEXT{'vol_faild_to_delete'} = "Failed to delete volume";
$TEXT{'vol_deleted'} = "Volume Deleted Succesfully";
$TEXT{'vol_snapshot'} = "Snapshot";
$TEXT{'vol_settings'} = "Settings";
$TEXT{'vol_permission'} = "Volume Permission";
$TEXT{'vol_user'} = "User";
$TEXT{'vol_group'} = "Group";
$TEXT{'vol_others'} = "Others";
$TEXT{'vol_readonly'} = "Read Only";
$TEXT{'vol_read&write'} = "Read & Write";
$TEXT{'vol_deny'} = "Deny";
$TEXT{'vol_reset'} = "Reset";
$TEXT{'vol_save'} = "Save";
$TEXT{'vol_create_snapshot'} = "Create Snapshot";
$TEXT{'vol_snapshot_name'} = "Snapshot Name";
$TEXT{'vol_no_snapshot_name'} = "No Snapshot name was entered";
$TEXT{'vol_failed_to_add_snapshot'} = "Failed to add snapshot";
$TEXT{'vol_snapshot_created'} = "Snapshot Created Succesfuly";
$TEXT{'vol_saved'} = "Volume Saved Succesfully";
$TEXT{'vol_no_fs'} = "No Available File System";

$TEXT{'failed_to_change_owner'} = "Failed to change owner";
$TEXT{'failed_to_change_permission'} = "Failed to change permission";
$TEXT{'group_owner'} = "Group Owner";
$TEXT{'user_permission'} = "User Permission";
$TEXT{'group_permission'} = "Group Permission";
$TEXT{'others_permission'} = "Others Permissions";
$TEXT{'vols'} = "Volumes";
$TEXT{'vol'} = "Volume";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "Volume Name";
$TEXT{'size'} = "Size";
$TEXT{'delete_vol?'} = "Are you sure you want to delete the volume ?";
$TEXT{'no_schedule_name'} = "No schedule name was entered.";
$TEXT{'failed_add_vol'} = "Failed adding a volume.";
$TEXT{'group_created'} = "Group created successfully";
$TEXT{'group_deleted'} = "Group deleted successfully";


#### Sync ####
$TEXT{'sync'} = "Sync Volumes";
$TEXT{'hostname'} = "Host name";
$TEXT{'rdir'} = "Remote Directory";
$TEXT{'password'} = "Password";
$TEXT{'sync_option'} = "Sync Option";
$TEXT{'sync_complete'} = "Sync Completed";
$TEXT{'failed_to_sync'} = "Failed to Sync";
$TEXT{'sync_could_not_connect'} = "Could not connect to RSync server";
$TEXT{'sync_bad_user_password'} = "Failed to Sync - Bad username or password";
$TEXT{'no_hostname'} = "Hostname was not enterd";
$TEXT{'no_rdir'} = "Remote dir was not enterd";
$TEXT{'no_vol'} = "Volume was not selected";

#### Users ####
$TEXT{'users_manager'} = "Users Manager";
$TEXT{'users_create'} = "Create User";
$TEXT{'users_id'} = "ID";
$TEXT{'users_name'} = "User Name";
$TEXT{'users_desc'} = "Description";
$TEXT{'users_groups'} = "Groups";
$TEXT{'users_actions'} = "Actions";
$TEXT{'users_password'} = "Password";
$TEXT{'users_password_retype'} = "Password Retype";
$TEXT{'users_created'} = "User created successfully";
$TEXT{'users_deleted'} = "User deleted successfully";
$TEXT{'users_add'} = "Add User";
$TEXT{'users_reset'} = "Reset";
$TEXT{'users_delete'} = "Delete User";
$TEXT{'users_settings'} = "Settings";
$TEXT{'users_change_password'} = "Change Password";
$TEXT{'users_passwords_do_no_match'}="Passwords do not match";
$TEXT{'users_password_must_exist'} = "Password must exist";
$TEXT{'users_user_must_exist'} = "User must exist";
$TEXT{'users_failed_to_add_user'} = "Failed to add user";
$TEXT{'users_failed_to_add_samba_user'} = "Failed to add Samba User";
$TEXT{'users_failed_to_add_samba_user'} = "Failed to add Samba User";
$TEXT{'users_failed_to_delete_user'} = "Failed to delete user";
$TEXT{'users_delete?'} = "Are you sure you want to delete the user ?";
$TEXT{'users_change_password'} = "Change Password";
$TEXT{'users_save_password'} = "Save Password";
$TEXT{'users_password_changed'} = "Password Changed Succesfully";
$TEXT{'users_save'} = "Save";
$TEXT{'users_settings_failed_to_save'} = "Settings failed to be saved";
$TEXT{'users_settings_saved'} = "Settings Saved Succesfully";


#### Groups ####
$TEXT{'groups_manager'} = "Groups Manager";
$TEXT{'groups_create'} = "Create Group";
$TEXT{'groups_failed_to_add'} = "Failed to add the group";
$TEXT{'group_delete'} = "Delete Group";
$TEXT{'group'} = "Group";
$TEXT{'groups'} = "Groups";
$TEXT{'group_can_not_delete'} = "can't be deleted";
$TEXT{'groups_failed_to_delete'} = "Failed to delete the group";
$TEXT{'group_name'} = "Group Name";
$TEXT{'access_permission'} = "Access Permission";
$TEXT{'groups_settings'} = "Groups Settings";
$TEXT{'groups_id'} = "Group ID";
$TEXT{'groups_name'} = "Group Name";
$TEXT{'groups_actions'} = "Actions";
$TEXT{'groups_delete?'} = "Are you sure you want to delete the group ?";
$TEXT{'groups_add'} = "Add Group";
$TEXT{'groups_reset'} = "Reset";
$TEXT{'groups_deleted'} = "Group Deleted Succesfully";
$TEXT{'groups_added'} = "Group Added Succesfully";



#### Security ####
$TEXT{'security'} = "Security";
$TEXT{'access_control'} = "Access Control";
$TEXT{'security_help'} = "";
$TEXT{'enter_ip_or_network'} = "Enter the IP address or network from with the connections to this server will be allowed or rejected";
$TEXT{'error_security_demo'} = "Can't change ACL in a demo site";
