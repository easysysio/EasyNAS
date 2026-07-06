#! /bin/bash
#========================================================================
# realm-import.sh
#
# Import pre-existing local EasyNAS accounts (/etc/passwd, uid 1000-6499) into
# the local AD DC, preserving each account's uid as its RFC2307 uidNumber so
# files already owned by that uid keep resolving to the same user. Passwords
# are not portable, so each imported user is given the supplied temporary
# password and should reset it. Accounts already present in the DC are skipped.
#
#   realm-import.sh <TEMP_PASSWORD>
#
# This file is part of EasyNAS (c) created by Yariv Hakim
#========================================================================
set -uo pipefail

TEMPPASS="${1:?temporary password required}"
LOG=/var/log/easynas/realm-setup.log

# Primary group for the imported users (Domain Users' gidNumber).
DU_GID="$(getent group 'domain users' 2>/dev/null | cut -d: -f3)"
[ -n "$DU_GID" ] || DU_GID=10000

existing="$(samba-tool user list 2>/dev/null)"
count=0

while IFS=: read -r name _pw uid _gid _gecos home _shell ; do
    [ -n "$uid" ] || continue
    [ "$uid" -ge 1000 ] 2>/dev/null || continue
    [ "$uid" -lt 6500 ] 2>/dev/null || continue
    [ "$name" = "easynas" ] && continue
    [ "$name" = "nobody" ]  && continue
    printf '%s\n' "$existing" | grep -qx "$name" && continue   # already in the DC

    if samba-tool user create "$name" "$TEMPPASS" \
            --uid-number="$uid" --gid-number="$DU_GID" \
            --given-name="$name" --login-shell=/bin/bash \
            --unix-home="${home:-/home/$name}" >> "$LOG" 2>&1 ; then
        count=$((count+1))
        echo "$(date) imported local account '$name' (uid $uid)" >> "$LOG"
    else
        echo "$(date) FAILED to import '$name'" >> "$LOG"
    fi
done < /etc/passwd

echo "$(date) realm-import: imported $count account(s)" >> "$LOG"
exit 0
