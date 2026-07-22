#!/bin/sh
#========================================================================
# mariadb-storage.sh <volume-path>|internal
#
# Relocate MariaDB's data onto an EasyNAS volume (so it survives a firmware
# update, which wipes the root filesystem), or move it back to internal storage.
#
# The data is placed under <volume>/mariadb and BIND-MOUNTED onto
# /var/lib/mysql. datadir therefore stays /var/lib/mysql, so the stock config
# and the AppArmor profile (which confines mariadbd to /var/lib/mysql) need no
# changes -- only the bytes move. The bind is persisted in fstab (ordered after
# the volume mount) plus a RequiresMountsFor drop-in, so on every boot the
# volume mounts, then the bind, then MariaDB starts, in that order.
#
# Existing data is always migrated with cp -a (never moved), and the previous
# copy is only ever shadowed by the bind mount, never deleted -- so a failed
# switch leaves the original recoverable.
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -u
DATADIR=/var/lib/mysql
DROPIN=/etc/systemd/system/mariadb.service.d/easynas-storage.conf
FSTAB=/etc/fstab
MARKER="# easynas-mariadb-storage"
SERVICE=mariadb.service

log() { echo "[mariadb-storage] $*"; }

target="${1:-}"
[ -n "$target" ] || { echo "usage: mariadb-storage.sh <volume-path>|internal" >&2; exit 2; }
case "$target" in
  internal|/mnt/*) ;;
  *) log "bad target: $target"; exit 2 ;;
esac

systemctl stop "$SERVICE" 2>/dev/null

# Current bind source (the volume the live data is on now), from our fstab line.
cur_src=$(sed -n "s%^\([^ ]*\) $DATADIR .*$MARKER%\1%p" "$FSTAB" | head -1)

# Detach any existing volume binding and our persisted config; re-added below
# for the volume case.
if mountpoint -q "$DATADIR"; then
    umount "$DATADIR" || { log "cannot unmount $DATADIR (in use?)"; exit 1; }
fi
sed -i "\%$MARKER%d" "$FSTAB"
rm -f "$DROPIN"

# The authoritative live data is on the old bind source if we were bound,
# otherwise in the root datadir.
livedir="$DATADIR"
[ -n "$cur_src" ] && [ -e "$cur_src/mysql" ] && livedir="$cur_src"

##### revert to internal #####
if [ "$target" = "internal" ]; then
    if [ "$livedir" != "$DATADIR" ]; then
        log "restoring data from $livedir to $DATADIR"
        cp -a "$livedir/." "$DATADIR/" || { log "restore copy failed"; exit 1; }
        chown -R mysql:mysql "$DATADIR"
    fi
    systemctl daemon-reload
    systemctl start "$SERVICE" || { log "start failed"; exit 1; }
    log "storage: internal"
    exit 0
fi

##### relocate to a volume #####
db="$target/mariadb"
mkdir -p "$db"
chown mysql:mysql "$db"
chmod 700 "$db"

# Seed the volume: migrate the live data if the volume has no DB yet, else
# initialize a fresh datadir there.
if [ ! -e "$db/mysql" ]; then
    if [ -e "$livedir/mysql" ]; then
        log "migrating data from $livedir to $db"
        cp -a "$livedir/." "$db/" || { log "migration copy failed"; exit 1; }
    else
        log "initializing a new datadir at $db"
        mariadb-install-db --user=mysql --datadir="$db" >/dev/null 2>&1 \
          || mysql_install_db --user=mysql --datadir="$db" >/dev/null 2>&1
    fi
fi
chown -R mysql:mysql "$db"

# Persist: bind <volume>/mariadb onto /var/lib/mysql, after the volume mount.
volmnt=$(echo "$target" | sed -E 's%(/mnt/[^/]+).*%\1%')
printf '%s %s none bind,x-systemd.requires-mount-for=%s 0 0 %s\n' \
    "$db" "$DATADIR" "$volmnt" "$MARKER" >> "$FSTAB"
mkdir -p "$(dirname "$DROPIN")"
printf '[Unit]\nRequiresMountsFor=%s\n' "$DATADIR" > "$DROPIN"

systemctl daemon-reload
mount "$DATADIR" || { log "bind mount of $DATADIR failed"; exit 1; }
chown mysql:mysql "$DATADIR"
systemctl start "$SERVICE" || { log "start failed"; exit 1; }
log "storage: $db"
exit 0
