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
| **Stored in** | a hashed **credentials file** on the config partition | the active **directory backend** (see below) |
| **Auth path** | app-level only (`login.pm`) | NSS + PAM (backend-specific) |
| **Exists when** | always | only after a **realm** is configured |
| **Purpose** | manage the NAS | access SMB / NFS / SSH / FTP |

- The **admin** logs into the web UI against a single hashed credential in a
  file — never a local or directory account. The box is always manageable, even
  before a realm exists or if the realm is broken.
- **Service users** exist only after the administrator **configures a realm**.
  The realm is a **pluggable directory backend**, and it is **switchable**:

  1. **Local (via Samba)** — self-contained; accounts stored on the appliance,
     no external server.
  2. **Active Directory** — either *host a local Samba DC* (be your own domain)
     or *join an existing external AD*.
  3. **OpenLDAP (external)** — bind to a 3rd-party LDAP directory.

Every backend is consumed through the same two OS interfaces — **NSS**
(identity/numbers) and **PAM** (auth) — plus a **Samba passdb** setting for SMB.
The services, the ownership model (§4), and `users_info`/`getent` are therefore
**backend-agnostic**; only the `realm` addon knows the difference.

### Owned vs consumer

The three families split into two behaviours that shape the UI:

- **EasyNAS-owned** (Local, AD-local-DC) → EasyNAS is the authority →
  Users/Groups pages are **fully editable** (create/delete/password).
- **Consumer** (AD-join-external, OpenLDAP) → the directory lives elsewhere →
  EasyNAS **browses** users/groups and assigns them to shares, but does **not**
  create/delete them (that happens on the 3rd-party system).

### Why this shape

- One NSS/PAM abstraction covers all three, so services and ownership are written
  once. Adding a backend is configuration, not new service code.
- The **Local** backend maps today's `useradd` + `smbpasswd` model, so existing
  installs become `backend = local` and nothing breaks.
- The **AD-local-DC** backend collapses today's triple-write (`useradd` +
  `chpasswd` + `smbpasswd`) into a single `samba-tool user create`.

---

## 2. Management plane — the admin

*(Implemented — Phase 1.)*

- `/etc/easynas/admin.conf` (config partition), mode `0600`, owned by the
  `easynas` service user: one line, `admin:<$6$ SHA-512 crypt hash>`.
- `login.pm` reads it, recomputes `crypt($pass, $stored)`, constant-time
  compares. Replaced reading `/etc/shadow` + `grep $user` (shell-injection) +
  accepting any non-root local account.
- **First boot** prompts for the password on the console (`easynas.sh` when
  `admin.conf` is absent); no default password ever exists. Changed later from
  the console menu / a Settings page.
- Backend-independent — identical regardless of which realm is active.

---

## 3. Service plane — the realm backends

### Consumption (backend-agnostic)

```
                 realm backend (one of, switchable)
   Local (Samba)      AD: local DC      AD: join external    OpenLDAP (ext)
   local accounts     this box IS DC    member of corp AD    3rd-party LDAP
        │                  │                  │                  │
        └──────────────────┴────────┬─────────┴──────────────────┘
                        NSS + PAM (per backend)
        ┌─────────────┬───────────────┬─────────────┐
      SSH / FTP /   NFS            EasyNAS app     Samba file server
      login         (uid/gid)      (CRUD if owned) (SMB auth)
```

### Backend matrix

| Backend | Samba role (`security` / `passdb`) | NSS / PAM | EasyNAS CRUD | uid/gid source | External server |
|---------|-----------------------------------|-----------|--------------|----------------|-----------------|
| **Local (Samba)** | `security=user`, `tdbsam` | files / `pam_unix` | **Yes** | local uids | none |
| **AD — local DC** | DC (`samba.service`) | winbind / `pam_winbind` | **Yes** (`samba-tool`) | RFC2307 `uidNumber` (ours) | none |
| **AD — join external** | member (`security=ads`) | winbind / `pam_winbind` | **No** (read-only) | RFC2307 / idmap (upstream) | AD domain |
| **OpenLDAP — external** | member via SSSD / `ldapsam` | SSSD(ldap) / `pam_sss` | read-only (RW only if bind allows) | posixAccount `uidNumber` (upstream) | LDAP server |

> On a box that *is* the DC, the glue is the DC's **winbind** (not SSSD). SSSD is
> the glue for the **external** backends (join-AD, OpenLDAP).

### Realm lifecycle (the `realm` addon), switchable

States: **not configured → configured (local | ad-dc | ad-member | ldap) →
running**, with **leave/destroy → reconfigure** so the backend can be switched.

- **Local:** enable Samba `tdbsam`; manage accounts locally.
- **AD local DC:** `samba-tool domain provision --use-rfc2307` (internal DNS, DB
  on the config partition), switch to `samba.service`, enable winbind.
- **AD join:** `net ads join` / `realm join`, configure winbind as a member.
- **OpenLDAP:** configure SSSD against the LDAP server; Samba via `ldapsam` or an
  SSSD-backed member.
- **Status / leave:** report the active backend; tear down to *not configured*.

`/etc/easynas/realm.conf` (config partition) records the backend and parameters.

> **Switching is a re-permission event.** uid/gid numbers differ between
> backends, so switching re-numbers on-disk ownership — existing share group
> assignments must be reapplied (a guided re-ACL step). The UI warns on switch.

### Persistence note per backend

- **Local:** the account store (Samba `tdbsam` + the POSIX passwd/group data)
  **must live on the config partition** so accounts survive an OS reinstall —
  this is the immutable-design §8.3 concern, now scoped to just this backend.
- **AD local DC:** `/var/lib/samba` → config partition.
- **AD join / OpenLDAP:** nothing to persist locally (directory is upstream);
  the winbind/SSSD cache is ephemeral.

### Per-protocol notes

| Protocol | Identity (NSS) | Auth | Notes |
|----------|----------------|------|-------|
| **SSH / FTP / login** | backend NSS | backend PAM | works once a realm is configured |
| **Samba (SMB)** | backend NSS | native / passdb | NT hash from the backend |
| **NFS** | backend NSS | export based | **NFSv4 + idmap** (or squash to the share group). NFSv3 per-user numeric matching across clients is unreliable |
| **future addons** | backend NSS | backend PAM | no work if PAM+NSS aware |

---

## 4. Ownership model

A POSIX filesystem **always** stores ownership as a **numeric uid/gid**, never a
name. Choosing a backend only changes who resolves that number to a name (local
`/etc/passwd`, or winbind/SSSD reading the directory).

### Stable numbers

Ownership must survive a reboot and an OS reinstall.

- **Directory backends** (AD, LDAP): use **RFC2307 / posixAccount** explicit
  `uidNumber`/`gidNumber`, **not** dynamic winbind idmap (which allocates
  per-box and can differ after a rebuild → orphaned files). On the **local DC**
  EasyNAS owns the pool — allocated from a fixed base (e.g. 10000+) and recorded
  — so recreate/migrate yields the same number.
- **Local backend**: uids come from local allocation and are stable **as long as
  the account store persists** (see §3 persistence note).

### Per-share (group) ownership

A share is a directory on a volume, **owned by a directory group** (its
`gidNumber`), with **setgid + `force group` + ACLs** so everything written there
belongs to that group regardless of which member wrote it. Access = group
membership. **The owner of a volume is the group assigned to the share on it.**
(Per-user ownership can be layered on later; per-group is the v1 default because
it sidesteps NFS uid-matching and is simple to reason about.)

- **Before a realm is configured:** a volume is just storage — top dir
  `root:root`. It gains a group owner when a share is assigned.
- **Guest / "everyone" shares:** map to `nobody`, no directory user needed.
- **In the UI:** resolve ownership via `getent`; if unresolved, show the raw
  uid/gid rather than a fake name.
- **On backend switch:** reapply share group assignments (a guided re-ACL step).

---

## 5. What this changes

### Base image (OS layer)
- `samba` + `samba-ad-dc` + winbind **and** SSSD (`sssd-ad`, `sssd-ldap`) present
  on **x86_64 and aarch64** — the backends need different glue.
- Only client/daemon config lives in the image; directory **data** does not.

### Application
- `login.pm` → file-based admin auth (done).
- `users.pm` / `groups.pm` → editable via the backend's tool when **owned**
  (`samba-tool` for AD-DC, `smbpasswd`/`pdbedit`+posix for Local); read-only
  pickers when **consumer**; gated on realm presence.
- `users_info` / `groups_info` (`easynas.pm`) → `getent passwd|group` through
  NSS (filtered by the uid/gid range) — backend-agnostic.
- `realm.pl` (realm addon) → configure / status / leave for all backends.
- `samba.pm` → correct service per backend; shares carry `force group` + setgid.

### Config partition (Layer 2)
- `/etc/easynas/admin.conf`, `/etc/easynas/realm.conf` → persistent.
- Local account store / `/var/lib/samba` (owned backends) → persistent.
- winbind / SSSD cache → ephemeral.

### Immutable-design impact
- Supersedes §8.3: Layer 2 is the admin credential file + realm config + the
  active owned backend's account store, all on the config partition.

---

## 6. Resolved decisions

- **Management auth:** single file-based admin, never a local/directory account.
- **Admin initial password:** first-boot console prompt; no default.
- **Realm = pluggable backend:** **Local (Samba)**, **AD** (local DC or join
  external), **OpenLDAP (external)**; **switchable**.
- **Glue:** winbind for local-DC / AD-member; SSSD for OpenLDAP; `pam_unix` +
  files for Local.
- **uid/gid stability:** RFC2307 / posixAccount explicit numbers for directory
  backends (EasyNAS owns the pool on a local DC); persisted local store for Local.
- **Ownership:** per-share **group** ownership (setgid + `force group` + ACLs);
  pre-realm volumes `root:root`; guest shares map to `nobody`.
- **Owned vs consumer:** Users/Groups editable for Local + AD-local-DC,
  read-only for AD-join + OpenLDAP.
- **Architecture:** realm supported on x86_64 **and** aarch64.

## 7. Open items

- [ ] Internal DNS coexistence with NetworkManager on a **local DC** — the top
      risk; validate in the Phase-2 spike.
- [ ] Persist the **Local** backend's account store on the config partition
      (the §8.3 concern, scoped to this backend).
- [ ] Confirm samba/winbind/SSSD packages install on the aarch64 repos.
- [ ] Backend **switch** flow: reapply share group ownership after a re-number.
- [ ] NFS version policy: standardize on **NFSv4 + idmap** (or squash to group).
- [ ] Migration for pre-existing local accounts into a chosen owned backend.
- [ ] OpenLDAP: schema assumptions (posixAccount/posixGroup), TLS, bind identity.

---

## 8. Phased plan

1. **Admin credential file + `login.pm`** — done (Phase 1).
2. **Realm addon skeleton + backend config** (`realm.conf`, status) + **VM spike
   (AD local DC)** — the richest owned backend; validates winbind, RFC2307 and
   the DNS/NetworkManager risk that the other backends don't have. If this spike
   is painful, reconsider scope before the app rewrite.
3. **Owned-backend user/group CRUD** (Local + AD-local-DC); `users_info` via
   `getent`; gate the pages on realm presence.
4. **Ownership:** per-share group ownership in `samba.pm`; pre-realm volumes
   `root:root`; UI resolves via `getent`.
5. **Consumer backends:** join external AD, then OpenLDAP — read-only pickers.
6. **Backend switching** (leave/rejoin) + the guided re-ACL after a re-number.
7. **Persistence + migration + validation matrix:** config-partition stores;
   local-account migration; every protocol authenticates a directory user on a
   real build (x86_64 + ARM), for each backend.
