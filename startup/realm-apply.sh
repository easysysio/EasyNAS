#! /bin/bash
#========================================================================
# realm-apply.sh
#
# (Re)establish the OS-layer runtime configuration for the configured realm
# backend, from state persisted on the config partition. Idempotent -- run once
# after setup (by realm-setup/join/ldap) and on every boot (by firstboot.sh) so
# the realm comes back after a reboot or an OS reinstall.
#
# Reads the backend + params from /etc/easynas/realm.conf. No-op for the local
# backend or when nothing is configured.
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail

RCONF=/etc/easynas/realm.conf

cfg() { grep -m1 "^$1=" "$RCONF" 2>/dev/null | cut -d= -f2- ; }
backend="$(cfg BACKEND)"
realm="$(cfg REALM)"
domain="$(cfg DOMAIN)"
dc_ip="$(cfg DC_IP)"
realm_lc="$(echo "$realm" | tr '[:upper:]' '[:lower:]')"

nm_unmanaged() {
    mkdir -p /etc/NetworkManager/conf.d
    printf '[main]\ndns=none\n' > /etc/NetworkManager/conf.d/90-easynas-dns.conf
    systemctl reload NetworkManager 2>/dev/null
}
nss_switch() {   # $1 = winbind | sss
    [ -f /etc/nsswitch.conf ] || cp /usr/etc/nsswitch.conf /etc/nsswitch.conf 2>/dev/null
    grep -qE "^passwd:.*$1" /etc/nsswitch.conf || sed -i -E "s/^(passwd:).*/\1 files $1/" /etc/nsswitch.conf
    grep -qE "^group:.*$1"  /etc/nsswitch.conf || sed -i -E "s/^(group:).*/\1 files $1/"  /etc/nsswitch.conf
}
dc_unit() {
    local u=samba-ad-dc.service
    systemctl list-unit-files "$u" >/dev/null 2>&1 || u=samba.service
    echo "$u"
}

case "$backend" in

  ad-dc)
    [ -f /var/lib/samba/private/sam.ldb ] || exit 0
    [ -f /var/lib/samba/private/krb5.conf ] && cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf
    nm_unmanaged
    nss_switch winbind
    unit="$(dc_unit)"
    systemctl disable --now smb nmb winbind 2>/dev/null
    systemctl enable "$unit" >/dev/null 2>&1
    systemctl restart "$unit" || exit 1
    sleep 3
    systemctl is-active --quiet "$unit" || exit 1
    printf 'search %s\nnameserver 127.0.0.1\n' "$realm_lc" > /etc/resolv.conf
    ;;

  ad-member)
    [ -n "$realm" ] && [ -n "$dc_ip" ] || exit 0
    # krb5.conf is a single file (not on a persisted dir) -- regenerate it.
    cat > /etc/krb5.conf <<EOF
[libdefaults]
    default_realm = $realm
    dns_lookup_realm = false
    dns_lookup_kdc = true
EOF
    nm_unmanaged
    printf 'search %s\nnameserver %s\n' "$realm_lc" "$dc_ip" > /etc/resolv.conf
    nss_switch winbind
    systemctl disable --now samba-ad-dc.service 2>/dev/null
    systemctl enable --now winbind smb 2>/dev/null || exit 1
    ;;

  ldap)
    [ -f /etc/sssd/sssd.conf ] || exit 0
    nss_switch sss
    systemctl disable --now samba-ad-dc.service winbind 2>/dev/null
    systemctl enable --now sssd 2>/dev/null || exit 1
    ;;

  *)
    exit 0   # local / unconfigured -- nothing to do
    ;;
esac
exit 0
