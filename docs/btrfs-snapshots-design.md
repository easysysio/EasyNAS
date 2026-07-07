# btrfs Snapshots — Bootable Upgrade Rollback

Status: **SHELVED — reverted to ext4 root.** This Proxmox LXC cannot produce a
bootable btrfs image, so the image ships `filesystem="ext4"` (the config that
built and booted on this host for months). Revisit btrfs snapshot rollback on a
non-container build host (a real VM / bare-metal, or the future Gitea host-mode
x86 runner), where openSUSE's standard `btrfs_root_is_snapshot` works.

**Why it doesn't work in the container (both layouts fail):**

- `btrfs_root_is_snapshot` won't **build**: snapper's `installation-helper
  --step filesystem` fails to create `/.snapshots` in the build chroot. A
  container/chroot limitation, independent of the build fs (fails on ext4 too).
- `btrfs_root_is_subvolume` **builds but won't boot**: GRUB can't resolve
  `@`-relative paths — the prefix (`grub>` CLI) and the kernel/initrd in the menu
  entries (`file '/vmlinuz-…' not found`). A dedicated `/boot` partition
  (`bootpartition="true"`) did **not** fix the kernel-path resolution.

The ext4 **build scratch** (`build.sh` `ensure_build_fs`) stays regardless: KIWI
doesn't support ZFS as its build filesystem, and this is a ZFS-backed LXC. That
is a separate issue from the boot problem above.

**Original design (for the future non-container build), two independent points:**

1. **`btrfs_root_is_snapshot` cannot build in this LXC.** That option runs
   `/usr/lib/snapper/installation-helper --step filesystem` inside the build
   chroot to create `/.snapshots`, and it fails (`creating
   /<root-prefix>/.snapshots failed`). This is a **container/chroot limitation**
   (snapper can't validate the bind-mounted target inside the chroot), and it is
   independent of the build filesystem — it fails identically on ZFS **and** on
   ext4. So we use `btrfs_root_is_subvolume`, which skips the snapper helper.

2. **KIWI does not support ZFS as its build filesystem** (removed years ago,
   confirmed by the maintainers). Separate issue; `build.sh`'s `ensure_build_fs`
   now mounts a **loop-backed ext4 scratch** for the build dir so KIWI builds on
   a supported fs. Necessary for a supported build, but it does **not** make
   `btrfs_root_is_snapshot` work — see #1.

**Boot fix:** with a subvolume root, GRUB's baked prefix
(`(hd0,gptN)/boot/grub2`) doesn't resolve, because GRUB doesn't follow the btrfs
default subvolume and `/boot` lives inside `@`. `bootpartition="true"` puts
`/boot` (and `grub.cfg`) on a plain partition, so GRUB boots directly.

**Rollback caveat:** this delivers snapshot-before-upgrade and the GRUB
"boot from snapshot" recovery menu. openSUSE's one-click permanent `snapper
rollback` wants the build-time snapshot layout (#1), which needs a non-container
build host — a real VM/bare-metal, or the future Gitea host-mode x86 runner.
Author: Yariv Hakim

Give every OS upgrade an automatic, bootable safety net: a snapshot is taken
before the upgrade, and if it goes wrong you reboot and pick the previous
snapshot from GRUB. This is openSUSE's native update-safety model — no custom
tooling.

---

## 1. Scope: Level 1 (read-write root + snapshots)

Two levels exist; we take the lighter one.

| | Level 1 (chosen) | Level 2 (not now) |
|---|---|---|
| root | normal read-write btrfs | read-only + transactional-update |
| snapshots | before/after every zypper transaction | per atomic update |
| rollback | boot a snapshot from GRUB | + auto-rollback on boot failure |
| immutability conflicts | **none to solve** | must solve §8 conflicts |

Level 1 delivers "snapshot before upgrade, boot to it anytime" with minimal
disruption. Level 2 (MicroOS model) is a later option if auto-rollback is
wanted; it depends on the immutable-design §8 conflict fixes.

---

## 2. Mechanism (all stock openSUSE)

| Package | Role |
|---------|------|
| `snapper` | snapshot management |
| `snapper-zypp-plugin` | auto-snapshot **before + after every zypper transaction** |
| `grub2-snapper-plugin` | GRUB "Boot from snapshot" submenu |
| `btrfsprogs`, `btrfsmaintenance` | already present |

Flow: `zypper up easynas` → pre-snapshot → upgrade → post-snapshot. Bad result
→ reboot → GRUB → *Start bootloader from a read-only snapshot* → previous OS.

### Version-labeled snapshots + "keep last 3"

Rather than rely on the zypp-plugin's generic auto-snapshots, EasyNAS takes an
**explicit, version-labeled snapshot before each upgrade**, in the update flow
(console "Check for updates" / "Reinstall", and the Firmware page):

```bash
snapper create --cleanup number \
  --description "EasyNAS $(rpm -q --qf '%{VERSION}-%{RELEASE}' easynas)" \
  --userdata "easynas=upgrade"
```

The description appears in `snapper list` **and the GRUB rollback menu**, so the
user picks a rollback point by version — "EasyNAS 1.99-3" — not by date/number.

**Retention: keep the last 3 upgrades.** The snapshots are tagged
`userdata easynas=upgrade`; after creating a new one, prune EasyNAS's own tagged
snapshots to the newest 3 (self-managed, so it's exactly "last 3 EasyNAS
upgrades" regardless of any other snapshot activity). To avoid noise, quiet the
`snapper-zypp-plugin` auto-pairs so the version-labeled ones are the only
upgrade snapshots the user sees.

---

## 3. Subvolume layout

Root (`@`) is snapshotted; everything that must **not** roll back with the OS
lives on an excluded subvolume.

| Path | In root snapshot? | Why |
|------|-------------------|-----|
| `/` incl. `/usr`, `/etc`, **`/easynas`** (app) | **yes** | OS + app + base config roll back together — no version skew |
| `/var` (cow=false) → incl. **`/var/log/easynas`** | no (excluded) | logs must survive a rollback |
| `/home`, `/tmp`, `/opt`, `/srv`, `/usr/local` | no (excluded) | openSUSE defaults |
| `/.snapshots` | n/a | snapshot storage |

> **Correction vs. the old RPi profile:** it put `/easynas` (the app) on its own
> subvolume *outside* root snapshots — a rollback would have reverted the OS but
> not the app, desyncing them. Here `/easynas` stays **inside** root so
> app+OS+config revert as one unit.

### `/etc/easynas` placement

- **Bootstrap (no data pool yet):** on root → inside the snapshot, so a rollback
  reverts settings with the OS. Acceptable (fresh box, little to lose).
- **After first pool:** `/etc/easynas` is bind-mounted from the **data pool**
  (see identity/reinstall design) → physically **outside** the btrfs root, so
  snapshots/rollback don't touch it at all. This is the steady state and it
  resolves the exclusion question for free.

So we do **not** need a special excluded subvolume for `/etc/easynas`: root
during bootstrap, data pool thereafter.

---

## 4. KIWI changes (per profile)

Apply uniformly to all five profiles (one payload principle):

- `<type filesystem="btrfs" ... btrfs_root_is_subvolume="true">`
  (replaces `filesystem="ext4"`). Root is the plain `@` subvolume; the
  `.snapshots` layout is created on first boot (see Status above), not at build,
  because snapper's installation-helper can't run in the LXC build chroot.
- `<systemdisk>` with the excluded volumes:
  ```xml
  <systemdisk>
    <volume name="home"/>
    <volume name="opt"/>
    <volume name="srv"/>
    <volume name="tmp"/>
    <volume name="usr/local"/>
    <volume name="var" copy_on_write="false"/>
  </systemdisk>
  ```
  (No `easynas` volume — deliberately.)
- Add `snapper`, `snapper-zypp-plugin`, `grub2-snapper-plugin` to the shared
  package list.
- Keep the `CONFIG` custom partition as-is (orthogonal to snapshots).
- x86: keep `eficsm="false"`; aarch64/RPi: btrfs already worked there before.

---

## 5. How it fits the rest

Two orthogonal safety mechanisms, both kept:

| Event | Mechanism | Scope |
|-------|-----------|-------|
| **Bad upgrade** | btrfs snapshot → boot previous snapshot | system disk, local |
| **Reinstall** (full ISO) | data-pool records + disk rediscovery | snapshots are wiped with the disk |

Snapshots protect *upgrades*; they do **not** survive a full reinstall (they're
on the system disk). Reinstall survival still relies on the data pool.

And the in-place upgrade requirement ("update root but not `/etc/easynas`,
`/etc/fstab`, `/var/log/easynas`") is satisfied by the package upgrade itself —
snapshots are the *rollback* net on top of it.

---

## 6. Sequencing & validation

1. **First:** validate the current **ext4** ISO end-to-end (boot, console, NFS).
2. Switch profiles to btrfs + snapper as one change; rebuild all.
3. Validate: `snapper list` shows pre/post snapshots after a `zypper up`; the
   GRUB "boot from snapshot" entry appears and boots the old root; `/var/log`
   and data survive a rollback.
4. Confirm cross-arch btrfs build works under emulation (ext4 was proven; btrfs
   uses a different disk-builder path — re-test the container build).

## 7. Open items

- [ ] Confirm GRUB snapshot submenu renders with the EasyNAS theme and shows
      the version-labeled descriptions.
- [ ] Decide whether firstboot/console exposes a "rollback" hint to users.
- [ ] Re-validate the container cross-arch build with btrfs root.
- [ ] Wire the pre-upgrade `snapper create` + prune-to-3 into the update flow
      (firmware.pm and console options 5/6); quiet the zypp-plugin auto-pairs.
