#! /bin/bash
#========================================================================
# realm-ldap.sh
#
# Bind to an external OpenLDAP directory via SSSD (consumer backend -- users
# are managed on the LDAP server). Provides NSS + PAM identity for SSH / FTP /
# login. Writes realm.conf BACKEND=ldap on success.
#
# NOTE: SMB authentication of LDAP users is NOT provided here -- that needs the
# Samba LDAP schema (sambaSamAccount) and a ldapsam passdb on the server side.
# This backend covers POSIX identity + PAM; SMB against a plain OpenLDAP is out
# of scope.
#
#   realm-ldap.sh <LDAP_URI> <BASE_DN> [BIND_DN] [BIND_PW]
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail

URI="${1:?ldap uri required}"
BASE="${2:?search base required}"
BINDDN="${3:-}"
BINDPW="${4:-}"

CONF=/etc/easynas
STATUS="$CONF/realm.status"
RCONF="$CONF/realm.conf"

fail() { echo "failed: $*" > "$STATUS"; exit 1; }
echo "configuring" > "$STATUS"

# LDAP identity replaces the DC/member winbind stack.
systemctl disable --now samba-ad-dc.service winbind 2>/dev/null

mkdir -p /etc/sssd
{
  echo "[sssd]"
  echo "services = nss, pam"
  echo "domains = ldap"
  echo ""
  echo "[domain/ldap]"
  echo "id_provider = ldap"
  echo "auth_provider = ldap"
  echo "ldap_uri = $URI"
  echo "ldap_search_base = $BASE"
  [ -n "$BINDDN" ] && echo "ldap_default_bind_dn = $BINDDN"
  [ -n "$BINDPW" ] && echo "ldap_default_authtok = $BINDPW"
  echo "ldap_id_use_start_tls = false"
  echo "ldap_tls_reqcert = never"
  echo "cache_credentials = true"
  echo "enumerate = true"
} > /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

[ -f /etc/nsswitch.conf ] || cp /usr/etc/nsswitch.conf /etc/nsswitch.conf 2>/dev/null
sed -i -E 's/^(passwd:).*/\1 files sss/' /etc/nsswitch.conf
sed -i -E 's/^(group:).*/\1 files sss/'  /etc/nsswitch.conf

systemctl enable --now sssd 2>/dev/null || fail "start sssd"

cat > "$RCONF" <<EOF
BACKEND=ldap
REALM=
DOMAIN=
EOF
chown easynas:easynas "$RCONF" 2>/dev/null
echo "ready" > "$STATUS"
chown easynas:easynas "$STATUS" 2>/dev/null
exit 0
