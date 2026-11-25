#!/bin/bash
#
# conf-perms.sh -- who owns what under /etc/easynas and /var/log/easynas.
#
# Run as root: by firstboot.sh (every boot, and from the core's %post) and
# by the add-ons' %post before they seed their configs. Idempotent.
#
# The web interface runs as easynas, which must not be able to write a
# daemon's config (rsyncd, radiusd, tgtd, minidlna, tftpd, pure-ftpd run as
# root) or a file root writes: that would be root without sudo. So:
#
#   /etc/easynas, /var/log/easynas   root:easynas 1775. easynas makes and
#       replaces its own files there; the sticky bit keeps it from renaming
#       or removing root's.
#   the web interface's files        easynas's (APP_FILES, APP_LOGS)
#   the daemons' configs, the add-on catalog, root's logs
#                                    root's, writable by root only
#                                    (ROOT_DIRS, ROOT_FILES, ROOT_LOGS)
#
# Older releases gave all of /etc/easynas to easynas. The first run gives
# those files to root, keeping what is in them, and leaves .root-owned
# behind. From then on a non-root file where root's belongs can only have
# been put there by easynas: it is moved aside (<name>.not-root.<time>), not
# adopted. A link there is removed either way.
#
# Tests point it elsewhere: EASYNAS_CONF_DIR, EASYNAS_LOG_DIR,
# EASYNAS_APP_USER, EASYNAS_APP_GROUP.
#
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2026
#
set -u
CONF_DIR=${EASYNAS_CONF_DIR:-/etc/easynas}
LOG_DIR=${EASYNAS_LOG_DIR:-/var/log/easynas}
APP_USER=${EASYNAS_APP_USER:-easynas}
APP_GROUP=${EASYNAS_APP_GROUP:-easynas}
MARK="$CONF_DIR/.root-owned"

APP_FILES="admin.conf easynas.cert easynas.key easynas.conf easynas.lang session.secret wizard.done lxc-images"
APP_LOGS="easynas.log balance.log"
ROOT_DIRS="addons rsyncd raddb tgt"
ROOT_FILES="minidlna tftp pure-ftpd.conf"
ROOT_LOGS="update.log lxc.log"
# Root's state from older releases, now in /run/easynas and addons/.
OLD_STATE="addonq addonq.cur addonq.lock addonq.new addonq.drainlock update.status easynas.updates easynas.core easynas.core.new"

say() { echo "conf-perms: $*" >&2; }
uid_of() { stat -c %u -- "$1" 2>/dev/null; }
# The first run is over -- and root says so: easynas can make a .root-owned
# too, but not one of root's.
first_done() { [ -f "$MARK" ] && [ ! -L "$MARK" ] && [ "$(uid_of "$MARK")" = 0 ]; }

# A directory easynas may make files in, without moving root's.
shared_dir() {
    local d="$1"
    if [ -L "$d" ]; then rm -f -- "$d"; fi
    [ -d "$d" ] || mkdir -p -- "$d" || return 1
    chown root:"$APP_GROUP" -- "$d" && chmod 1775 -- "$d"
}

# Move $1 out of the way: it is not root's, where only root's belongs.
aside() {
    local p="$1" to
    to="$p.not-root.$(date +%Y%m%d%H%M%S)"
    say "$p is not root's; moved to $to"
    mv -T -- "$p" "$to"
}

# Make root's whatever is at $1, unless (after the first run) it was easynas
# that put it there. Prints nothing; true when $1 is now root's or absent.
claim() {
    local p="$1"
    if [ -L "$p" ]; then rm -f -- "$p"; return 0; fi
    [ -e "$p" ] || return 0
    if [ "$(uid_of "$p")" != 0 ] && first_done; then
        aside "$p"
        return 0
    fi
    # Adopt: root owns all of it; the app group loses any hold on it; nobody
    # but root writes. (-h: a link inside stays a link, its target untouched.)
    chown -hR root -- "$p"
    find "$p" -group "$APP_GROUP" -exec chgrp -h root -- {} + 2>/dev/null
    chmod -R go-w -- "$p"
}

# A root directory at $1: claimed, else made. mkdir fails on anything already
# there -- a link easynas made in the meantime -- and then it is checked again.
root_dir() {
    local d="$1" try
    for try in 1 2 3; do
        claim "$d"
        if [ -d "$d" ] && [ ! -L "$d" ] && [ "$(uid_of "$d")" = 0 ]; then return 0; fi
        mkdir -m 0755 -- "$d" 2>/dev/null && chown root:root -- "$d" && return 0
    done
    say "could not make $d root's"
    return 1
}

# An empty root file at $1 when none is there: made under another name, then
# renamed over whatever easynas may have put there meanwhile.
root_file() {
    local f="$1" t
    claim "$f"
    if [ -f "$f" ] && [ ! -L "$f" ] && [ "$(uid_of "$f")" = 0 ]; then return 0; fi
    t=$(mktemp -- "$(dirname -- "$f")/.$(basename -- "$f").XXXXXX") || return 1
    chmod 0644 -- "$t"
    mv -fT -- "$t" "$f" || { rm -f -- "$t"; say "could not make $f root's"; return 1; }
}

# The web interface's own file: easynas's, if it is a plain file.
app_file() {
    local f="$1"
    [ -f "$f" ] && [ ! -L "$f" ] && chown "$APP_USER:$APP_GROUP" -- "$f"
    return 0
}

if [ "$(id -u)" != 0 ]; then say "must run as root"; exit 1; fi

# The directories first: until then easynas could still move things in them.
shared_dir "$CONF_DIR" || { say "cannot set up $CONF_DIR"; exit 1; }
shared_dir "$LOG_DIR"  || { say "cannot set up $LOG_DIR"; exit 1; }

rc=0
for d in $ROOT_DIRS;  do root_dir "$CONF_DIR/$d" || rc=1; done
for f in $ROOT_FILES; do claim "$CONF_DIR/$f"    || rc=1; done
for f in $ROOT_LOGS;  do root_file "$LOG_DIR/$f" || rc=1; done
for f in $OLD_STATE;  do rm -f -- "$CONF_DIR/$f"; done
for f in $APP_FILES;  do app_file "$CONF_DIR/$f"; done
for f in $APP_LOGS;   do app_file "$LOG_DIR/$f"; done

# The first run is done: from now on, non-root files where root's belong are
# not adopted.
[ "$rc" = 0 ] && ! first_done && root_file "$MARK"
exit $rc
