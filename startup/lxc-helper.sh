#!/bin/sh
#========================================================================
# lxc-helper.sh -- the root side of the LXC add-on (lxc.pm calls it with sudo,
# always with list arguments that lxc.pm has already validated; this script
# checks them again).
#
#   lxc-helper.sh net
#       Turn on the lxcbr0 NAT bridge (lxc-net) and container autostart (lxc).
#       openSUSE's lxc points every new container at lxcbr0 but ships the
#       bridge switched off (USE_LXC_BRIDGE="false" in /etc/default/lxc), so
#       without this no container can start.
#   lxc-helper.sh create <name> <dist> <release> <arch> <nat|lan> <0|1>
#       Download an image from images.linuxcontainers.org and make a container
#       of it. Slow, so lxc.pm runs it in its own transient unit; progress is
#       /run/easynas-lxc/<name> ("creating", then gone, or "failed").
#   lxc-helper.sh delete <name>
#   lxc-helper.sh autostart <name> <0|1>
#   lxc-helper.sh storage <volume-path>|internal
#       Keep containers on an EasyNAS volume, the way mariadb-storage.sh keeps
#       the database there: <volume>/lxc is bind-mounted onto /var/lib/lxc
#       (fstab, after the volume) so they survive a firmware update, which
#       wipes the system disk. Existing containers are copied, never moved.
#   lxc-helper.sh terminal <name> <token>
#       A one-shot ttyd on port 8080 attached to the container, guarded by the
#       credential easynas:<token>.
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -u
# The paths can be pointed elsewhere for t/lxc-helper.t (sudo drops them).
LXCPATH=${EASYNAS_LXCPATH:-/var/lib/lxc}
STATE=${EASYNAS_LXC_STATE:-/run/easynas-lxc}
LOG=${EASYNAS_LXC_LOG:-/var/log/easynas/lxc.log}
FSTAB=${EASYNAS_FSTAB:-/etc/fstab}
MARKER="# easynas-lxc-storage"
DROPIN=${EASYNAS_LXC_DROPIN:-/etc/systemd/system/lxc.service.d/easynas-storage.conf}
NETCONF=${EASYNAS_LXC_NETCONF:-/etc/default/lxc-net}
TERM_UNIT=easynas-lxc-terminal

log() { echo "$(date '+%F %T') [lxc] $*" >> "$LOG"; }
die() { log "$*"; echo "$*" >&2; exit 1; }

good_name() { echo "$1" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'; }
need_name() { good_name "${1:-}" || die "bad container name"; }
exists()    { [ -f "$LXCPATH/$1/config" ]; }
running()   { [ "$(lxc-info -n "$1" -s -H 2>/dev/null)" = "RUNNING" ]; }

# The NAT bridge: lxcbr0 on 10.0.3.1/24 with dnsmasq for DHCP, as lxc-net sets
# it up. /etc/default/lxc sources /etc/default/lxc-net after its own "false".
net_up() {
    if ! grep -qs '^USE_LXC_BRIDGE="true"' "$NETCONF"; then
        sed -i '/^USE_LXC_BRIDGE=/d' "$NETCONF" 2>/dev/null
        echo 'USE_LXC_BRIDGE="true"' >> "$NETCONF"
        systemctl stop lxc-net.service 2>/dev/null
    fi
    systemctl enable lxc-net.service lxc.service >/dev/null 2>&1
    ip link show lxcbr0 >/dev/null 2>&1 || systemctl restart lxc-net.service
    ip link show lxcbr0 >/dev/null 2>&1
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
mkdir -p "$STATE" "$(dirname "$LOG")"

case "$cmd" in

net)
    net_up || die "the lxcbr0 bridge did not come up (see: journalctl -u lxc-net)"
    ;;

create)
    name="${1:-}"; dist="${2:-}"; rel="${3:-}"; arch="${4:-}"; net="${5:-}"; auto="${6:-0}"
    need_name "$name"
    echo "$dist$rel" | grep -Eq '^[A-Za-z0-9._-]+$' || die "bad image"
    case "$arch" in amd64|arm64) ;; *) die "bad architecture" ;; esac
    case "$net"  in nat|lan) ;; *) die "bad network" ;; esac
    case "$auto" in 0|1) ;; *) die "bad autostart" ;; esac
    exists "$name" && die "container $name already exists"
    echo creating > "$STATE/$name"

    conf=$(mktemp) || die "mktemp failed"
    if [ "$net" = "lan" ]; then
        # Its own address from the LAN's DHCP, on the interface the default
        # route leaves by. (macvlan: the NAS itself can't reach it, the rest
        # of the LAN can.)
        link=$(ip -o route show default 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="dev"){print $(i+1); exit}}')
        [ -n "$link" ] || { rm -f "$conf"; echo failed > "$STATE/$name"; die "no default route to put the container on"; }
        printf 'lxc.net.0.type = macvlan\nlxc.net.0.macvlan.mode = bridge\nlxc.net.0.link = %s\n' "$link" > "$conf"
    else
        net_up || { rm -f "$conf"; echo failed > "$STATE/$name"; die "the lxcbr0 bridge did not come up"; }
        printf 'lxc.net.0.type = veth\nlxc.net.0.link = lxcbr0\n' > "$conf"
    fi
    printf 'lxc.net.0.flags = up\nlxc.net.0.hwaddr = 10:66:6a:xx:xx:xx\nlxc.start.auto = %s\n' "$auto" >> "$conf"

    log "creating $name from $dist $rel ($arch, $net network)"
    if lxc-create -n "$name" -f "$conf" -t download -- -d "$dist" -r "$rel" -a "$arch" >> "$LOG" 2>&1; then
        rm -f "$conf" "$STATE/$name"
        log "created $name"
    else
        rm -f "$conf"
        lxc-destroy -n "$name" >/dev/null 2>&1
        echo failed > "$STATE/$name"
        die "creating $name failed"
    fi
    ;;

delete)
    name="${1:-}"; need_name "$name"
    rm -f "$STATE/$name"            # a failed create leaves only this
    exists "$name" || exit 0
    lxc-destroy -n "$name" -f >> "$LOG" 2>&1 || die "deleting $name failed"
    log "deleted $name"
    ;;

autostart)
    name="${1:-}"; on="${2:-}"; need_name "$name"
    case "$on" in 0|1) ;; *) die "bad autostart" ;; esac
    exists "$name" || die "no container $name"
    cfg="$LXCPATH/$name/config"
    sed -i '/^[[:space:]]*lxc\.start\.auto[[:space:]]*=/d' "$cfg"
    echo "lxc.start.auto = $on" >> "$cfg"
    log "autostart of $name set to $on"
    ;;

storage)
    target="${1:-}"
    case "$target" in internal|/mnt/*) ;; *) die "bad storage target" ;; esac
    echo "$target" | grep -q '\.\.' && die "bad storage target"
    for c in $(lxc-ls -1 2>/dev/null); do
        running "$c" && die "stop the running containers first ($c is running)"
    done
    grep -qs creating "$STATE"/* && die "a container is still being created"

    cur_src=$(sed -n "s%^\([^ ]*\) $LXCPATH .*$MARKER%\1%p" "$FSTAB" | head -1)
    if mountpoint -q "$LXCPATH"; then
        umount "$LXCPATH" || die "cannot unmount $LXCPATH (in use?)"
    fi
    sed -i "\%$MARKER%d" "$FSTAB"
    rm -f "$DROPIN"
    livedir="$LXCPATH"
    [ -n "$cur_src" ] && [ -d "$cur_src" ] && livedir="$cur_src"

    if [ "$target" = "internal" ]; then
        if [ "$livedir" != "$LXCPATH" ]; then
            log "copying containers from $livedir back to $LXCPATH"
            cp -a "$livedir/." "$LXCPATH/" || die "copy back failed"
        fi
        systemctl daemon-reload
        log "storage: internal"
        exit 0
    fi

    dir="$target/lxc"
    mkdir -p "$dir" && chmod 755 "$dir"
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ] && [ -n "$(ls -A "$livedir" 2>/dev/null)" ]; then
        log "copying containers from $livedir to $dir"
        cp -a "$livedir/." "$dir/" || die "copy to $dir failed"
    fi
    volmnt=$(echo "$target" | sed -E 's%(/mnt/[^/]+).*%\1%')
    printf '%s %s none bind,x-systemd.requires-mounts-for=%s 0 0 %s\n' \
        "$dir" "$LXCPATH" "$volmnt" "$MARKER" >> "$FSTAB"
    mkdir -p "$(dirname "$DROPIN")"
    printf '[Unit]\nRequiresMountsFor=%s\n' "$LXCPATH" > "$DROPIN"
    systemctl daemon-reload
    mount "$LXCPATH" || die "bind mount of $LXCPATH failed"
    log "storage: $dir"
    ;;

terminal)
    name="${1:-}"; token="${2:-}"; need_name "$name"
    echo "$token" | grep -Eq '^[0-9a-f]{32}$' || die "bad token"
    running "$name" || die "$name is not running"
    # One terminal at a time: a ttyd nobody connected to would hold the port.
    systemctl stop "$TERM_UNIT" 2>/dev/null
    systemctl reset-failed "$TERM_UNIT" 2>/dev/null
    systemd-run --collect --quiet --unit="$TERM_UNIT" -p RuntimeMaxSec=8h \
        /usr/bin/ttyd -p 8080 -o -W -c "easynas:$token" /usr/bin/lxc-attach -n "$name" \
        || die "ttyd did not start"
    # Hand the browser over only once ttyd listens, or it is refused.
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        ss -ltn 'sport = :8080' 2>/dev/null | grep -q LISTEN && exit 0
        sleep 0.25
    done
    die "ttyd is not listening on port 8080"
    ;;

*)
    echo "usage: lxc-helper.sh net|create|delete|autostart|storage|terminal ..." >&2
    exit 2
    ;;
esac
exit 0
