#!/bin/bash
#
# firstboot.sh
#
# Seeds EasyNAS persistent config-layer state (/etc/easynas, cron) if it is
# absent, then fixes ownership. Idempotent: every operation is guarded by an
# "if missing" check, so it is safe to run on every boot and self-heals after
# a factory reset of the config layer.
#
# In the immutable-OS model the OS image is read-only; this script is what
# populates the writable config layer on first boot instead of doing it at
# RPM build time. See docs/immutable-design.md.
#
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2017
#

CONF_DIR=/etc/easynas
CRON=/etc/cron.d/easynas.cron

# --- Layer-2 persistence (docs/immutable-design.md sec 8.3) ------------------
# The config partition mounts at /config. Persistent state lives under
# /config/<name> and is bind-mounted onto its real location so it survives an
# OS reinstall: /etc/easynas (admin/realm config, certs) and /var/lib/samba
# (the AD DC database). No-op when /config isn't a mounted partition (e.g. a
# source/dev checkout), so nothing breaks off-appliance.
CONFIG_MNT=/config

persist_bind() {
    local name="$1" target="$2"
    local store="${CONFIG_MNT}/${name}"
    mountpoint -q "$CONFIG_MNT" || return 0
    mkdir -p "$store" "$target"
    # First use: seed the store from the image's initial contents so nothing is
    # shadowed once we bind-mount over the target.
    if [ -z "$(ls -A "$store" 2>/dev/null)" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
        cp -a "$target/." "$store/" 2>/dev/null
    fi
    mountpoint -q "$target" || mount --bind "$store" "$target"
    grep -q " $target " /etc/fstab 2>/dev/null \
        || echo "$store $target none bind,x-systemd.requires-mounts-for=${CONFIG_MNT} 0 0" >> /etc/fstab
}

persist_bind easynas  /etc/easynas
persist_bind samba    /var/lib/samba
persist_bind samba-cf /etc/samba      # smb.conf (ad-dc / ad-member)
persist_bind sssd     /etc/sssd        # sssd.conf (ldap)

# SSL certificate (conflict #3): generate only if missing, so an OS upgrade
# never regenerates the appliance's identity.
if [ ! -f ${CONF_DIR}/easynas.cert ]; then
    openssl req -x509 -newkey rsa:2048 \
        -keyout ${CONF_DIR}/easynas.key \
        -out ${CONF_DIR}/easynas.cert \
        -sha256 -days 365 -nodes \
        -subj "/C=US/ST=Oregon/O=EasyNAS/OU=Org/CN=easynas"
fi

# Listen port (conflict #1): seed the default if missing.
if [ ! -f ${CONF_DIR}/easynas.conf ]; then
    echo "EASYNAS_PORT=1443" > ${CONF_DIR}/easynas.conf
fi

# Cron schedule (conflict #2): seed the default update-check entry if missing.
# Per-filesystem scrub and snapshot entries are appended/removed at runtime by
# the application, which is why the file must live on the writable config layer.
if [ ! -f ${CRON} ]; then
    echo '0 */6 * * *  root sleep ${RANDOM:0:2}m ;/easynas/startup/check_update.pl' > ${CRON}
fi

chown -R easynas:easynas ${CONF_DIR}
chown -R easynas:easynas /var/log/easynas

# Re-establish an AD DC realm on boot (idempotent, no-op unless the backend is
# ad-dc): after a reboot or an OS reinstall the database is persisted on the
# config partition, but the OS-layer runtime config (service enablement,
# nsswitch, Kerberos, resolver) must be reapplied. See realm-apply.sh.
/easynas/startup/realm-apply.sh 2>/dev/null || true

# --- btrfs root snapshots (set up here, not at image-build) -------------------
# The image ships a plain '@' subvolume root (KIWI btrfs_root_is_subvolume),
# NOT a snapper snapshot layout: KIWI's btrfs_root_is_snapshot runs snapper's
# installation-helper, which cannot create /.snapshots inside our LXC build
# chroot. So we configure snapper on the running system, where the real kernel
# makes subvolume creation work. This gives snapshot-before-upgrade plus the
# GRUB "boot from snapshot" recovery menu. See docs/btrfs-snapshots-design.md.
# Idempotent: once /etc/snapper/configs/root exists we do nothing.
setup_snapshots() {
    command -v snapper >/dev/null 2>&1 || return 0
    [ "$(stat -f -c %T / 2>/dev/null)" = "btrfs" ] || return 0
    [ -e /etc/snapper/configs/root ] && return 0

    snapper -c root create-config / || return 0
    # Explicit, version-labeled upgrade snapshots are the model (see the design
    # doc); silence timeline noise and keep number-based cleanup on.
    snapper -c root set-config "TIMELINE_CREATE=no" "NUMBER_CLEANUP=yes" 2>/dev/null
    # A known-good baseline to roll back to.
    snapper -c root create --description "EasyNAS baseline" --cleanup number 2>/dev/null
    # Regenerate GRUB so the "boot from snapshot" submenu appears.
    [ -e /boot/grub2/grub.cfg ] && grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null
    return 0
}
setup_snapshots

exit 0
