#! /bin/bash
#========================================================================
# realm-join.sh
#
# Join an existing external Active Directory domain as a member server
# (consumer backend -- users are managed on the upstream domain). Writes
# realm.conf BACKEND=ad-member on success. Uses winbind with the 'rid' idmap
# so uid/gid are deterministic per-domain without requiring RFC2307 attrs
# upstream (stable ownership as long as the ranges below don't change).
#
#   realm-join.sh <REALM> <DOMAIN> <DC_IP> <ADMIN_USER> <ADMIN_PASS>
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail

REALM="${1:?realm required}"
DOMAIN="${2:?domain required}"
DC_IP="${3:?domain controller IP required}"
ADMIN="${4:?admin user required}"
PASS="${5:?admin password required}"

CONF=/etc/easynas
STATUS="$CONF/realm.status"
RCONF="$CONF/realm.conf"
REALM_LC="$(echo "$REALM" | tr '[:upper:]' '[:lower:]')"

fail() { echo "failed: $*" > "$STATUS"; exit 1; }
echo "configuring" > "$STATUS"

# A local DC and a domain member are mutually exclusive.
systemctl disable --now samba-ad-dc.service 2>/dev/null

# DNS must resolve the AD domain -- point at the domain controller.
mkdir -p /etc/NetworkManager/conf.d
printf '[main]\ndns=none\n' > /etc/NetworkManager/conf.d/90-easynas-dns.conf
systemctl reload NetworkManager 2>/dev/null
printf 'search %s\nnameserver %s\n' "$REALM_LC" "$DC_IP" > /etc/resolv.conf

# Kerberos + Samba member config (persisted via the /etc/samba bind mount).
cat > /etc/krb5.conf <<EOF
[libdefaults]
    default_realm = $REALM
    dns_lookup_realm = false
    dns_lookup_kdc = true
EOF

cat > /etc/samba/smb.conf <<EOF
[global]
    security = ads
    workgroup = $DOMAIN
    realm = $REALM
    winbind refresh tickets = yes
    winbind use default domain = yes
    winbind enum users = yes
    winbind enum groups = yes
    template shell = /bin/bash
    template homedir = /home/%U
    idmap config * : backend = tdb
    idmap config * : range = 100000-199999
    idmap config $DOMAIN : backend = rid
    idmap config $DOMAIN : range = 10000-99999
EOF

# Join, then bring up winbind (+ smb so the box can serve shares to AD users).
printf '%s\n' "$PASS" | net ads join -U "$ADMIN" \
    >> /var/log/easynas/realm-setup.log 2>&1 || fail "AD join"

[ -f /etc/nsswitch.conf ] || cp /usr/etc/nsswitch.conf /etc/nsswitch.conf 2>/dev/null
sed -i -E 's/^(passwd:).*/\1 files winbind/' /etc/nsswitch.conf
sed -i -E 's/^(group:).*/\1 files winbind/'  /etc/nsswitch.conf
systemctl enable --now winbind smb 2>/dev/null || fail "start winbind"

cat > "$RCONF" <<EOF
BACKEND=ad-member
REALM=$REALM
DOMAIN=$DOMAIN
DC_IP=$DC_IP
EOF
chown easynas:easynas "$RCONF" 2>/dev/null
echo "ready" > "$STATUS"
chown easynas:easynas "$STATUS" 2>/dev/null
exit 0
