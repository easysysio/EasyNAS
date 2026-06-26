# EasyNAS Identity / Directory Design

Status: **Proposed**
Author: Yariv Hakim

How EasyNAS manages users and groups across all access protocols, and how that
fits the immutable-OS model (see [immutable-design.md](immutable-design.md)).

---

## 1. Decision

Drop local system accounts (`/etc/passwd`, `/etc/shadow`, `/etc/group`,
`smbpasswd`) as the source of truth. Replace them with a **local Samba Active
Directory Domain Controller** as the single directory, consumed by every
protocol through **SSSD** (NSS for identity, PAM for authentication).

This also resolves the immutable-design §8.3 open question (system-account
persistence): the directory database lives on the **config partition**, so
accounts survive an OS upgrade without bind-mounting `/etc/passwd`.

### Why Samba AD DC (over OpenLDAP + ldapsam)

- `samba-ad-dc` is **already** in the KIWI x86_64 package list.
- One directory is simultaneously LDAP + Kerberos KDC + SMB authority.
- `samba-tool user create` sets POSIX attrs, Kerberos keys, **and** the NT hash
  in a single operation — no POSIX-password / NT-hash sync to maintain.
- The alternative (OpenLDAP + `ldapsam`) is lighter (no KDC/AD-DNS) but forces a
  dual-write on every password change and hand-maintained schema.

Trade-off accepted: an AD DC is heavier on a single box (internal DNS + KDC).

---

## 2. Architecture

```
                ┌─────────────────────────────┐
                │   Samba AD DC (directory)   │   data: /var/lib/samba
                │   LDAP + Kerberos + SMB      │   --> CONFIG PARTITION
                └─────────────┬───────────────┘
                              │
                  ┌───────────┴───────────┐
                  │         SSSD          │   NSS + PAM glue
                  └───┬───────┬───────┬───┘
        NSS (id) +    │       │       │
        PAM (auth)    │       │       │
            ┌─────────┘       │       └─────────┐
          SSH / FTP /       NFS              EasyNAS app
          login / future   (uid/gid          (samba-tool /
          PAM+NSS addons    mapping)          ldap ops)

          Samba file server ── authenticates SMB natively against the DC
```

**The rule:** every protocol consumes the directory through **PAM (auth)** and
**NSS (identity)** via SSSD. Samba is the one exception that talks to the
directory natively (it *is* the DC / a domain member), because SMB needs NT
hashes, not PAM.

Any future addon that speaks PAM + NSS gets users for free — no per-addon code.

---

## 3. Per-protocol notes

| Protocol | Identity (NSS) | Auth | Notes |
|----------|----------------|------|-------|
| **SSH** | SSSD | PAM (SSSD) | works once joined |
| **FTP** (pure-ftpd) | SSSD | PAM (SSSD) | PAM service config |
| **login / console** | SSSD | PAM (SSSD) | |
| **Samba (SMB)** | SSSD | **native** (DC / domain member) | NT hash from the directory |
| **NFS** | SSSD | host/export based | needs **stable uid/gid** across reboots — use RFC2307 attrs or pinned SSSD ID-mapping. NFSv4 + `sec=krb5` can do per-user auth against the KDC later. |
| **future addons** | SSSD | PAM (SSSD) | no work if PAM+NSS aware |

---

## 4. What this changes

### Base image (OS layer)
- Add `sssd` (+ `sssd-ad` / `sssd-tools`) and its NSS/PAM wiring
  (`nsswitch.conf`, `pam` stack).
- `samba-ad-dc` already present.
- Only **client/daemon config** lives in the image; the directory **data** does
  not.

### First boot (`firstboot.sh` pattern)
- If the directory is not yet provisioned, provision the local AD domain and
  store its database on the config partition; otherwise leave it intact.
- Idempotent, same "seed if absent" model as cert/cron.

### Application (`users.pm`, `groups.pm`)
- Replace `useradd` / `groupadd` / `chpasswd` / `smbpasswd` with directory
  operations (`samba-tool user|group …`).
- Net simplification: **one** create per user covers SMB + POSIX + Kerberos,
  removing the separate `smbpasswd` step.

### Config partition (Layer 2)
- `/var/lib/samba` (the AD database) → persistent.
- SSSD cache (`/var/lib/sss`) can be ephemeral (rebuilds from the DC).

### Immutable-design impact
- Supersedes §8.3 bind-mount-of-/etc/passwd. The scattered account files are no
  longer Layer 2 — the directory database is, and it sits cleanly under
  `/var/lib/samba` on the config partition.

---

## 5. Open items

- [ ] Decide RFC2307 (explicit uid/gid attributes) vs SSSD ID-mapping for NFS
      ownership stability. RFC2307 is more predictable for file servers.
- [ ] AD DC needs internal DNS — confirm it coexists with NetworkManager config.
- [ ] First-boot provisioning parameters (realm, domain, admin password source).
- [ ] Migration path for existing installs that already have local accounts.
- [ ] PAM service files for ftp/ssh addons reviewed for SSSD.

---

## 6. Task checklist

- [ ] Add `sssd` (+ `sssd-ad`, `sssd-tools`) to the base package list.
- [ ] First-boot: provision local Samba AD DC onto the config partition if absent.
- [ ] Join host / configure SSSD (NSS + PAM) against the local domain.
- [ ] Rewrite `users.pm` / `groups.pm` to use `samba-tool`.
- [ ] Configure Samba file server as part of the AD.
- [ ] Wire NFS uid/gid stability (RFC2307 or pinned ID-mapping).
- [ ] Review FTP/SSH PAM service files for SSSD.
- [ ] Persist `/var/lib/samba` on the config partition.
- [ ] Define migration for installs with pre-existing local accounts.
- [ ] Validate every protocol authenticates a directory user on a real build.
