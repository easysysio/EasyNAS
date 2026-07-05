#!/bin/bash
#========================================================================
# realm-dc-spike.sh
#
# Phase-2 spike for the identity design (docs/identity-design.md): stand up a
# local Samba AD Domain Controller with RFC2307, internal DNS and winbind on a
# THROWAWAY openSUSE VM, then prove that one directory user resolves through
# NSS and authenticates through winbind + SMB -- and that it survives a reboot.
#
# This is a validation harness, NOT appliance code. It rewrites Samba, DNS and
# NetworkManager config on the machine it runs on. Run it only on a disposable
# VM you can throw away.
#
# Usage:
#   ./realm-dc-spike.sh --yes                 provision + validate
#   ./realm-dc-spike.sh --validate-only       just re-run the checks (post-reboot)
#
# Tunables (env): REALM DOMAIN ADMINPASS FORWARDER TESTUSER TESTPASS TESTGROUP
#                 UID_BASE GID_BASE
#
# What it proves (the two risks the design flags):
#   1. internal DNS coexists with NetworkManager and survives a reboot
#   2. a directory user resolves via NSS (getent) and authenticates (wbinfo/SMB)
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail   # NOT -e: validation continues and reports every check

### ===== CONFIG =====
REALM="${REALM:-EASYNAS.LAN}"
DOMAIN="${DOMAIN:-EASYNAS}"
ADMINPASS="${ADMINPASS:-EasyNAS-Adm1n!}"     # must meet AD complexity rules
FORWARDER="${FORWARDER:-1.1.1.1}"            # upstream DNS the DC forwards to
TESTUSER="${TESTUSER:-alice}"
TESTPASS="${TESTPASS:-Alice-P4ss!}"
TESTGROUP="${TESTGROUP:-staff}"
UID_BASE="${UID_BASE:-10000}"                # RFC2307 uidNumber for the test user
GID_BASE="${GID_BASE:-10000}"                # RFC2307 gidNumber for Domain Users
GID_STAFF="${GID_STAFF:-10001}"

REALM_LC="$(echo "$REALM" | tr '[:upper:]' '[:lower:]')"
SMB_CONF=/etc/samba/smb.conf

PASS=0 ; FAIL=0
ok()   { echo "  [PASS] $*" ; PASS=$((PASS+1)) ; }
bad()  { echo "  [FAIL] $*" ; FAIL=$((FAIL+1)) ; }
die()  { echo "[FATAL] $*" ; exit 1 ; }
step() { echo ; echo "=== $* ===" ; }

# check "<description>" <command...>  -> PASS if command succeeds
check() { local d="$1" ; shift ; if "$@" >/dev/null 2>&1 ; then ok "$d" ; else bad "$d" ; fi ; }

### ===== detect the AD DC systemd unit (differs across distros) =====
dc_unit() {
    for u in samba-ad-dc.service samba.service ; do
        systemctl list-unit-files "$u" >/dev/null 2>&1 && { echo "$u" ; return ; }
    done
    echo "samba.service"
}
UNIT="$(dc_unit)"

### ===== PROVISION =====
provision() {
    step "Install packages"
    # zypper returns non-zero informational codes (e.g. when everything is
    # already installed / "nothing to do"), so don't trust its exit status --
    # attempt the install, then verify the tools we actually need are present.
    # python3-cryptography is a samba-tool runtime dep that samba-ad-dc does not
    # pull in on this openSUSE build -- without it 'samba-tool domain provision'
    # dies with ModuleNotFoundError. (Finding: the appliance package list needs
    # it too, or user management via samba-tool won't work.)
    zypper --non-interactive install \
        samba samba-ad-dc samba-client samba-winbind krb5-client bind-utils \
        python3-cryptography
    for c in samba-tool wbinfo smbclient net host ; do
        command -v "$c" >/dev/null || die "required command '$c' missing after install"
    done
    # samba-tool imports its Python deps lazily; confirm they load before we
    # provision, so a missing module is a clear message rather than a traceback.
    samba-tool domain provision --help >/dev/null 2>&1 \
        || die "samba-tool cannot load its Python modules (missing dep, e.g. python3-cryptography)"

    step "Stand down standalone Samba units (conflict with the DC)"
    systemctl disable --now smb nmb winbind 2>/dev/null
    rm -f "$SMB_CONF"          # let provisioning write a fresh DC smb.conf

    step "Set a DC hostname (must differ from the NetBIOS domain)"
    # Samba refuses to provision when the short hostname equals the NetBIOS
    # domain. Give the DC its own name. (Finding: the appliance's realm addon
    # must ensure hostname != domain when hosting a DC.)
    DC_HOSTNAME="${DC_HOSTNAME:-dc1}"
    hostnamectl set-hostname "$DC_HOSTNAME" 2>/dev/null || hostname "$DC_HOSTNAME"
    grep -q "[[:space:]]$DC_HOSTNAME\b" /etc/hosts \
        || echo "127.0.0.2 $DC_HOSTNAME.$REALM_LC $DC_HOSTNAME" >> /etc/hosts

    step "Provision the domain ($REALM / $DOMAIN) with RFC2307"
    if [ -f /var/lib/samba/private/sam.ldb ] ; then
        echo "[INFO] already provisioned -- reusing the existing domain"
    else
        samba-tool domain provision \
            --use-rfc2307 \
            --realm="$REALM" \
            --domain="$DOMAIN" \
            --server-role=dc \
            --dns-backend=SAMBA_INTERNAL \
            --adminpass="$ADMINPASS" \
            --option="dns forwarder = $FORWARDER" \
            || die "domain provision failed"
    fi

    step "Kerberos config"
    cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

    step "Internal DNS + NetworkManager (the coexistence risk)"
    # Tell NetworkManager to keep its hands off resolv.conf, then point the box
    # at the DC's own internal DNS with the realm as the search domain.
    mkdir -p /etc/NetworkManager/conf.d
    cat > /etc/NetworkManager/conf.d/90-easynas-dns.conf <<EOF
[main]
dns=none
EOF
    systemctl reload NetworkManager 2>/dev/null
    rm -f /etc/resolv.conf
    cat > /etc/resolv.conf <<EOF
search $REALM_LC
nameserver 127.0.0.1
EOF

    step "nsswitch: resolve users/groups through winbind"
    # openSUSE ships the vendor default under /usr/etc; /etc holds the override.
    # Seed /etc from /usr/etc if it isn't there yet, then wire winbind.
    [ -f /etc/nsswitch.conf ] || cp /usr/etc/nsswitch.conf /etc/nsswitch.conf 2>/dev/null
    sed -i -E 's/^(passwd:).*/\1 files winbind/' /etc/nsswitch.conf
    sed -i -E 's/^(group:).*/\1 files winbind/'  /etc/nsswitch.conf
    grep -E '^(passwd|group):' /etc/nsswitch.conf 2>/dev/null

    step "Enable + start the DC ($UNIT)"
    systemctl enable "$UNIT" >/dev/null 2>&1
    systemctl restart "$UNIT" 2>&1
    sleep 5
    if ! systemctl is-active --quiet "$UNIT" ; then
        echo "[WARN] $UNIT is not active -- diagnostics:"
        systemctl --no-pager --full status "$UNIT" 2>&1 | tail -20
        echo "---- journal ----"
        journalctl -u "$UNIT" --no-pager -n 40 2>&1 | tail -40
    fi

    step "Seed RFC2307 test accounts"
    # Domain Users needs a gidNumber so a user's primary group resolves via NSS.
    # (addunixattrs sets Unix attrs on an existing group; if it's missing on this
    # samba-tool version, getent will fail below and the spike reports it.)
    samba-tool group addunixattrs "Domain Users" "$GID_BASE" \
        || echo "[WARN] could not set Domain Users gidNumber -- getent may not resolve the primary group"
    samba-tool group add "$TESTGROUP" --gid-number="$GID_STAFF" 2>/dev/null
    samba-tool user create "$TESTUSER" "$TESTPASS" \
        --given-name=Test --surname=User \
        --uid-number="$UID_BASE" --gid-number="$GID_BASE" \
        --login-shell=/bin/bash --unix-home="/home/$TESTUSER" \
        || echo "[WARN] user create with RFC2307 flags failed -- check samba-tool version"
    samba-tool group addmembers "$TESTGROUP" "$TESTUSER" 2>/dev/null
}

### ===== VALIDATE =====
validate() {
    step "DC health"
    check "samba DC service active"            systemctl is-active --quiet "$UNIT"
    check "domain level reports"               samba-tool domain level show

    step "Internal DNS (served from 127.0.0.1)"
    check "SRV _ldap._tcp.$REALM_LC resolves"  host -t SRV "_ldap._tcp.$REALM_LC"
    check "DNS forwarder reaches upstream"      host -t A example.com

    step "Identity via NSS (winbind)"
    check "winbind responds"                   wbinfo -p
    check "getent passwd $TESTUSER"            getent passwd "$TESTUSER"
    check "getent group $TESTGROUP"            getent group "$TESTGROUP"
    # ownership stability: the uid must be the RFC2307 number we assigned
    local uid ; uid="$(getent passwd "$TESTUSER" | cut -d: -f3)"
    if [ "$uid" = "$UID_BASE" ] ; then ok "uid is the RFC2307 number ($UID_BASE)"
    else bad "uid is '$uid', expected RFC2307 $UID_BASE (dynamic idmap => unstable ownership)" ; fi

    step "Authentication"
    check "winbind auth (wbinfo -a)"           wbinfo -a "$TESTUSER%$TESTPASS"
    check "SMB auth (smbclient -L)"            smbclient -L localhost -U "$TESTUSER%$TESTPASS"
    check "SMB read of netlogon share"         smbclient "//localhost/netlogon" "$TESTPASS" -U "$TESTUSER" -c 'ls'

    step "RESULT"
    echo "  passed: $PASS   failed: $FAIL"
    if [ "$FAIL" -eq 0 ] ; then
        echo "  SPIKE PASSED. Now: 'reboot', then './realm-dc-spike.sh --validate-only'"
        echo "  to confirm DNS + winbind survive a reboot with NetworkManager."
    else
        echo "  SPIKE FAILED -- see [FAIL] lines above."
    fi
    [ "$FAIL" -eq 0 ]
}

### ===== MAIN =====
case "${1:-}" in
    --validate-only) [ "$(id -u)" -eq 0 ] || die "run as root" ; validate ;;
    --yes)           [ "$(id -u)" -eq 0 ] || die "run as root" ; provision ; validate ;;
    *)
        echo "Usage: $0 --yes | --validate-only"
        echo "  DESTRUCTIVE: rewrites Samba/DNS/NetworkManager config."
        echo "  Run only on a throwaway VM."
        exit 1 ;;
esac
