# EasyNAS Immutable-OS / Image-Update Design

Status: **Proposed**
Author: Yariv Hakim

This document describes how EasyNAS moves from a single mutable install to an
**immutable-OS appliance** where:

1. **Full install** (from the ISO) rewrites *everything*, including settings — a clean slate.
2. **Upgrade** replaces *only the OS part*, preserving user settings and data.
3. The OS part is published and fetched **over the internet**.

---

## 1. The three layers

The whole design rests on splitting the system into three independent layers.
Updates only ever touch Layer 1.

| Layer | Contents | Mutability | Touched by upgrade? |
|------|----------|-----------|---------------------|
| **1. OS image** | base OS + `/easynas` app code + static units/config | read-only, replaceable | **Yes — replaced** |
| **2. Config** | user/group accounts, certs, `/etc/easynas`, fstab entries for data, NetworkManager profiles, cron | read-write, persistent | No |
| **3. Data** | the user's btrfs NAS pools, subvolumes, snapshots | read-write, on separate disks | No |

---

## 2. Disk layout

```
SYSTEM DISK
 ├─ ESP (EFI)         bootloader + active-slot pointer
 ├─ root-A   (ro)  ┐  OS image slot  (incl. /easynas app code)
 ├─ root-B   (ro)  ┘  inactive slot receives upgrades
 └─ config   (rw)     persistent settings (Layer 2)

DATA DISKS (separate)
 └─ btrfs NAS pools (Layer 3) — never touched by install or upgrade
```

With `transactional-update` (recommended, see §4) the A/B slots are btrfs
read-only **snapshots** rather than fixed partitions, and `config` is a
persistent subvolume excluded from snapshots.

---

## 3. The two flows

### Full install (from ISO) — rewrites everything
1. Partition the system disk.
2. Write the OS image to root-A.
3. **Format `config` and seed it with factory defaults** → settings wiped.
4. Install bootloader pointing at root-A.

### Upgrade (over the internet) — OS only
1. Fetch the new OS from `repo.easynas.org`.
2. Apply it into the **inactive** slot (root-B / new snapshot).
3. Flip the boot pointer; reboot.
4. `config` and data disks are never written → settings + data survive.
5. If the new slot fails to boot → automatic rollback to the previous slot.

---

## 4. Implementation paths

### Path A — `transactional-update` + read-only btrfs root  *(recommended)*
- Native to openSUSE; **reuses the existing KIWI build, RPM repo, and firmware module**.
- The "OS image" is a read-only btrfs snapshot; `transactional-update dup`
  pulls from the existing zypper repo into a new snapshot and reboots into it.
- Rollback via snapper + GRUB.
- Lowest new infrastructure; the "OS over the internet" is just the current repo.

### Path B — RAUC + true A/B partition images
- Industry-standard image-based updates: signed bundles, bootloader-integrated,
  atomic, auto-rollback.
- Requires building/hosting full slot images and integrating RAUC into GRUB.
- Reserve for when signed image bundles are wanted.

**Decision: Path A**, because it meets all three requirements with the least
new machinery and keeps the RPM/KIWI pipeline intact.

---

## 5. Runtime path inventory (what goes where)

### Layer 1 — OS image (read-only)
- `/easynas/**` (lib, templates, public, script, startup, addons, lang)
- `/usr/lib/systemd/system/easynas.service` *(see Conflict #1)*
- `/usr/lib/systemd/system/easynas-sshd.service`
- `/etc/sudoers.d/easynas`
- `/etc/zypp/repos.d/*.repo`
- `/etc/easynas/sshd_config`

### Layer 2 — config (persistent, read-write)
| Path | Written by |
|------|-----------|
| `/etc/fstab` (data-pool mounts) | `filesystem.pm` |
| `/etc/passwd`, `/etc/shadow`, `/etc/group` | `users.pm`, `groups.pm` |
| `/var/lib/samba/` passdb | `users.pm` (smbpasswd) |
| `/etc/easynas/easynas.cert`, `.key` | first-boot service *(see Conflict #3)* |
| `/etc/easynas/easynas.lang` | `easynas.pm` |
| `/etc/easynas/easynas.updates` | `firmware.pm` |
| `/etc/easynas/addons/*.addon`, `easynas.addons` | `addons.pm` |
| `/etc/hostname`, `/etc/hosts` | `settings.pm` |
| `/etc/NetworkManager/system-connections/` | `network.pm` |
| `/etc/cron.d/easynas.cron` | `filesystem.pm`, `volume.pm` *(see Conflict #2)* |
| `/var/log/easynas/easynas.log` | `write_log` |

### Layer 3 — data (separate disks)
- `/mnt/<fs>` btrfs pools + subvolumes/snapshots (managed by `volume.pm`).

---

## 6. Conflicts to fix (code writes into would-be read-only Layer 1)

These block immutability and must be fixed first. They are independent of the
chosen swap mechanism.

1. **Port change edits the systemd unit in place.**
   `settings.pm` does `sed -i` on `/usr/lib/systemd/system/easynas.service`.
   → Move the port to a writable **drop-in**
   (`/etc/systemd/system/easynas.service.d/override.conf`) or an
   `EnvironmentFile` in `/etc/easynas`, and edit *that*.

2. **Cron file is both shipped and runtime-mutated.**
   Installed by the RPM but `sed`-edited by `filesystem.pm` / `volume.pm`.
   → Must live entirely on the `config` layer, seeded once at first boot.

3. **SSL cert generated in RPM `%post`.**
   In an image model `%post` runs at build time → every appliance ships the
   same key, or it regenerates on every update.
   → Generate via a **first-boot service** that writes to persistent
   `/etc/easynas/` only if the cert is absent.

---

## 7. Factory reset

`startup/easynas.sh` currently runs `tar -xf settings.tar -C /`.
In the immutable model, factory reset = **reset the `config` layer to defaults**
(or roll to the base snapshot), leaving Layer 1 and Layer 3 untouched.

---

## 8. Task checklist

- [ ] Carve Layer 2 onto a persistent partition/subvolume; bind-mount paths.
- [ ] Fix Conflict #1 — systemd port drop-in.
- [ ] Fix Conflict #2 — relocate cron to `config`, seed at first boot.
- [ ] Fix Conflict #3 — cert generation via first-boot service.
- [ ] KIWI: read-only btrfs root + snapshot layout + persistent `config` volume.
- [ ] Build pipeline: produce install ISO (full) + OS update (published online).
- [ ] Firmware module: "Upgrade" calls `transactional-update dup`.
- [ ] Rework factory reset to reset the `config` layer.
