#! /bin/bash
#========================================================================
# realm-apply.sh
#
# (Re)establish the OS-layer runtime configuration for an already-provisioned
# local AD DC: Kerberos, NetworkManager, nsswitch/winbind, the DC service and
# the resolver. Idempotent -- run once after provisioning (by realm-setup.sh)
# and on every boot (by firstboot.sh) so the DC comes back after a reboot or an
# OS reinstall, using the database persisted on the config partition.
#
# Reads the realm from /etc/easynas/realm.conf. No-op unless the backend is
# ad-dc and a provisioned database is present.
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail

RCONF=/etc/easynas/realm.conf
FORWARDER="${FORWARDER:-1.1.1.1}"

backend="$(grep -m1 '^BACKEND=' "$RCONF" 2>/dev/null | cut -d= -f2)"
realm="$(grep -m1 '^REALM=' "$RCONF" 2>/dev/null | cut -d= -f2)"
[ "$backend" = "ad-dc" ] || exit 0
[ -n "$realm" ] || exit 0
[ -f /var/lib/samba/private/sam.ldb ] || exit 0     # nothing provisioned yet
realm_lc="$(echo "$realm" | tr '[:upper:]' '[:lower:]')"

# Kerberos config, from the (persisted) samba private dir.
[ -f /var/lib/samba/private/krb5.conf ] && cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# NetworkManager must not manage resolv.conf.
mkdir -p /etc/NetworkManager/conf.d
printf '[main]\ndns=none\n' > /etc/NetworkManager/conf.d/90-easynas-dns.conf
systemctl reload NetworkManager 2>/dev/null

# nsswitch -> winbind (seed /etc from the openSUSE vendor default if needed).
[ -f /etc/nsswitch.conf ] || cp /usr/etc/nsswitch.conf /etc/nsswitch.conf 2>/dev/null
grep -qE '^passwd:.*winbind' /etc/nsswitch.conf || sed -i -E 's/^(passwd:).*/\1 files winbind/' /etc/nsswitch.conf
grep -qE '^group:.*winbind'  /etc/nsswitch.conf || sed -i -E 's/^(group:).*/\1 files winbind/'  /etc/nsswitch.conf

# Start the DC (the standalone units conflict with it).
UNIT=samba-ad-dc.service
systemctl list-unit-files "$UNIT" >/dev/null 2>&1 || UNIT=samba.service
systemctl disable --now smb nmb winbind 2>/dev/null
systemctl enable "$UNIT" >/dev/null 2>&1
systemctl restart "$UNIT" || exit 1
sleep 3
systemctl is-active --quiet "$UNIT" || exit 1

# The DC now serves DNS -- point the box at it.
printf 'search %s\nnameserver 127.0.0.1\n' "$realm_lc" > /etc/resolv.conf
exit 0
