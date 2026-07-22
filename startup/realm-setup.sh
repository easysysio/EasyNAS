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

# The DC forwards external DNS to $FORWARDER. A hardcoded public resolver
# (1.1.1.1) is unreachable on networks that block outbound DNS -- and once the
# DC points the box at 127.0.0.1 (realm-apply), that leaves nothing resolvable.
# When the caller left the default, prefer the resolver DHCP already handed us
# (captured now, before step 4 overwrites resolv.conf); the network is
# guaranteed to allow it. Fall back to the default gateway, then 1.1.1.1.
if [ "$FORWARDER" = "1.1.1.1" ]; then
    _dns="$(awk '/^nameserver/ && $2 !~ /^127\./ {print $2; exit}' /etc/resolv.conf 2>/dev/null)"
    [ -z "$_dns" ] && _dns="$(ip route 2>/dev/null | awk '/^default/{print $3; exit}')"
    [ -n "$_dns" ] && FORWARDER="$_dns"
fi

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

# 6. Give Domain Users a gidNumber so members' primary group resolves in NSS.
samba-tool group addunixattrs "Domain Users" 10000 2>/dev/null

# 7. Record the active backend for the app (easynas.pm get_realm). Written
#    before apply so realm-apply.sh (which reads it) sees the ad-dc realm.
cat > "$RCONF" <<EOF
BACKEND=ad-dc
REALM=$REALM
DOMAIN=$DOMAIN
EOF
chown easynas:easynas "$RCONF" 2>/dev/null

# 8. Establish the runtime config (Kerberos, NetworkManager, winbind, the DC
#    service, resolver). Shared with the boot path so it is defined once.
FORWARDER="$FORWARDER" /easynas/startup/realm-apply.sh || fail "starting the domain controller"

echo "ready" > "$STATUS"
chown easynas:easynas "$STATUS" 2>/dev/null
exit 0
