#!/bin/bash
#========================================================================
# web-port.sh
#
# The web interface's port lives in /etc/easynas/easynas.conf
# (EASYNAS_PORT=, set on the Settings page). systemd, not the app, holds the
# listening socket (easynas.socket) so connections wait instead of being
# refused while the app restarts -- and a socket unit can't read an
# EnvironmentFile. So the port is written into a drop-in for it:
#
#   /etc/systemd/system/easynas.socket.d/port.conf
#
#   web-port.sh           write the drop-in (and reload systemd if it changed)
#   web-port.sh --boot    ...and if the socket is already open on another
#                         port, reopen it (firstboot.sh, before the app starts)
#   web-port.sh --apply   ...then restart the web interface: on a new port the
#                         socket is reopened (a short gap is unavoidable then);
#                         on the same port only the app restarts, with no gap
#
# Runs as root: from firstboot.sh (every boot, and the RPM's %post), and the
# Settings page (via systemd-run, so it outlives the easynas.service it
# restarts).
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -u

# (The paths can be pointed elsewhere for the tests: t/web-port.t.)
CONF=${EASYNAS_CONF:-/etc/easynas/easynas.conf}
DROPIN_DIR=${EASYNAS_SOCKET_DROPIN:-/etc/systemd/system/easynas.socket.d}
SYSTEMD_DIR=${EASYNAS_SYSTEMD_DIR:-/run/systemd/system}
SYSTEMCTL=${EASYNAS_SYSTEMCTL:-/usr/bin/systemctl}
DROPIN=$DROPIN_DIR/port.conf
DEFAULT=1443

port=""
if [ -r "$CONF" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ $line =~ ^EASYNAS_PORT=([0-9]{1,5})[[:space:]]*$ ]] && port=${BASH_REMATCH[1]}
    done < "$CONF"
fi
if [ -z "$port" ] || [ "$port" -lt 1025 ] || [ "$port" -gt 65535 ]; then
    port=$DEFAULT
fi

want="# Written by /easynas/startup/web-port.sh from $CONF -- edit the port there.
[Socket]
ListenStream=
ListenStream=$port"

changed=0
if [ "$(cat "$DROPIN" 2>/dev/null)" != "$want" ]; then
    mkdir -p "$DROPIN_DIR"
    printf '%s\n' "$want" > "$DROPIN.tmp" && mv -f "$DROPIN.tmp" "$DROPIN"
    changed=1
fi

# No running systemd (an image build): the drop-in is read at the first boot.
[ -d "$SYSTEMD_DIR" ] || exit 0
[ "$changed" = 1 ] && "$SYSTEMCTL" daemon-reload

mode=${1:-}
[ "$mode" = "--apply" ] || [ "$mode" = "--boot" ] || exit 0

# The port the socket listens on now, e.g. "[::]:1443 (Stream)" -> 1443.
listen=$("$SYSTEMCTL" show -p Listen --value easynas.socket 2>/dev/null)
current=""
[[ $listen =~ :([0-9]+)[[:space:]] ]] && current=${BASH_REMATCH[1]}
active=0
"$SYSTEMCTL" -q is-active easynas.socket && active=1

if [ "$mode" = "--boot" ]; then
    # Only a socket that is open, on the wrong port. (Not open: the RPM's
    # %post is moving an old app that holds the port itself over to the
    # socket, and opens it once that app has stopped.)
    if [ "$active" = 1 ] && [ "$current" != "$port" ]; then
        "$SYSTEMCTL" restart easynas.socket
    fi
    exit 0
fi

if [ "$current" = "$port" ] && [ "$active" = 1 ]; then
    "$SYSTEMCTL" restart easynas.service
else
    # The app keeps a copy of the old socket, so it has to stop before the
    # socket is reopened on the new port.
    "$SYSTEMCTL" stop easynas.service
    "$SYSTEMCTL" restart easynas.socket
    "$SYSTEMCTL" start easynas.service
fi
