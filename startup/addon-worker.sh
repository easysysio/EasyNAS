#!/bin/sh
# EasyNAS addon install/update queue.
#
# Two modes, both run as root (via sudo from the addons controller):
#   addon-worker.sh enqueue <install|update> <package>
#       Append one op to the FIFO queue (click order) and flag activity.
#   addon-worker.sh            (no args)
#       Drain the queue one op at a time. Started -- possibly redundantly --
#       after every enqueue; a drain-lock keeps exactly one drainer running,
#       and it loops until the queue is empty, so an op appended while it runs
#       is still processed. zypper can't run concurrently anyway, so this
#       serialization is required, not just cosmetic.
#
# State (all under the writable config dir, read by the addons page):
#   addonq      pending ops, one "<op>\t<package>" line per op, in order
#   addonq.cur  the op currently running (absent when idle)
#   update.status  "updating" while the queue is active (drives the banner)
set -u
DIR=/etc/easynas
QUEUE="$DIR/addonq"
CUR="$DIR/addonq.cur"
LOG=/var/log/easynas/update.log
ADDONDIR="$DIR/addons"

valid_pkg() { case "$1" in easynas|easynas-[a-z0-9-]*) return 0 ;; *) return 1 ;; esac; }

##### enqueue mode #####
if [ "${1:-}" = "enqueue" ]; then
    op="${2:-}"; pkg="${3:-}"
    case "$op" in install|update) ;; *) exit 2 ;; esac
    valid_pkg "$pkg" || exit 2
    mkdir -p "$DIR"
    ( flock 8; printf '%s\t%s\n' "$op" "$pkg" >> "$QUEUE" ) 8>>"$QUEUE.lock"
    echo updating > "$DIR/update.status"
    exit 0
fi

##### drain mode #####
# One drainer only; another holder will see our queued line, so just leave.
exec 9>>"$DIR/addonq.drainlock"
flock -n 9 || exit 0

repo=EasyNAS
zypper --quiet lr -E 2>/dev/null | grep -q '\bEasyNAS_Beta\b' && repo=EasyNAS_Beta

pop() {
    ( flock 8
      [ -s "$QUEUE" ] || exit 1
      head -n1 "$QUEUE"
      tail -n +2 "$QUEUE" > "$QUEUE.new" 2>/dev/null
      mv -f "$QUEUE.new" "$QUEUE" 2>/dev/null
    ) 8>>"$QUEUE.lock"
}

# Track whether a NEW addon was installed this drain: its Mojolicious route is
# only registered at web-app startup, so we restart the service once at the end.
did_install=0

while :; do
    line=$(pop) || break
    [ -n "$line" ] || break
    op=${line%%	*}
    pkg=${line#*	}
    valid_pkg "$pkg" || continue

    printf '%s\t%s\n' "$op" "$pkg" > "$CUR"
    echo updating > "$DIR/update.status"

    if [ "$op" = "install" ]; then
        zypper -n --gpg-auto-import-keys install "$pkg" >>"$LOG" 2>&1
    else
        zypper -n --gpg-auto-import-keys update "$pkg" >>"$LOG" 2>&1
    fi
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "[addon-worker] $op $pkg failed (rc=$rc)" >>"$LOG"
    elif [ "$op" = install ]; then
        did_install=1
    fi

    # Reflect the new state: refresh this addon's info and the pending-update
    # list so the grid and the sidebar badge are correct on the next reload.
    zypper --xmlout info "$pkg" > "$ADDONDIR/$pkg.addon" 2>/dev/null
    zypper --quiet --xmlout lu -a --repo "$repo" > "$DIR/easynas.updates" 2>/dev/null
done

# Queue drained: clear the current-op and the banner flag.
rm -f "$CUR" "$DIR/update.status"

# A freshly installed addon's Mojolicious route is only registered at web-app
# startup (lib/EasyNAS.pm builds routes from get_addons once), so its new
# sidebar link would 404 until the service restarts. Restart once, after the
# whole queue drains, and only when something was actually installed -- updates
# reuse the same program and need no restart. This worker runs in its own
# transient systemd unit (systemd-run --collect), so it survives the restart
# and still exits cleanly.
[ "$did_install" = 1 ] && /usr/bin/systemctl restart easynas.service
