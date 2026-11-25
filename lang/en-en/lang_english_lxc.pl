
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
$TEXT{'lxc_terminal_connecting'} = "Connecting...";
$TEXT{'lxc_terminal_connected'} = "Connected to";
$TEXT{'lxc_terminal_closed'} = "The session ended. Reload the page to open a new one.";
$TEXT{'lxc_terminal_noxterm'} = "Couldn't load the terminal from cdn.jsdelivr.net. This browser needs internet access for it.";
$TEXT{'lxc_storage'} = "Container storage";
$TEXT{'lxc_storage_help'} = "Containers are kept on a volume so they survive firmware updates, which wipe the system disk. Existing containers are copied over; stop them all first.";
$TEXT{'lxc_volume_help'} = "Containers are kept on a volume (in its lxc folder), so they survive firmware updates, which wipe the system disk. This container and every one after it go here.";
$TEXT{'lxc_volume_set_help'} = "Every container is kept on this volume. To move them all to another one, use Change on the containers page.";
$TEXT{'lxc_no_vol_create'} = "Containers are kept on a volume, and there is none yet.";
$TEXT{'lxc_create_vol'} = "Create a volume first";
$TEXT{'lxc_pick_on_create'} = "Containers are kept on a volume, picked when you create the first one.";
$TEXT{'lxc_volume'} = "Volume";
$TEXT{'lxc_no_vol'} = "No volumes available. Create a volume first.";
$TEXT{'lxc_bad_vol'} = "Pick a volume.";
$TEXT{'lxc_storage_saved'} = "Container storage changed.";
$TEXT{'lxc_storage_failed'} = "Container storage was not changed. Stop every container first; see /var/log/easynas/lxc.log.";
$TEXT{'lxc_internal_warning'} = "Containers are kept on the system disk, which a firmware update wipes.";
$TEXT{'lxc_choose_volume'} = "Keep them on a volume";
$TEXT{'lxc_kept_on'} = "Containers are kept on";
$TEXT{'lxc_change'} = "Change";
$TEXT{'lxc_root_password'} = "Root password";
$TEXT{'lxc_root_password_again'} = "Root password again";
$TEXT{'lxc_root_password_help'} = "For signing in to the container as root (for example over SSH, once it is installed). The terminal here doesn't ask for it.";
$TEXT{'lxc_no_password'} = "Enter the container's root password.";
$TEXT{'lxc_password_mismatch'} = "The passwords don't match.";
$TEXT{'lxc_bad_password'} = "A password can't have line breaks.";
