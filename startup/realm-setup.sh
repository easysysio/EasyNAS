#! /bin/bash
#========================================================================
# realm-setup.sh
#
# Provision a local Samba AD Domain Controller for EasyNAS. This is the
# sequence validated end-to-end by the build repo's tools/realm-dc-spike.sh
# (see docs/identity-design.md sec 10). Runs as root, launched in the
# background by the realm addon; it records progress in realm.status and, on
# success, writes realm.conf so the app picks up the ad-dc backend.
#
#   realm-setup.sh <REALM> <DOMAIN> <ADMINPASS> [FORWARDER] [DC_HOSTNAME]
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail

REALM="${1:?realm required}"
DOMAIN="${2:?domain required}"
ADMINPASS="${3:?admin password required}"
FORWARDER="${4:-1.1.1.1}"
DC_HOSTNAME="${5:-easynas-dc}"

CONF=/etc/easynas
STATUS="$CONF/realm.status"
RCONF="$CONF/realm.conf"
SMB_CONF=/etc/samba/smb.conf
REALM_LC="$(echo "$REALM" | tr '[:upper:]' '[:lower:]')"

fail() { echo "failed: $*" > "$STATUS"; exit 1; }

echo "configuring" > "$STATUS"

# 1. Stand down standalone Samba (conflicts with the DC).
systemctl disable --now smb nmb winbind 2>/dev/null

# 2. openSUSE's MIT KDC binary is not at samba's default /usr/sbin/krb5kdc.
KDC_BIN=/usr/lib/mit/sbin/krb5kdc
for p in /usr/lib/mit/sbin/krb5kdc /usr/sbin/krb5kdc /usr/lib/krb5/krb5kdc ; do
    [ -x "$p" ] && KDC_BIN="$p" && break
done

# 3. The DC's short hostname must differ from the NetBIOS domain.
hostnamectl set-hostname "$DC_HOSTNAME" 2>/dev/null || hostname "$DC_HOSTNAME"
grep -q "[[:space:]]$DC_HOSTNAME\b" /etc/hosts \
    || echo "127.0.0.2 $DC_HOSTNAME.$REALM_LC $DC_HOSTNAME" >> /etc/hosts

# 4. Use the forwarder for DNS while provisioning (the DC isn't up yet).
printf 'nameserver %s\n' "$FORWARDER" > /etc/resolv.conf

# 5. Provision (idempotent: reuse an existing domain).
if [ ! -f /var/lib/samba/private/sam.ldb ] ; then
    rm -f "$SMB_CONF"
    samba-tool domain provision \
        --use-rfc2307 \
        --realm="$REALM" \
        --domain="$DOMAIN" \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL \
        --adminpass="$ADMINPASS" \
        --option="dns forwarder = $FORWARDER" \
        --option="mit kdc command = $KDC_BIN" \
        || fail "domain provision"
fi

# 6. Kerberos config (copy, do not symlink).
cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# 7. Keep NetworkManager from overwriting resolv.conf.
mkdir -p /etc/NetworkManager/conf.d
printf '[main]\ndns=none\n' > /etc/NetworkManager/conf.d/90-easynas-dns.conf
systemctl reload NetworkManager 2>/dev/null

# 8. Resolve users/groups through winbind (seed /etc from the openSUSE vendor
#    default under /usr/etc if needed).
[ -f /etc/nsswitch.conf ] || cp /usr/etc/nsswitch.conf /etc/nsswitch.conf 2>/dev/null
sed -i -E 's/^(passwd:).*/\1 files winbind/' /etc/nsswitch.conf
sed -i -E 's/^(group:).*/\1 files winbind/'  /etc/nsswitch.conf

# 9. Start the DC (unit name differs across builds).
UNIT=samba-ad-dc.service
systemctl list-unit-files "$UNIT" >/dev/null 2>&1 || UNIT=samba.service
systemctl enable "$UNIT" >/dev/null 2>&1
systemctl restart "$UNIT" || fail "start $UNIT"
sleep 5
systemctl is-active --quiet "$UNIT" || fail "$UNIT did not stay up"

# 10. The DC now serves DNS -- point the box at it.
printf 'search %s\nnameserver 127.0.0.1\n' "$REALM_LC" > /etc/resolv.conf

# 11. Give Domain Users a gidNumber so members' primary group resolves in NSS.
samba-tool group addunixattrs "Domain Users" 10000 2>/dev/null

# 12. Record the active backend for the app (easynas.pm get_realm).
cat > "$RCONF" <<EOF
BACKEND=ad-dc
REALM=$REALM
DOMAIN=$DOMAIN
EOF
chown easynas:easynas "$RCONF" 2>/dev/null

echo "ready" > "$STATUS"
chown easynas:easynas "$STATUS" 2>/dev/null
exit 0
