
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

#### lxc ####
$TEXT{'virtualization'} = "Virtualization";
$TEXT{'lxc_on_off'} = "ON/OFF";
$TEXT{'lxc_settings'} = "Settings";
$TEXT{'lxc_name'} = "Name";
$TEXT{'lxc_state'} = "State";
$TEXT{'lxc_ip'} = "IP";
$TEXT{'lxc_action'} = "Action";
$TEXT{'lxc_create'} = "Create new System";
$TEXT{'lxc_start'} = "Start";
$TEXT{'lxc_stop'} = "Stop";
$TEXT{'lxc_terminal'} = "Terminal";
$TEXT{'lxc_none'} = "No containers.";
$TEXT{'lxc_delete'} = "Delete";
$TEXT{'lxc_delete_confirm'} = "Delete this container and everything in it? This cannot be undone.";
$TEXT{'lxc_deleted'} = "Container deleted.";
$TEXT{'lxc_dismiss'} = "Dismiss";
$TEXT{'lxc_autostart'} = "Start at boot";
$TEXT{'lxc_autostart_on'} = "Start at boot";
$TEXT{'lxc_autostart_off'} = "Don't start at boot";
$TEXT{'lxc_state_creating'} = "Creating...";
$TEXT{'lxc_state_failed'} = "Creating it failed (see /var/log/easynas/lxc.log)";
$TEXT{'lxc_image'} = "Image";
$TEXT{'lxc_image_help'} = "Downloaded from images.linuxcontainers.org for this machine";
$TEXT{'lxc_no_images'} = "Couldn't get the list of images from images.linuxcontainers.org. Is the appliance online?";
$TEXT{'lxc_network'} = "Network";
$TEXT{'lxc_network_nat'} = "Private";
$TEXT{'lxc_network_nat_help'} = "an address on a private network inside the NAS (10.0.3.x). It reaches the internet; other devices on your network cannot reach it.";
$TEXT{'lxc_network_lan'} = "Your network";
$TEXT{'lxc_network_lan_help'} = "its own address from your router, like another computer on the network. Other devices can reach it; the NAS itself cannot.";
$TEXT{'lxc_create_button'} = "Create";
$TEXT{'lxc_cancel'} = "Cancel";
$TEXT{'lxc_save'} = "Save";
$TEXT{'lxc_creating'} = "Downloading the image and creating the container. This takes a few minutes; the list updates by itself.";
$TEXT{'lxc_bad_name'} = "A name has letters, digits, '.', '_' and '-', and starts with a letter or digit.";
$TEXT{'lxc_exists'} = "There is already a container with that name.";
$TEXT{'lxc_bad_image'} = "Pick an image from the list.";
$TEXT{'lxc_failed'} = "That did not work. See /var/log/easynas/lxc.log.";
$TEXT{'lxc_start_failed'} = "The container didn't start. The reason is in /var/log/easynas/lxc.log.";
$TEXT{'lxc_terminal_failed'} = "The terminal did not start. Is the container running?";
$TEXT{'lxc_storage'} = "Container storage";
$TEXT{'lxc_storage_help'} = "Keep containers on a volume so they survive firmware updates, which wipe the system disk. Existing containers are copied over; stop them all first.";
$TEXT{'lxc_internal'} = "Internal (system disk)";
$TEXT{'lxc_volume'} = "Volume";
$TEXT{'lxc_no_vol'} = "No volumes available. Create a volume first.";
$TEXT{'lxc_bad_vol'} = "Pick a volume.";
$TEXT{'lxc_storage_saved'} = "Container storage changed.";
$TEXT{'lxc_storage_failed'} = "Container storage was not changed. Stop every container first; see /var/log/easynas/lxc.log.";
$TEXT{'lxc_internal_warning'} = "Containers are kept on the system disk, which a firmware update wipes.";
$TEXT{'lxc_choose_volume'} = "Keep them on a volume";
$TEXT{'lxc_kept_on'} = "Containers are kept on";
$TEXT{'lxc_change'} = "Change";
