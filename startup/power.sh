#!/bin/bash
#
# power.sh {reboot|shutdown}
#
# Stop every installed EasyNAS service, then reboot or power off the appliance.
# Shared by the web UI (Power controller) and the console menu (easynas.sh) so
# power behaves identically from either surface. Uses sudo internally, so the
# caller does not need to.
#
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2017
#

ADDON_DIR=/easynas/addons
action="$1"

# Gracefully stop each installed addon's service before going down. Idempotent:
# a service that is absent or already stopped is ignored.
for f in "$ADDON_DIR"/*.easynas; do
    [ -f "$f" ] || continue
    svc=$(grep -o '<service>[^<]*</service>' "$f" | sed 's/<[^>]*>//g')
    [ -n "$svc" ] && sudo /usr/bin/systemctl stop "$svc" >/dev/null 2>&1
done

case "$action" in
    reboot)   sudo /usr/bin/systemctl reboot ;;
    shutdown) sudo /usr/bin/systemctl poweroff ;;
    *) echo "usage: power.sh {reboot|shutdown}" >&2; exit 1 ;;
esac
