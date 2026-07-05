# EasyNAS Identity / Directory Design

Status: **Planned**
Author: Yariv Hakim

How EasyNAS manages the appliance administrator and the users that access
services, and how that fits the immutable-OS model (see
[immutable-design.md](immutable-design.md)).

---

## 1. Decision

EasyNAS separates identity into **two independent planes**:

| | Management plane | Service plane |
|--|------------------|---------------|
| **Who** | one `admin` | share / service users |
| **Stored in** | a hashed **credentials file** on the config partition | a **Realm** (local Samba AD Domain Controller) |
| **Auth path** | app-level only (`login.pm`) | winbind (SMB native) + `pam_winbind` / NSS |
| **Exists when** | always | only after a realm is created |
| **Purpose** | manage the NAS | access SMB / NFS / SSH / FTP |
| **Local OS account** | none | none |

Neither plane uses local system accounts (`/etc/passwd`, `/etc/shadow`,
`/etc/group`, `smbpasswd`) as a source of truth.

- The **admin** logs into the web UI against a single hashed credential in a
  file. No directory, no PAM, no local account — the box is always manageable,
  even before a realm exists or if the realm is broken.
- **Service users** exist only after the administrator **creates a realm** (the
  `realm` addon provisions a local Samba AD DC). Every service then consumes
  that one directory.

This supersedes the earlier "provision an AD DC at first boot and route
everything through SSSD" proposal. Two things changed:

1. **The realm is on-demand, not a boot dependency.** The AD DC's heavy parts
   (internal DNS, Kerberos KDC) only come online when the operator opts in.
2. **On a box that *is* the DC, the NSS/PAM glue is winbind, not SSSD.** SSSD is
   for domain *members* joining an external AD; the DC ships its own winbind.
   (SSSD stays a future option only if EasyNAS later joins an existing AD.)

### Why Samba AD DC for the service plane (over OpenLDAP + ldapsam)

- `samba-ad-dc` is already available and one daemon is simultaneously LDAP +
  Kerberos KDC + SMB authority.
- `samba-tool user create` sets POSIX attrs, Kerberos keys, **and** the NT hash
  in one operation — no POSIX-password / NT-hash sync to maintain. Today's
  triple-write (`useradd` + `chpasswd` + `smbpasswd`, `users.pm`) collapses to a
  single command.
- OpenLDAP + `ldapsam` is lighter (no KDC/DNS) but forces a dual-write on every
  password change and hand-maintained schema.

Trade-off accepted: an AD DC is heavier on a single box (internal DNS + KDC) —
mitigated by making it opt-in.

---

## 2. Management plane — the admin

### Credential file

- `/etc/easynas/admin.conf` (on the config partition, so it survives OS
  upgrade/reinstall), mode `0600`, owned by the `easynas` service user.
- Contains a single SHA-512 crypt string (`$6$…`) — reuses the `crypt()` call
  already in `login.pm`, so no new Perl dependency.

### login.pm

Replace the current logic — which reads `/etc/shadow`, `grep`s for the supplied
username, and accepts **any** non-root local account — with: read the one line
from `admin.conf`, recompute `crypt($pass, $stored)`, constant-time compare.

This also closes two defects in the current code:
- **Shell injection:** the username form field is interpolated into a
  `` `... grep $user` `` backtick.
- **Over-broad auth:** any account with an `/etc/shadow` entry (e.g. the
  `easynas` service user, or an addon-created account) can log into the web UI.

### Setting the password

- **First boot** prompts for the admin password and writes `admin.conf`
  (`startup/firstboot.sh` / `easynas-firstboot.service`). No default password
  ever exists on the appliance.
- Changed afterward from a Settings page (writes the same file).

The console menu / autologin (`easynas` user → `easynas.sh`) is unaffected — it
is gated by physical access, not this credential.

---

## 3. Service plane — the realm

### Architecture

```
        (created on demand via the "realm" addon)
                ┌─────────────────────────────┐
                │   Samba AD DC (directory)   │   data: /var/lib/samba
                │   LDAP + Kerberos + SMB      │   --> CONFIG PARTITION
                │   + winbindd (bundled)       │
                └─────────────┬───────────────┘
                              │
             NSS (winbind) + PAM (pam_winbind)
            ┌─────────────┬───────────────┬─────────────┐
          SSH / FTP /   NFS            EasyNAS app     Samba file server
          login         (uid/gid       (samba-tool     (native SMB auth,
          (PAM+NSS)      via RFC2307)   locally)        served ON the DC)
```

**The rule:** every non-SMB protocol consumes the directory through **NSS
(winbind)** for identity and **PAM (`pam_winbind`)** for auth. Samba is the
exception — it authenticates SMB natively because it *is* the DC. Any future
addon that speaks PAM + NSS gets users for free, no per-addon code.

### Realm lifecycle (the `realm` addon)

- **Create** — `samba-tool domain provision --use-rfc2307` (internal DNS,
  database under `/var/lib/samba` on the config partition), then switch Samba to
  `samba.service` and enable winbind NSS + `pam_winbind`. Realm parameters
  (realm/domain/admin password) come from the addon form.
- **Status** — report whether a realm exists and its realm/domain.
- **Destroy** — tear the realm down (later phase).

Users/Groups pages **gate on realm presence**: before a realm exists they show
"Create a realm first"; after, they manage directory accounts.

### Per-protocol notes

| Protocol | Identity (NSS) | Auth | Notes |
|----------|----------------|------|-------|
| **SSH** | winbind | `pam_winbind` | works once a realm exists |
| **FTP** (pure-ftpd) | winbind | `pam_winbind` | PAM service config |
| **login / console** | winbind | `pam_winbind` | |
| **Samba (SMB)** | winbind | **native** (DC) | NT hash from the directory |
| **NFS** | winbind | host/export based | needs **stable uid/gid** — RFC2307 `uidNumber`/`gidNumber`. NFSv4 + `sec=krb5` can do per-user auth against the KDC later |
| **future addons** | winbind | `pam_winbind` | no work if PAM+NSS aware |

---

## 4. What this changes

### Base image (OS layer)
- Ensure `samba-ad-dc` and the winbind NSS/PAM tooling are present on **both
  x86_64 and aarch64** package lists (realm supported on x86_64 + ARM).
- Only client/daemon config lives in the image; the directory **data** does not.

### First boot
- Prompt for the **admin password** → write `/etc/easynas/admin.conf`
  (idempotent, seed-if-absent, same model as the TLS cert).
- Do **not** auto-provision a realm. That is an explicit operator action later.

### Application
- `login.pm` → file-based admin auth (§2).
- `users.pm` / `groups.pm` → `samba-tool user|group …`; gate on realm presence.
- `users_info` / `groups_info` (`easynas.pm`) → read `getent passwd|group`
  through winbind NSS (filtered by the RFC2307 uid/gid range) instead of parsing
  `/etc/passwd`. Stays protocol-agnostic.
- `realm.pl` (realm addon) → provision / status / destroy.
- `samba.pm` → controls `samba.service` (not `smb.service`); share sections
  still written to `smb.conf`, now served by the DC.

### Config partition (Layer 2)
- `/etc/easynas/admin.conf` → persistent.
- `/var/lib/samba` (the AD database) → persistent.
- winbind cache → ephemeral (rebuilds from the DC).

### Immutable-design impact
- Supersedes §8.3 (bind-mount of `/etc/passwd`). The scattered account files are
  no longer Layer 2 — the admin credential file and the directory database are,
  and both sit cleanly on the config partition.

---

## 5. Resolved decisions

- **Management auth:** single file-based admin (`admin.conf`), not a directory
  or local account.
- **Admin initial password:** set by the first-boot prompt; no default.
- **NSS/PAM glue:** winbind + `pam_winbind` (the box is the DC), not SSSD.
- **NFS uid/gid stability:** RFC2307 explicit `uidNumber`/`gidNumber` from a
  fixed base (e.g. 10000+); winbind reads RFC2307, giving stable ownership.
- **App → directory:** `samba-tool` run locally as root (no LDAP bind creds).
- **File serving:** shares run on the DC (single-box appliance) via
  `samba.service` — upstream discourages DC + file server on one host, accepted
  for the appliance.
- **Architecture:** realm supported on x86_64 **and** aarch64.

## 6. Open items

- [ ] Internal DNS coexistence with NetworkManager (resolver → `127.0.0.1` +
      forwarders; NM must not overwrite `/etc/resolv.conf`) — the top risk;
      validate in the Phase-2 spike.
- [ ] Confirm `samba-ad-dc` + winbind are actually installable on the aarch64
      repos used by the RPi/ARM64 profiles.
- [ ] Migration/import for installs that already have local EasyNAS accounts
      (recreate usernames + uids in the realm; reset passwords — hashes are not
      portable).

---

## 7. Phased plan

1. **Admin credential file + `login.pm` rewrite.** Small, independent, security-
   positive; ships without any Samba work. First-boot writes `admin.conf`.
2. **Realm addon: provision / status / destroy a Samba AD DC.** Validate first
   on a throwaway VM — prove one SMB user + one SSH login + `getent passwd` all
   resolve the same directory account, and that internal DNS survives a reboot
   with NetworkManager. If this spike is painful, that is the signal to
   reconsider scope — before the app rewrite.
3. **Gate Users/Groups on realm presence; rewrite to `samba-tool`;**
   `users_info`/`groups_info` via `getent`.
4. **samba.pm → `samba.service`,** shares served on the DC.
5. **Per-protocol PAM/NSS** (ssh, ftp) + **NFS RFC2307** mapping.
6. **Persistence + migration:** `/var/lib/samba` and `admin.conf` on the config
   partition; optional import for pre-existing local accounts; a validation
   matrix (every protocol authenticates a directory user on a real build, x86_64
   and ARM).
