
# lang_chinese_easynas.pl
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
$TEXT{'please_wait'} = "请等待....";
$TEXT{'not_authorized'} = "你未被授权使用这个功能";
$TEXT{'edit'} = "编辑";
$TEXT{'delete'} = "删除";
$TEXT{'about'} = "关于";
$TEXT{'save'} = "保存";
$TEXT{'reset'} = "重置";
$TEXT{'create'} = "创建";
$TEXT{'add'} = "增加";
$TEXT{'easynas_url'} = "https://www.easynas.org";
$TEXT{'running'} = "运行于";
$TEXT{'close'} = "关闭";

#### Types ####
$TEXT{'storage'} = "存储";
$TEXT{'system'} = "系统";
$TEXT{'sharing'} = "文件共享";
$TEXT{'services'} = "服务";
$TEXT{'multimedia'} = "多媒体";
$TEXT{'realm'} = "域 (Realm)";


#####   Login #####
$TEXT{'login'} = "登录";
$TEXT{'login_to_easynas'} = "登录 EasyNAS";
$TEXT{'login_username'} = "用户名";
$TEXT{'login_password'} = "密码";
$TEXT{'login_remember_me'} = "记住我";

######  Dashboard ######
$TEXT{'dashboard'} = "仪表盘";
$TEXT{'dashboard_view_details'} = "查看详情";
$TEXT{'dashboard_update_available'} = "EasyNAS 及其附加组件有可用更新。";
$TEXT{'dashboard_update_here'} = "打开附加组件";
$TEXT{'dashboard_drives'} = "硬盘";
$TEXT{'dashboard_filesystems'} = "文件系统";
$TEXT{'dashboard_users'} = "用户";
$TEXT{'dashboard_volumes'} = "卷";
$TEXT{'dashboard_disk'} = "磁盘";
$TEXT{'dashboard_filesystem'} = "文件系统";
$TEXT{'dashboard_failed'} = "故障";
$TEXT{'dashboard_used'} = "已用";
$TEXT{'dashboard_system'} = "系统";
$TEXT{'dashboard_free'} = "空闲";
$TEXT{'dashboard_good'} = "良好";
$TEXT{'dashboard_degreded'} = "已降级";
$TEXT{'dashboard_update_available'} = "EasyNAS 及其附加组件有可用更新。";
$TEXT{'dashboard_click_here'} = " 点击此处更新";
$TEXT{'dashboard_cpu'} = "CPU";
$TEXT{'dashboard_cores'} = "核心";
$TEXT{'dashboard_load'} = "负载";
$TEXT{'dashboard_memory'} = "内存";
$TEXT{'dashboard_memory_available'} = "可用";
$TEXT{'dashboard_swap'} = "交换分区";

#### Search ####
$TEXT{'search'} = "查找";

#### System Info ####
$TEXT{'sysinfo'} = "系统信息";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "供应商";
$TEXT{'model'} = "型号";
$TEXT{'cache_size'} = "缓存";
$TEXT{'speed'} = "速度";
$TEXT{'os'} = "操作系统";
$TEXT{'architecture'} = "架构";
$TEXT{'firmware'} = "固件";
$TEXT{'filesystem'} = "文件系统";
$TEXT{'memory'} = "内存";
$TEXT{'total_memory'} = "总内存";
$TEXT{'free_memory'} = "可用内存";
$TEXT{'total_swap_memory'} = "总虚拟内存";
$TEXT{'free_swap_memory'} = "可用虚拟内存";

#### Settings ####
$TEXT{'settings'} = "设置";
$TEXT{'settings_date_time'} = "日期 / 时间";
$TEXT{'settings_date'} = "日期";
$TEXT{'settings_time'} = "时间";
$TEXT{'settings_date_help'} = "仅在未使用 NTP 时手动设置；否则 NTP 会重新同步时钟。";
$TEXT{'settings_date_set'} = "日期和时间已更新。";
$TEXT{'settings_cert'} = "证书";
$TEXT{'settings_cert_current'} = "当前证书";
$TEXT{'settings_cert_file'} = "证书 (PEM)";
$TEXT{'settings_key_file'} = "私钥（PEM，可选）";
$TEXT{'settings_cert_help'} = "上传匹配的证书和私钥。Web 服务器将重启以应用。";
$TEXT{'settings_cert_uploaded'} = "证书已上传。正在重启以应用...";
$TEXT{'no_cert'} = "证书没找到";
$TEXT{'settings_repo'} = "软件仓库";
$TEXT{'settings_hostname'} = "主机名";
$TEXT{'settings_port'} = "端口";
$TEXT{'settings_save'} = "保存";
$TEXT{'settings_reset'} = "重置";
$TEXT{'settings_bad_port'} = "无效的端口";
$TEXT{'settings_saved'} = "新设置已保存。可能需要重启才能生效。";

$TEXT{'change_settings_in_progress'} = "正在改变设置....";
$TEXT{'cert_details'} = "证书详情";
$TEXT{'no_cert'} = "证书没找到";
$TEXT{'bad_cert'} = "无效的证书";
$TEXT{'upload'} = "上传";
$TEXT{'error_updating_date'} = "日期 / 时间错误";
$TEXT{'error_settings_demo'} = "演示版网站不能改变设置";
$TEXT{'enabled'} = "已启用";
$TEXT{'disabled'} = "已禁用";
$TEXT{'enable'} = "启用";
$TEXT{'disable'} = "禁用";

#### User Profile ####
$TEXT{'user_profile'} = "用户资料";


#### Backup ####
$TEXT{'backup_restore'} = "备份 & 还原";
$TEXT{'backup'} = "备份";
$TEXT{'restore'} = "还原";
$TEXT{'file_name'} = "文件名";
$TEXT{'backup_failed'} = "备份失败";
$TEXT{'backup_completed'} = "备份成功完成";
$TEXT{'restore_failed'} = "还原失败";
$TEXT{'testore_completed'} = "还原完成";

#### Network settings ####
$TEXT{'network_setting'} = "网络设置";
$TEXT{'network_interface'} = "网络接口";
$TEXT{'network_type'} = "类型";
$TEXT{'network_state'} = "状态";
$TEXT{'network_speed'} = "速度";
$TEXT{'network_connection_type'} = "连接类型";
$TEXT{'network_ip'} = "IP 地址";
$TEXT{'network_subnet'} = "子网掩码";
$TEXT{'network_gateway'} = "网关";
$TEXT{'network_dns1'} = "首选 DNS";
$TEXT{'network_dns2'} = "备用 DNS";
$TEXT{'network_domain'} = "域";
$TEXT{'network_actions'} = "操作";
$TEXT{'network_edit'} = "编辑";
$TEXT{'network_static'} = "静态";
$TEXT{'network_dhcp'} = "DHCP";
$TEXT{'network_saved'} = "IP 地址已更改";
$TEXT{'network_failed_to_save'} = "更改 IP 设置失败";
$TEXT{'network_manager_down'} = "网络管理器未运行";
$TEXT{'network_settings_can_not_change'} = "无法更改网络设置";
$TEXT{'network_click_here_to_activate'} = "点击此处激活";

$TEXT{'error_ip_demo'} = "不能改变IP在演示网站";
$TEXT{'network_restart'} = "网络重启";


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
$TEXT{'sc_name'} = "名字";
$TEXT{'remote_system'} = "远程系统";
$TEXT{'time'} = "时间";
$TEXT{'date'} = "日期";
$TEXT{'day_of_week'} = "星期";
$TEXT{'sc'} = "计划";
$TEXT{'scs'} = "计划";
$TEXT{'sc_name'} = "名字";
$TEXT{'sc_task'} = "任务";
$TEXT{'vol_name'} = "卷名";
$TEXT{'fs_name'} = "名字";
$TEXT{'fs_delete'} = "删除文件系统";
$TEXT{'weekday'} = "星期";
$TEXT{'delete_sc?'} = "你确定要删除计划吗？";

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

#### Realm ####
$TEXT{'computers'} = "计算机";
$TEXT{'computers_manager'} = "计算机管理";


#### Monitor ####
$TEXT{'cpu'} = "CPU";
$TEXT{'memory'} = "内存";
$TEXT{'disk_io'} = "磁盘IO";
$TEXT{'network_band'} = "网络带宽";


#### Power Managment ####
$TEXT{'power_management'} = "电源管理";
$TEXT{'shutdown_restart'} = "关机 / 重启";
$TEXT{'power_restart'} = "重启";
$TEXT{'power_shutdown'} = "关机";
$TEXT{'power_restarting'} = "设备正在重启...";
$TEXT{'power_shuttingdown'} = "设备正在关机...";
$TEXT{'power_restart_confirm'} = "现在重启设备吗？";
$TEXT{'power_shutdown_confirm'} = "现在关闭设备吗？";
$TEXT{'error_restart_demo'} = "不能重启演示网站";
$TEXT{'restart_system'} = "重启系统......";
$TEXT{'error_shutdown_demo'} = "不能关闭演示网站";
$TEXT{'shutdown_system'} = "系统关机.....";
$TEXT{'execute_immediately'} = "立刻执行系统重启/关机.";
$TEXT{'restart'} = "重启";
$TEXT{'shutdown'} = "关机";
$TEXT{'close_service'} = "正在停止服务.....";
$TEXT{'close_fs'} = "正在卸载文件系统.....";
$TEXT{'restart_are_u_sure'} = "确定要重启吗？";
$TEXT{'restart_help'} = "您即将重启 EasyNAS<br>请保存所有文件并关闭打开的服务<br><br>准备好后请点击重启";
$TEXT{'shutdown_help'} = "您即将关闭 EasyNAS<br>请保存所有文件并关闭打开的服务<br><br>准备好后请点击关机";

#### Firmware ####
$TEXT{'firmware'} = "固件";
$TEXT{'firmware_name'} = "名称";
$TEXT{'firmware_desc'} = "描述";
$TEXT{'firmware_new'} = "新版本";
$TEXT{'firmware_current'} = "当前版本";
$TEXT{'firmware_actions'} = "操作";
$TEXT{'firmware_update_r_u_sure'} = "确定要更新吗？";
$TEXT{'firmware_update'} = "更新";
$TEXT{'firmware_update_available'} = "有可用的新更新";
$TEXT{'firmware_here'} = " 点击此处更新";
$TEXT{'firmware_refresh'} = "刷新";
$TEXT{'firmware_refreshed'} = "软件仓库已刷新";
$TEXT{'firmware_noupdate'} = "没有可用更新";
$TEXT{'firmware_update_success'} = "更新成功完成";
$TEXT{'firmware_update_failed'} = "更新失败";
$TEXT{'firmware_updating'} = "系统更新正在后台运行...";
$TEXT{'firmware_phase_down'} = "下载中";
$TEXT{'firmware_phase_inst'} = "安装中";
$TEXT{'firmware_phase_prep'} = "准备中";

#### Addons #####
$TEXT{'addons'} = "附加组件";
$TEXT{'addons_sharing'} = "文件共享";
$TEXT{'addons_storage'} = "存储与备份";
$TEXT{'addons_multimedia'} = "多媒体";
$TEXT{'addons_services'} = "服务";
# Addon grid category labels, keyed by package group code (easynas-<group>-*).
$TEXT{'addons_fs'} = "文件共享";
$TEXT{'addons_mm'} = "多媒体";
$TEXT{'addons_srv'} = "服务";
$TEXT{'addons_stg'} = "存储";
$TEXT{'addons_easynas'} = "EasyNAS";
$TEXT{'addons_lang'} = "语言";
$TEXT{'addons_other'} = "其他应用";
$TEXT{'addons_name'} = "组件名称";
$TEXT{'addons_version'} = "版本";
$TEXT{'addons_update'} = "更新";
$TEXT{'addons_delete'} = "删除";
$TEXT{'addons_status'} = "状态";
$TEXT{'addons_desc'} = "描述";
$TEXT{'addons_actions'} = "操作";
$TEXT{'addons_install'} = "安装";
$TEXT{'addons_delete'} = "删除";
$TEXT{'addons_update'} = "更新";
$TEXT{'addons_install?'} = "安装该组件？";
$TEXT{'addons_update?'} = "更新该组件？";
$TEXT{'addons_delete?'} = "删除该组件？";
$TEXT{'addons_info'} = "信息";
$TEXT{'addons_installed'} = "组件安装成功";
$TEXT{'addons_not_installed'} = "组件安装出错";
$TEXT{'addons_notinst'} = "未安装";
$TEXT{'addons_deleted'} = "组件删除成功";
$TEXT{'addons_not_deleted'} = "组件删除出错";
$TEXT{'addons_updated'} = "组件更新成功";
$TEXT{'addons_not_updated'} = "组件更新出错";
$TEXT{'addons_close'} = "关闭";
$TEXT{'addons_details'} = "详情";
$TEXT{'addons_version'} = "版本";
$TEXT{'addons_nodesc'} = "暂无描述。";


$TEXT{'firmware_upgrade'} = "固件升级";
$TEXT{'lang'} = "语言";
$TEXT{'other_apps'} = "其他应用";
$TEXT{'component'} = "说明";
$TEXT{'author'} = "作者";
$TEXT{'version'} = "版本";
$TEXT{'current_version'} = "当前版本";
$TEXT{'new_version'} = "新版本";
$TEXT{'package_name'} = "软件包名称";
$TEXT{'update'} = "更新";
$TEXT{'refresh'} = "刷新";
$TEXT{'refresh_failed'} = "刷新失败";
$TEXT{'installed_version'} = "已安装版本";
$TEXT{'current_version'} = "当前版本";
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
$TEXT{'firmware_upgraded'} = "固件更新了";
$TEXT{'error_upgrading'} = "升级错误，请稍后再尝试";
$TEXT{'error_connecting'} = "连接 EasyNAS 错误, 请稍后再尝试";
$TEXT{'failed_to_refresh_repo'} = "刷新失败 EasyNAS 更新库";
$TEXT{'failed_to_install_addon'} = "安装插件失败";
$TEXT{'refresh_repo'} = "刷新更新库";
$TEXT{'failed_to_delete_addon'} = "删除插件失败";
$TEXT{'install_addon?'} = "安装该组件？";
$TEXT{'update_addon?'} = "更新该组件？";
$TEXT{'delete_addon?'} = "删除该组件？";
$TEXT{'update_all'} = "全部更新";
$TEXT{'firmware_refreshed'} = "软件仓库已刷新";
$TEXT{'firmware_not_refreshed'} = "刷新软件仓库出错";

#### Disk ####
$TEXT{'disk_manager'} = "磁盘管理";
$TEXT{'disk'} = "磁盘";
$TEXT{'disk_size'} = "容量";
$TEXT{'disk_status'} = "状态";
$TEXT{'disk_type'} = "类型";
$TEXT{'disk_health'} = "健康状况";
$TEXT{'disk_model'} = "型号";
$TEXT{'disk_serial'} = "序列号";
$TEXT{'disk_firmware'} = "固件";
$TEXT{'disk_actions'} = "操作";
$TEXT{'disk_free'} = "空闲";
$TEXT{'disk_used'} = "已用";
$TEXT{'disk_system'} = "系统";
$TEXT{'disk_bad'} = "损坏";
$TEXT{'disk_good'} = "良好";
$TEXT{'disk_format'} = "格式化";
$TEXT{'disk_settings'} = "磁盘设置";
$TEXT{'disk_format_success'} = "磁盘格式化成功";
$TEXT{'disk_format_failed'} = "磁盘格式化失败";
$TEXT{'disk_write_io_errs'} = "写入 IO 错误";
$TEXT{'disk_read_io_errs'} = "读取 IO 错误";
$TEXT{'disk_flush_io_errs'} = "刷写 IO 错误";
$TEXT{'disk_corruption_errs'} = "数据损坏错误";
$TEXT{'disk_generation_errs'} = "代数错误";
$TEXT{'disk_clean_errs'} = "清除错误计数";
$TEXT{'disk_clean_errs_success'} = "错误计数已清除";
$TEXT{'disk_clean_errs_failed'} = "清除错误计数失败";
$TEXT{'disk_close'} = "关闭";

#### File System ####
$TEXT{'fs'} = "文件系统";
$TEXT{'fs_create'} = "创建文件系统";
$TEXT{'fs_name'} = "名字";
$TEXT{'fs_raid_level'} = "RAID 级别";
$TEXT{'fs_compression'} = "压缩";
$TEXT{'fs_ssd_optimization'} = "SSD 优化";
$TEXT{'fs_auto_defrag'} = "自动碎片整理";
$TEXT{'fs_auto_mount'} = "自动挂载";
$TEXT{'fs_add'} = "添加文件系统";
$TEXT{'fs_reset'} = "重置";
$TEXT{'fs_used'} = "已用";
$TEXT{'fs_status'} = "状态";
$TEXT{'fs_drives'} = "硬盘";
$TEXT{'fs_health'} = "健康状况";
$TEXT{'fs_readonly'} = "只读";
$TEXT{'fs_read&write'} = "读写";
$TEXT{'fs_filesystem_contain_vol'} = "文件系统包含卷";
$TEXT{'fs_failed_changing_label'} = "无法更改文件系统标签";
$TEXT{'fs_invalid_name'} = "无效的名称：只能使用字母、数字、连字符和下划线";
$TEXT{'fs_busy'} = "文件系统仍在使用中（有打开的文件）。请关闭它们或重启共享服务后重试";
$TEXT{'fs_name_changed'} = "文件系统名称已更改";
$TEXT{'fs_umount_first'} = "更改名称前必须先卸载文件系统";
$TEXT{'fs_failed_formating_disk'} = "格式化磁盘失败";
$TEXT{'fs_failed_creating_dir'} = "创建目录失败";
$TEXT{'fs_failed_mounting'} = "挂载文件系统失败";
$TEXT{'fs_mounted'} = "文件系统已挂载";
$TEXT{'fs_size'} = "容量";
$TEXT{'fs_better'} = "更高压缩";
$TEXT{'fs_faster'} = "更快";
$TEXT{'fs_optimized'} = "均衡优化";
$TEXT{'fs_none'} = "无";
$TEXT{'fs_mount'} = "挂载";
$TEXT{'fs_unmount'} = "卸载";
$TEXT{'fs_delete?'} = "删除文件系统？";
$TEXT{'fs_change_settings'} = "更改设置";

$TEXT{'cancel'} = "取消";
$TEXT{'resume'} = "继续";
$TEXT{'snapshot'} = "快照";
$TEXT{'filesystems'} = "文件系统";
$TEXT{'fs_manager'} = "文件系统管理";
$TEXT{'better'} = "更高压缩";
$TEXT{'faster'} = "更快";
$TEXT{'none'} = "无";
$TEXT{'health'} = "健康状况";
$TEXT{'logs'} = "日志";
$TEXT{'good'} = "良好";
$TEXT{'degraded'} = "已降级";
$TEXT{'disk_errors'} = "磁盘错误";
$TEXT{'insufficient'} = "磁盘数量不足";
$TEXT{'remove_hd'} = "删除硬盘";
$TEXT{'replace_hd'} = "更换硬盘";
$TEXT{'source_hd'} = "源硬盘";
$TEXT{'target_hd'} = "目标硬盘";
$TEXT{'failed_to_remove_hd'} = "删除硬盘失败";
$TEXT{'fs_hd_removed'} = "硬盘移除成功";
$TEXT{'fs_hd_added'} = "硬盘添加成功";
$TEXT{'fs_hd_replaced'} = "硬盘更换成功";
$TEXT{'fs_failed_to_replace'} = "更换硬盘失败";
$TEXT{'add_hd'} = "增加硬盘";
$TEXT{'failed_to_add_HD'} = "增加硬盘失败";
$TEXT{'repair_hd'} = "修复硬盘";
$TEXT{'fs_need_to_be_unmounted'} = "文件系统需要重新加载";
$TEXT{'fs_need_to_be_mounted'} = "文件系统必须已挂载";
$TEXT{'check&repair_hd'} = "检查并修复硬盘 HD";
$TEXT{'create_fs'} = "创建文件系统";
$TEXT{'fs_deleted'} = "文件系统删除成功";
$TEXT{'no_disks_were_selected'} = "为选择磁盘";
$TEXT{'no_fs_name_was_entered'} = "没有输入文件系统名字";
$TEXT{'reserved_fs'} = "ROOT 是保留的名字";
$TEXT{'raid_0_require_two'} = "Raid 0 最少需要2个驱动器";
$TEXT{'raid_1_require_two'} = "Raid 1 最少需要2个驱动器";
$TEXT{'raid_10_require_four'} = "Raid 10 最少需要4个驱动器";
$TEXT{'raid_5_require_three'} = "Raid 5 最少需要3个驱动器";
$TEXT{'raid_6_require_four'} = "Raid 6 最少需要4个驱动器";
$TEXT{'raid_the_same'} = "RAID 级别相同，无需操作。";
$TEXT{'raid_require_force'} = "更改 RAID 级别会降低数据完整性，必须强制执行此更改。";
$TEXT{'raid_converting'} = "正在后台将文件系统转换为新的 RAID 级别，这可能需要一段时间。";
$TEXT{'fs_not_mounted'} = "执行此操作需要先挂载文件系统。";
$TEXT{'fs_balancing'} = "正在后台平衡文件系统。";
$TEXT{'fs_scrubbing'} = "校验 (Scrub) 已开始；正在检查文件系统。";
$TEXT{'fs_repairing'} = "修复已开始：校验将利用冗余数据重建损坏的块。";
$TEXT{'fs_removing_disk'} = "正在后台移除磁盘；数据正在迁移。";
$TEXT{'fs_disk_added'} = "磁盘已添加。请运行平衡以将数据分布到该磁盘。";
$TEXT{'fs_failed_adding_disk'} = "添加磁盘失败。";
$TEXT{'fs_replacing_disk'} = "正在后台更换磁盘。";
$TEXT{'fs_add_disk'} = "添加硬盘";
$TEXT{'fs_replace_disk'} = "更换硬盘";
$TEXT{'fs_replace_from'} = "要更换的磁盘";
$TEXT{'fs_select_disk'} = "选择空闲磁盘";
$TEXT{'fs_apply'} = "应用";
$TEXT{'failed_creating_directory'} = "创建目录失败.";
$TEXT{'failed_creating_fs'} = "创建文件系统失败.";
$TEXT{'failed_mounting_fs'} = "加载文件系统失败.";
$TEXT{'mount_fs'} = "加载文件系统";
$TEXT{'unmount_fs'} = "卸载文件系统";
$TEXT{'fs_failed_unmounting_fs'} = "卸载文件系统失败。";
$TEXT{'no_free_disk'} = "没有可用磁盘空间";
$TEXT{'raid_profile'} = "Raid 说明";
$TEXT{'compression'} = "压缩";
$TEXT{'disks'} = "磁盘";
$TEXT{'ssd_optimization'} = "SSD 优化";
$TEXT{'auto_mount'} = "自动加载";
$TEXT{'auto_defrag'} = "自动碎片整理";
$TEXT{'mount_option'} = "加载选项";
$TEXT{'file_system_name'} = "文件系统名";
$TEXT{'fs_raidlevel'} = "RAID 级别";
$TEXT{'raid_profile'} = "Raid 说明";
$TEXT{'force_raid_change'} = "Raid 强力改变";
$TEXT{'change_raid'} = "改变 Raid";
$TEXT{'fs_change_name'} = "更改名称";
$TEXT{'fs_mount_options'} = "加载选项";
$TEXT{'fs_disks'} = "磁盘";
$TEXT{'number'} = "数";
$TEXT{'disk'} = "磁盘";
$TEXT{'total_size'} = "总空间";
$TEXT{'status'} = "状态";
$TEXT{'remove_hd?'} = "你确定删除硬盘吗？";
$TEXT{'repair_hd?'} = "你确定修复硬盘吗？";
$TEXT{'check_repair_complete'} = "检查与修复已完成";
$TEXT{'add_hd'} = "增加硬盘";
$TEXT{'no_free_disks_available'} = "无可用磁盘空间";
$TEXT{'drives'} = "驱动器";
$TEXT{'fs_limit'} = "文件系统配额限制";
$TEXT{'0_no_limit'} = "(输入 0 等于不限制)";
$TEXT{'failed_limit'} = "文件系统上的配额失败";
$TEXT{'filesystem_contain_vol'} = "文件系统包含卷";
$TEXT{'filesystem_not_changed'} = "文件系统名称未更改";
$TEXT{'fs_created'} = "文件系统创建成功";

$TEXT{'fs_jbod_info'} = "JBOD（just a bunch of disks）将多块磁盘合并为一个逻辑卷，不提供冗余，也不做条带化。";
$TEXT{'fs_raid0_info'} = "RAID 0（条带化）将数据均匀分布到两块或更多磁盘上，没有奇偶校验和冗余。任何一块磁盘故障都会导致整个阵列失效，因为数据分布在所有磁盘上。";
$TEXT{'fs_raid1_info'} = "RAID 1 在两块或更多磁盘上保存完全相同的数据副本（镜像）；经典的 RAID 1 由两块磁盘组成。不提供奇偶校验和条带化。";
$TEXT{'fs_raid5_info'} = "RAID 5 采用块级条带化和分布式奇偶校验。单块磁盘故障后，可通过奇偶校验重建数据。RAID 5 至少需要三块磁盘。";
$TEXT{'fs_raid6_info'} = "RAID 6 在 RAID 5 基础上增加了第二个奇偶校验块：块级条带化，两个奇偶校验块分布在所有磁盘上。";
$TEXT{'fs_raid10_info'} = "RAID 10 结合镜像与条带化：数据条带化分布在镜像对上。每个镜像可容忍一块磁盘故障，至少需要四块磁盘。";

#### Volumes ####
$TEXT{'vol_manager'} = "卷管理";
$TEXT{'vol_create'} = "创建卷";
$TEXT{'vol_name'} = "卷名";
$TEXT{'vol_filesystem'} = "文件系统";
$TEXT{'vol_user_owner'} = "所有者（用户）";
$TEXT{'vol_group_owner'} = "所有者（组）";
$TEXT{'vol_no_vol_name'} = "未输入卷名称";
$TEXT{'vol_no_fs_selected'} = "未选择文件系统";
$TEXT{'vol_created'} = "卷创建成功";
$TEXT{'vol_id'} = "ID";
$TEXT{'vol_size'} = "容量";
$TEXT{'vol_fs'} = "文件系统";
$TEXT{'vol_actions'} = "操作";
$TEXT{'vol_delete'} = "删除卷";
$TEXT{'vol_delete?'} = "确定要删除该卷吗？";
$TEXT{'vol_faild_to_delete'} = "删除卷失败";
$TEXT{'vol_deleted'} = "卷删除成功";
$TEXT{'vol_snapshot'} = "快照";
$TEXT{'vol_settings'} = "设置";
$TEXT{'vol_permission'} = "卷权限";
$TEXT{'vol_user'} = "用户";
$TEXT{'vol_group'} = "组";
$TEXT{'vol_others'} = "其他";
$TEXT{'vol_readonly'} = "只读";
$TEXT{'vol_read&write'} = "读写";
$TEXT{'vol_deny'} = "拒绝";
$TEXT{'vol_reset'} = "重置";
$TEXT{'vol_save'} = "保存";
$TEXT{'vol_create_snapshot'} = "创建快照";
$TEXT{'vol_snapshot_name'} = "快照名称";
$TEXT{'vol_no_snapshot_name'} = "未输入快照名称";
$TEXT{'vol_failed_to_add_snapshot'} = "创建快照失败";
$TEXT{'vol_snapshot_created'} = "快照创建成功";
$TEXT{'vol_saved'} = "卷保存成功";
$TEXT{'vol_no_fs'} = "没有可用的文件系统";

$TEXT{'failed_to_change_owner'} = "改变所有者失败";
$TEXT{'failed_to_change_permission'} = "修改权限失败";
$TEXT{'group_owner'} = "组所有者";
$TEXT{'user_permission'} = "用户权限";
$TEXT{'group_permission'} = "组权限";
$TEXT{'others_permission'} = "其他权限";
$TEXT{'vols'} = "卷";
$TEXT{'vol'} = "卷";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "卷名";
$TEXT{'size'} = "空间";
$TEXT{'delete_vol?'} = "你确定删除卷吗？";
$TEXT{'no_schedule_name'} = "未输入计划名.";
$TEXT{'failed_add_vol'} = "增加卷失败.";
$TEXT{'group_created'} = "组创建成功";
$TEXT{'group_deleted'} = "组删除成功";


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

#### Users ####
$TEXT{'users_manager'} = "用户管理";
$TEXT{'users_create'} = "创建用户";
$TEXT{'users_id'} = "ID";
$TEXT{'users_name'} = "用户名";
$TEXT{'users_desc'} = "描述";
$TEXT{'users_groups'} = "组";
$TEXT{'users_actions'} = "操作";
$TEXT{'users_password'} = "密码";
$TEXT{'users_password_retype'} = "重复密码";
$TEXT{'users_created'} = "用户创建成功";
$TEXT{'users_deleted'} = "用户删除成功";
$TEXT{'users_add'} = "添加用户";
$TEXT{'users_reset'} = "重置";
$TEXT{'users_delete'} = "删除用户";
$TEXT{'users_settings'} = "设置";
$TEXT{'users_change_password'} = "更改密码";
$TEXT{'users_passwords_do_no_match'} = "两次输入的密码不一致";
$TEXT{'users_password_must_exist'} = "必须输入密码";
$TEXT{'users_user_must_exist'} = "必须输入用户";
$TEXT{'users_failed_to_add_user'} = "添加用户失败";
$TEXT{'users_failed_to_add_samba_user'} = "添加 Samba 用户失败";
$TEXT{'users_failed_to_add_samba_user'} = "添加 Samba 用户失败";
$TEXT{'users_failed_to_delete_user'} = "删除用户失败";
$TEXT{'users_delete?'} = "确定要删除该用户吗？";
$TEXT{'users_change_password'} = "更改密码";
$TEXT{'users_save_password'} = "保存密码";
$TEXT{'users_password_changed'} = "密码修改成功";
$TEXT{'users_save'} = "保存";
$TEXT{'users_settings_failed_to_save'} = "设置保存失败";
$TEXT{'users_settings_saved'} = "设置保存成功";


#### Groups ####
$TEXT{'groups_manager'} = "组群管理";
$TEXT{'groups_create'} = "创建组";
$TEXT{'groups_failed_to_add'} = "添加组失败";
$TEXT{'group_delete'} = "删除组";
$TEXT{'group'} = "组";
$TEXT{'groups'} = "组群";
$TEXT{'group_can_not_delete'} = "无法删除";
$TEXT{'groups_failed_to_delete'} = "删除组失败";
$TEXT{'group_name'} = "组名";
$TEXT{'access_permission'} = "访问权限";
$TEXT{'groups_settings'} = "组群设置";
$TEXT{'groups_id'} = "组 ID";
$TEXT{'groups_name'} = "组名称";
$TEXT{'groups_actions'} = "操作";
$TEXT{'groups_delete?'} = "确定要删除该组吗？";
$TEXT{'groups_add'} = "添加组";
$TEXT{'groups_reset'} = "重置";
$TEXT{'groups_deleted'} = "组删除成功";
$TEXT{'groups_added'} = "组添加成功";



#### Security ####
$TEXT{'security'} = "安全";
$TEXT{'access_control'} = "访问控制";
$TEXT{'security_help'} = " Access Control<br><br> Allow or deny access to the admin menu from IPs or networks<br><br> Allow all connection:  anyone can access the admin menu. <br> Deny connection from the list: anyone from the list can't access the admin menu, the rest can.<br> Allow connection from the list: anyone from the list can access the admin menu, the rest can't.<br><br> the IP/network list need to be in the following format:<br> IP: xxx.yyy.zzz.www <br> Subnet: xxx.yyy.zzz.www/[1-32]<br>";
$TEXT{'enter_ip_or_network'} = "输入允许或者拒绝的IP地址或者网络";
$TEXT{'error_security_demo'} = "不能改变访问控制层（ACL），这是掩饰网站";

#### Addon descriptions (addons grid (i) + each addon's page) ####
$TEXT{'about_easynas'} = "EasyNAS 核心：Web 界面、存储管理和更新系统。";
$TEXT{'about_samba'} = "兼容 Windows 的文件共享（SMB/CIFS）：向 Windows、macOS 和 Linux 客户端共享卷。";
$TEXT{'about_nfs'} = "面向 Linux/UNIX 客户端的 NFS 导出：通过网络文件系统共享卷。";
$TEXT{'about_afp'} = "Apple 文件协议（netatalk）：向较旧的 macOS 客户端和时间机器备份共享卷。";
$TEXT{'about_ftp'} = "FTP 文件传输（pure-ftpd）：用户使用 EasyNAS 账户登录并访问卷。";
$TEXT{'about_ssh'} = "对设备的安全 Shell 访问，包括 SFTP 文件传输。";
$TEXT{'about_rsyncd'} = "rsync 守护进程：将卷作为 rsync 模块，用于快速远程同步和备份。";
$TEXT{'about_tftp'} = "TFTP 服务器：通过简单 FTP 提供一个卷，例如用于 PXE 启动镜像和网络设备。";
$TEXT{'about_dlna'} = "DLNA/UPnP 媒体服务器（minidlna）：向电视和播放器串流音乐、照片和视频。";
$TEXT{'about_plex'} = "Plex 媒体服务器：整理并串流媒体库；在 32400 端口的 Plex Web 应用中管理。";
$TEXT{'about_iscsi'} = "iSCSI 目标：将卷上的磁盘镜像作为块设备（LUN）发布给 iSCSI 启动器。";
$TEXT{'about_radius'} = "FreeRADIUS 服务器：为 Wi-Fi 接入点和交换机等网络设备提供集中认证。";
$TEXT{'about_lxc'} = "Linux 容器（LXC）：在设备上运行轻量级容器，带 Web 终端。";
$TEXT{'about_mariadb'} = "MariaDB 数据库服务器，供需要 SQL 存储的应用使用。";
$TEXT{'about_german'} = "EasyNAS 界面的德语语言包。";
$TEXT{'about_polish'} = "EasyNAS 界面的波兰语语言包。";
$TEXT{'about_chinese'} = "EasyNAS 界面的简体中文语言包。";
$TEXT{'about_portuguese'} = "EasyNAS 界面的巴西葡萄牙语语言包。";
