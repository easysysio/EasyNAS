
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

$TEXT{'easynas'} = "EasyNAS";
$TEXT{'yariv'} = "Yariv Hakim";
$TEXT{'username'} = "用户名";
$TEXT{'password'} = "密码";
$TEXT{'please_wait'} = "请等待....";
$TEXT{'not_authorized'} = "你未被授权使用这个功能";
$TEXT{'edit'} = "编辑";
$TEXT{'delete'} = "删除";
$TEXT{'about'} = "关于";
$TEXT{'save'} = "保存";
$TEXT{'reset'} = "重置";
$TEXT{'create'} = "创建";
$TEXT{'add'} = "增加";
$TEXT{'web_system'} = "系统";
$TEXT{'web_storage'} = "存储";
$TEXT{'web_users'} = "用户 / 组群";
$TEXT{'web_sharing'} = "文件共享";
$TEXT{'web_services'} = "网络服务";
$TEXT{'web_applications'} = "应用";
$TEXT{'index_help'} = "
<h1><center>EasyNAS</center></h1><br>
<h3><center>$firmware_ver</center></h3><br><br>
<center>版权 &copy; 2013-2017</center><br>
<h4><center><a href=\"http://www.easynas.org\"  target=\"new\" >http://www.easynas.org</a></center><h4>";

#### Search ####
$TEXT{'search'} = "查找";
$TEXT{'search_help'} = "
Search menu allows you to search a text in one of the following seections:<br><br>
File System Manager<br>
Volume Manager<br>
Users<br>
Groups<br><br>
You will see only the raws that contain your search<br>
and you will be able to do any of the action like in the regular menus.";

#### System Info ####
$TEXT{'sysinfo'} = "系统信息";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "供应商";
$TEXT{'model'} = "型号";
$TEXT{'cache_size'} = "缓存";
$TEXT{'speed'} = "速度";
$TEXT{'system'} = "系统";
$TEXT{'os'} = "操作系统";
$TEXT{'architecture'} = "架构";
$TEXT{'firmware'} = "固件";
$TEXT{'filesystem'} = "文件系统";
$TEXT{'memory'} = "内存";
$TEXT{'total_memory'} = "总内存";
$TEXT{'free_memory'} = "可用内存";
$TEXT{'total_swap_memory'} = "总虚拟内存";
$TEXT{'free_swap_memory'} = "可用虚拟内存";
$TEXT{'storage'} = "存储";
$TEXT{'sysinfo_help'} = "<p>This menu shows the system information like CPU, Memeory, Installed OS and Storage<p>";

#### Settings ####
$TEXT{'general_settings'} = "基本设置";
$TEXT{'bad_system_port'} = "无效系统端口";
$TEXT{'bad_secure_port'} = "无效安全端口t";
$TEXT{'bad_web_port'} = "无效Web端口";
$TEXT{'settings'} = "设置";
$TEXT{'date_time'} = "日期 / 时间";
$TEXT{'access_list'} = "访问列表";
$TEXT{'host_name'} = "主机名";
$TEXT{'system_port'} = "系统端口";
$TEXT{'secure_port'} = "系统安全端口";
$TEXT{'change_settings_in_progress'} = "正在改变设置....";
$TEXT{'certificate'} = "证书";
$TEXT{'cert_details'} = "证书详情";
$TEXT{'no_cert'} = "证书没找到";
$TEXT{'upload'} = "上传";
$TEXT{'error_updating_date'} = "日期 / 时间错误";
$TEXT{'error_settings_demo'} = "演示版网站不能改变设置";
$TEXT{'settings_help'} = "<p>This menu allows you to change the general settings of the NAS functionality. <br> 
Changing any setting will be saved even after system restarrt. <br><br>
Change the following settings: <br><br>
Host name - the name of the NAS in the network. <br>
System Port - the port number this managment GUI will be listening to. <br>
Date - the current date. <br>
Time - The current time <br>
Access List - Allows prevent unauthorized access to the web managment GUI.<br>
Certificate - Allows to change the default SSL certificate. </p>"; 

#### Backup ####
$TEXT{'backup_restore'} = "备份 & 还原";
$TEXT{'backup'} = "备份";
$TEXT{'restore'} = "还原";
$TEXT{'file_name'} = "文件名";
$TEXT{'backup_failed'} = "备份失败";
$TEXT{'backup_completed'} = "备份成功完成";
$TEXT{'restore_failed'} = "还原失败";
$TEXT{'testore_completed'} = "还原完成";
$TEXT{'backup_help'} = "Backup and restore your settings to allow easy migration<br>
                        To backup settings - enter a filename, select the volume where this backup will reside<br>
                                             press backup to save the settings.<br>
                        To restore settings - enter filename, select the volume where the backup exists<br> 
					     press restore to restore the setting.<br>";
#### Network settings ####
$TEXT{'network_setting'} = "网络设置";
$TEXT{'error_ip_demo'} = "演示网站不能改变IP地址";
$TEXT{'network_restart'} = "重启 EasyNAS 服务器才生效.";
$TEXT{'network_help'} = "
This menu will help you change the network setting to your network cards. <br>
Select an interface to setup the ip parameters. <br><br><br>
Note: The same settings can also be changed in the console.";

#### Scheduler ##########
$TEXT{'scheduler'} = "计划";
$TEXT{'snapshots'} = "快照";
$TEXT{'syncs'} = "远程同步";
$TEXT{'scrubs'} = "文件系统清理";
$TEXT{'powers'} = "电源控制";
$TEXT{'create_sc'} = "创建计划";
$TEXT{'schedule_snapshot'} = "快照计划";
$TEXT{'schedule_sync'} = "远程同步计划";
$TEXT{'schedule_scrub'} = "清理计划";
$TEXT{'schedule_power'} = "电源控制计划";
$TEXT{'no_vol_selected'} = "没有卷被选中";
$TEXT{'sc_exists'} = "计划名字已经存在";
$TEXT{'control_type'} = "控制类型";
$TEXT{'error_restarting_sc'} = "重启计划错误";
$TEXT{'delete_sc'} = "删除计划";
$TEXT{'error_deleting_sc'} = "删除计划错误";
$TEXT{'update_sc'} = "更新计划"; 
$TEXT{'sc_name'} = "计划名字";
$TEXT{'remote_system'} = "远程系统";
$TEXT{'time'} = "时间";
$TEXT{'date'} = "日期";
$TEXT{'day_of_week'} = "星期";
$TEXT{'sc'} = "计划";
$TEXT{'scs'} = "计划";
$TEXT{'sc_name'} = "名字";
$TEXT{'sc_task'} = "任务";
$TEXT{'vol_name'} = "卷名";
$TEXT{'fs_name'} = "文件系统名";
$TEXT{'fs_delete'} = "删除文件系统";
$TEXT{'weekday'} = "星期";
$TEXT{'delete_sc?'} = "你确定要删除计划吗？";
$TEXT{'schedule_help'} = "
Scheduler can create tasks on a timly manner<br>
create a scheule every Day, Month, Year, Time, Day of the week or any combiantion between them<br>
Type of schedules that can be created:<br>
Snapshot -The snapshot will be created automaticaly with the name:  volume.date<br>
Scrub - finding errors on the FileSystem and fixing it";

### NETWORK ###
$TEXT{'network_settings'} = "网络设置";
$TEXT{'network_interfaces'} = "网络接口";
$TEXT{'interface'} = "接口";
$TEXT{'state'} = "状态";
$TEXT{'broadcast'} = "广播地址";
$TEXT{'net_mask'} = "掩码";
$TEXT{'hardware_mac'} = "MAC地址";
$TEXT{'dhcp'} = "DHCP";
$TEXT{'static'} = "静态";
$TEXT{'ip_address'} = "IP地址";
$TEXT{'subnet_mask'} = "子网掩码";
$TEXT{'gateway'} = "网关";
$TEXT{'domain'} = "域";
$TEXT{'pri_dns'} = "主DNS";
$TEXT{'sec_dns'} = "备DNS";
$TEXT{'state_up'} = "有效";
$TEXT{'state_down'} = "无效";
$TEXT{'error_ip_demo'} = "不能改变IP在演示网站";
$TEXT{'network_restart'} = "网络重启";
$TEXT{'network_help'} = "
This menu will help you change the network setting to your network cards. <br>
Select an interface to setup the ip parameters. <br><br><br>
Note: The same settings can also be changed in the console.";

### Resource Monitor ###
$TEXT{'resource_monitor'} = "资源监控";
$TEXT{'cpu'} = "CPU";
$TEXT{'memory'} = "内存";
$TEXT{'disk_io'} = "磁盘IO";
$TEXT{'network_band'} = "网络带宽";
$TEXT{'resources_help'} = "
Resource Monitor menu will monitor the system cpu,memory,disk and network.";



#### Power Managment ####
$TEXT{'power_management'} = "电源管理";
$TEXT{'shutdown_restart'} = "关机 / 重启";
$TEXT{'error_restart_demo'} = "不能重启演示网站";
$TEXT{'restart_system'} = "重启系统......";
$TEXT{'error_shutdown_demo'} = "不能关闭演示网站";
$TEXT{'shutdown_system'} = "系统关机.....";
$TEXT{'execute_immediately'} = "立刻执行系统重启/关机.";
$TEXT{'restart'} = "重启";
$TEXT{'shutdown'} = "关机";
$TEXT{'power_help'} = "Use this menu to Shutdown or Restart your NAS";

#### Firmware ####
$TEXT{'firmware_upgrade'} = "固件升级";
$TEXT{'firmware'} = "固件";
$TEXT{'component'} = "说明";
$TEXT{'author'} = "作者";
$TEXT{'version'}="版本";
$TEXT{'installed_version'} = "已安装版本";
$TEXT{'current_version'} = "当前版本";
$TEXT{'install'} = "安装";
$TEXT{'upgrade'} = "升级";
$TEXT{'uninstall'} = "卸载";
$TEXT{'install_addon'} = "安装插件";
$TEXT{'uninstall_addon'} = "卸载插件";
$TEXT{'upgrade_addon'} = "升级插件";
$TEXT{'check_for_update'} = "检查更新";
$TEXT{'cheking_firmware_availble'} = "检查有效的固件: ";
$TEXT{'latest_firmware'} = "你的系统固件已经最新";
$TEXT{'download_latest_version_here'} = "下载最新版在 <a href=http://www.easynas.org/download target=New_Page>here</a>";
$TEXT{'upgrade_in_progress'} = "升级中.........";
$TEXT{'downloading_firmware'} = "下载固件.......";
$TEXT{'installing_new_firmware'} = "安装新固件......";
$TEXT{'firmware_upgraded'}="固件更新了";
$TEXT{'error_upgrading'}="升级错误，请稍后再尝试";
$TEXT{'error_connecting'}="连接 EasyNAS 错误, 请稍后再尝试";
$TEXT{'failed_to_refresh_repo'}="刷新失败 EasyNAS 更新库";
$TEXT{'failed_to_install_addon'} = "安装插件失败";
$TEXT{'refresh_repo'}="刷新更新库";
$TEXT{'failed_to_delete_addon'} = "删除插件失败";
$TEXT{'firmware_help'} = "
Firware upgrade feature will allow you to upgrade any new minor version. <br>
Your current version will be checked agains EasyNAS latest version, and let you know if an upgrade is available. <br>
The upgrade requires direct internet connection. No restart is needed after upgrade. <br>
Major version will usually include kernel upgrade, so new install will be required."; 

#### Disk ####
$TEXT{'free'} = "可用";
$TEXT{'used'} = "已使用";
$TEXT{'system'} = "系统";
$TEXT{'failed'} = "失败";
$TEXT{'disk_manager'} = "磁盘管理";
$TEXT{'disk_performace'} = "磁盘性能";
$TEXT{'testing'} = "测试中";
$TEXT{'rerun_test'} = "再运行测试";
$TEXT{'disk_performance_help'} = "磁盘性能测试将检查磁盘的读性能.";
$TEXT{'error_updating_param'} = "更新磁盘性能错误";
$TEXT{'error_formating_disk'} = "格式化磁盘错误";
$TEXT{'physical_disks'} = "物理盘";
$TEXT{'disk'} = "磁盘";
$TEXT{'size'} = "容量";
$TEXT{'status'} = "状态";
$TEXT{'model_number'} = "型号";
$TEXT{'serial_number'} = "序列号";
$TEXT{'firmware_version'} = "固件版本";
$TEXT{'actions'} = "作用";
$TEXT{'disk_format_are_u_sure'} = "你确定要格式化磁盘吗？数据将会丢失。";
$TEXT{'disk_format'} = "格式化";
$TEXT{'test_performance'} = "测试性能";
$TEXT{'disk_distribution'} = "磁盘使用情况";
$TEXT{'disk_settings'} = "磁盘设置";
$TEXT{'multi_count'} = "多计数:";
$TEXT{'io_supprt'} = "IO 支持:";
$TEXT{'read_only'} = "只读:";
$TEXT{'read_ahead'} = "预读:";
$TEXT{'disk_help1'} = "选择一个磁盘并改变它的默认设置";
$TEXT{'disk_help2'} = "
Change the disk setting: <br><br>
Read Ahead -  sector count for filesystem (software) read-ahead. <br>
This is  used  to  improve  performance  in sequential reads of large
files, by prefetching additional blocks in anticipation of  them
being  needed  by the running task.  Many IDE drives also have a
separate  built-in  read-ahead  function,  which  augments  this
filesystem (software) read-ahead function.";

#### File System ####
$TEXT{'fs'} = "文件系统";
$TEXT{'fs_manager'} = "文件系统管理";
$TEXT{'remove_hd'} = "删除硬盘";
$TEXT{'failed_to_remove_hd'} = "删除硬盘失败";
$TEXT{'add_hd'} = "增加磁盘";
$TEXT{'failed_to_add_HD'} = "增加硬盘失败";
$TEXT{'repair_hd'} = "修复硬盘";
$TEXT{'fs_need_to_be_unmounted'} = "文件系统需要重新加载";
$TEXT{'check&repair_hd'} = "检查并修复硬盘 HD";
$TEXT{'create_fs'} = "创建文件系统";
$TEXT{'no_disks_were_selected'} = "为选择磁盘";
$TEXT{'create_fs'} = "创建文件系统";
$TEXT{'no_fs_name_was_entered'} = "没有输入文件系统名字";
$TEXT{'reserved_fs'} = "ROOT 是保留的名字";
$TEXT{'raid_0_require_two'} = "Raid 0 最少需要2个驱动器";
$TEXT{'raid_1_require_two'} = "Raid 1 最少需要2个驱动器";
$TEXT{'raid_10_require_four'} = "Raid 10 最少需要4个驱动器";
$TEXT{'raid_5_require_three'} = "Raid 5 最少需要3个驱动器";
$TEXT{'raid_6_require_four'} = "Raid 6 最少需要4个驱动器";
$TEXT{'failed_creating_directory'} = "创建目录失败.";
$TEXT{'failed_creating_fs'} = "创建文件系统失败.";
$TEXT{'failed_mounting_fs'} = "加载文件系统失败.";
$TEXT{'mount_fs'} = "加载文件系统";
$TEXT{'unmount_fs'} = "卸载文件系统";
$TEXT{'failed_unmounting_fs'} = "卸载文件系统失败.";
$TEXT{'create_fs'} = "创建文件系统";
$TEXT{'no_free_disk'} = "没有可用磁盘空间";
$TEXT{'fs_name'} = "名字";
$TEXT{'raid_profile'} = "Raid 描述";
$TEXT{'compression'} = "压缩";
$TEXT{'disks'} = "磁盘";
$TEXT{'ssd_optimization'} = "SSD 优化";
$TEXT{'auto_mount'} = "自动加载";
$TEXT{'auto_defrag'} = "自动碎片整理";
$TEXT{'mount_option'} = "加载选项";
$TEXT{'file_system_name'} = "文件系统名";
$TEXT{'raid_level'} = "Raid 级别";
$TEXT{'raid_profile'} = "Raid 说明";
$TEXT{'force_raid_change'} = "Raid 强力改变";
$TEXT{'change_raid'} = "改变 Raid";
$TEXT{'fs_mount_options'} = "加载选项";
$TEXT{'fs_disks'} = "磁盘";
$TEXT{'number'} = "数";
$TEXT{'disk'} = "磁盘";
$TEXT{'total_size'} = "总空间";
$TEXT{'used'} = "使用的";
$TEXT{'status'} = "状态";
$TEXT{'remove_hd?'} = "你确定删除硬盘吗？";
$TEXT{'repair_hd?'} = "你确定修复硬盘吗？";
$TEXT{'add_hd'} = "增加硬盘";
$TEXT{'no_free_disks_available'} = "无可用磁盘空间";
$TEXT{'drives'} = "驱动器";
$TEXT{'create_fs'} = "创建文件系统";
$TEXT{'fs_limit'} = "文件系统配额限制";
$TEXT{'0_no_limit'} = "(输入 0 等于不限制)";
$TEXT{'failed_limit'} = "文件系统上的配额失败";
$TEXT{'fs_help1'} = "
A FileSystem consist one or more disks. <br>
Each FileSystem can have features like: Compression, Redundency and Availability. <br>
FileSystem can't be deleted if it cointains volumes.";
$TEXT{'fs_help2'} = "
Add a new FileSystem <br><br>
FileSystem Name - the name of the Filesystem <br> 	
Raid Profile - Considering the performance gain and extra redundancy, choose the Raid level you want:<br>
JBOD (Just Bunch Of Disks): Flexibility without redundancy <br>
RAID 0 (Disk Striping): performance gain but without redundancy <br>
RAID 1: (Disk Mirroring): allows one disk failure <br>
RAID 10 (Disk Mirroring and Striping): allows one disk failure from each RAID 1 pair <br>
RAID 5 (Disk Striping with parity): allows one disk failure <br>
RAID 6 (Disk Striping with double parity): allows two disk failure <br>
Compression -  Reduce the size of data with selecting: Better, Faster or None <br>
Disks - list of available disk that can be used to this FileSystem <br>
SSD Optimization - When using SSD drive, this option will optimize the use for longer life <br> 
Auto Defrag - Will detect random writes into existing files and kick off background defragging. <br>
Auto Mount - This option will auto mount the Filesystem";	
$TEXT{'fs_help3'} = "
Change the file system settings:<br><br>
Change Name -  Change the links and name of the filesystem and any volumes connected to it.<br>
Change Raid -  Change the raid level the filesystem has. In case there is a reduce in the integrity, you must select the force raid change. <br>
Mount Options - Mount or unmount a filesystem with or without compression or SSD Optimization.<br>
File System Disks - Balance, fix,  tune or remove a disk from the file system disks pool.<br>";

#### Volumes ####
$TEXT{'vol_manager'} = "卷管理";
$TEXT{'create_vol'} = "创建卷";
$TEXT{'no_vol_name'} = "没有输入卷名";
$TEXT{'no_fs_selected'} = "未选择文件系统";
$TEXT{'delete_vol'} = "删除卷";
$TEXT{'faild_to_delete_vol'} = "删除卷失败";
$TEXT{'create_snapshot'} = "创建快照";
$TEXT{'no_snapshot_name'} = "未输入快照名字";
$TEXT{'failed_to_add_snapshot'} = "增加快照失败";
$TEXT{'failed_to_change_owner'} = "改变所有者失败";
$TEXT{'failed_to_change_permission'} = "修改权限失败";
$TEXT{'vol_name'} = "卷名";
$TEXT{'user_owner'} = "用户所有者";
$TEXT{'group_owner'} = "组所有者";
$TEXT{'user_permission'} = "用户权限";
$TEXT{'group_permission'} = "组权限";
$TEXT{'others_permission'} = "其他权限";
$TEXT{'snapshot_name'} = "快照名";
$TEXT{'vols'} = "卷";
$TEXT{'vol'} = "卷";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "卷名";
$TEXT{'size'} = "空间";
$TEXT{'delete_vol?'} = "你确定删除卷吗？";
$TEXT{'no_schedule_name'} = "未输入计划名.";
$TEXT{'failed_add_vol'} = "增加卷失败.";
$TEXT{'vol_help1'} = "
One or more volumes can be created on a FileSystem <br>
The volume will inherite the FileSystem features like: compression, redunduncy, availabity. <br>
The volume will be available only if the FileSystem will be mounted.";
$TEXT{'vol_help2'} = "
Add or change the following settings:<br><br>
User & Group Owner will determine who can read & write files<br>
Files Permission will determin what will be the user, group or other permission.<br>
File System Quota will limit the max amount of storage";

#### Sync ####
$TEXT{'sync'} = "同步卷";
$TEXT{'hostname'} = "主机名";
$TEXT{'rdir'} = "远程目录";
$TEXT{'password'} = "密码";
$TEXT{'sync_option'} = "同步选项";
$TEXT{'sync_complete'} = "同步完成";
$TEXT{'failed_to_sync'} = "同步失败";
$TEXT{'sync_could_not_connect'} = "不能连接到同步服务器";
$TEXT{'sync_bad_user_password'} = "同步失败，用户名或者密码错误";
$TEXT{'no_hostname'} = "主机名未输入";
$TEXT{'no_rdir'} = "远程目录没有输入";
$TEXT{'no_vol'} = "未选择卷";
$TEXT{'sync_help'} = "
Use the Sync option to copy from a remote rsync daemon a complete directory<br>
use the following parameters:<br><br>
Host name - the IP or host name of the remote server<br>
Remote Directory - the directory name from the remote server you are going to sync from.<br>
Username - the remote username<br>
Password - the remote password<br>
File System / Volume - the volume name you want to copy the data to<br>
Sync option - the protocol to use for sync<br><br>
Note: the remote server myst have Rsync installed to use this option";

#### Users ####
$TEXT{'users_manager'} = "用户管理";
$TEXT{'create_user'} = "创建用户";
$TEXT{'passwords_do_not_match'} = "密码不匹配.";
$TEXT{'failed_to_add_user'} = "增加用户失败";
$TEXT{'failed_to_change_password'} = "改变密码失败";
$TEXT{'failed_to_add_samba_user'} = "增加用户失败";
$TEXT{'delete_user'} = "删除用户";
$TEXT{'user_admin_cant_be_delete'} = "admin 不能删除.";
$TEXT{'user_admin_cant_be_changed'} = "admin 不能改变.";
$TEXT{'failed_to_delete_user'} = "删除用户失败";
$TEXT{'cant_change_admin_password'} = "不能改变admin密码这是演示网站";
$TEXT{'passwords_do_not_match'} = "密码不匹配";
$TEXT{'password_must_exist'} = "密码必须";
$TEXT{'change_password'} = "改变密码";
$TEXT{'one_group_needed'} = "至少需要一个组";
$TEXT{'failed_to_change_samba_password'} = "修改密码失败";
$TEXT{'change_settings'} = "修改设置";
$TEXT{'failed_to_change_settings'} = "修改设置失败.";
$TEXT{'users'} = "用户";
$TEXT{'user_name'} = "用户名";
$TEXT{'name'} = "名字";
$TEXT{'desc'} = "描述";
$TEXT{'uid'} = "UID";
$TEXT{'group'} = "组";
$TEXT{'groups'} = "组群";
$TEXT{'password'} = "密码";
$TEXT{'password_again'} = "再次输入密码";
$TEXT{'easynas_admin'} = "EasyNAS Admin";
$TEXT{'delete_user?'} = "你确定删除用户吗？";
$TEXT{'user_settings'} = "用户设置";
$TEXT{'users_help'} = "使用这个菜单增加或删除账号.";
$TEXT{'password_help'}  = "使用这个菜单修改密码.";


#### Groups ####
$TEXT{'groups_manager'} = "组群管理";
$TEXT{'create_group'} = "创建组";
$TEXT{'failed_to_add_group'} = "增加组失败";
$TEXT{'delete_group'} = "删除组";
$TEXT{'group'} = "组";
$TEXT{'groups'} = "组群";
$TEXT{'can_not_deleted'} = "不能删除";
$TEXT{'failed_to_delete_group'} = "删除组失败";
$TEXT{'group_name'} = "组名";
$TEXT{'access_permission'} = "访问权限";
$TEXT{'groups_settings'} = "组群设置";
$TEXT{'gid'} = "GID";
$TEXT{'delete_group?'} = "你确定删除组吗？";
$TEXT{'groups_help'} = "
Use this menu to add/delete groups.<br>
Or to change group settings";
$TEXT{'groups_help2'} = "
Enter the group name and the roles this group will have access to:<br><br>
SYSTEM - General settings of the NAS.<br>
STORAGE - Allow to add/change/delete FileSystems and volumes<br>
USERS - Manage users and groups<br>
SHARING - Configure file sharing protocols<br>
SERVICES - Configure network services.";

#### Security ####
$TEXT{'security'} = "安全";
$TEXT{'access_control'} = "访问控制";
$TEXT{'security_help'} = "";
$TEXT{'enter_ip_or_network'} = "输入允许或者拒绝的IP地址或者网络";
$TEXT{'error_security_demo'} = "不能改变访问控制层（ACL），这是掩饰网站";
$TEXT{'security_help'} = "
Access Control<br><br>
Allow or deny access to the admin menu from IPs or networks<br><br>
Allow all connection:  anyone can access the admin menu. <br>
Deny connection from the list: anyone from the list can't access the admin menu, the rest can.<br>
Allow connection from the list: anyone from the list can access the admin menu, the rest can't.<br><br>
the IP/network list need to be in the following format:<br>
IP: xxx.yyy.zzz.www <br>
Subnet: xxx.yyy.zzz.www/[1-32]<br>";
