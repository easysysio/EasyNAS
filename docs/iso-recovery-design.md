# ISO Recovery Design — Reinstall OS, Keep Settings

Status: **Proposed**
Author: Yariv Hakim

## Purpose

The install ISO offers two operations:

1. **Install (erase disk)** — full install, wipes everything (existing behaviour).
2. **Recover (keep settings)** — reinstall the OS when it fails, **preserving the
   `config` partition and data disks**.

There is **no online upgrade**. Recovery is the offline path for a broken OS.
Settings survive because recovery never repartitions — it rewrites only the
root partition and leaves `config` + data untouched.

Relies on the persistent `config` partition from
[poc-test.md](poc-test.md) / [immutable-design.md](immutable-design.md).

---

## Disk model (single root + config)

```
SYSTEM DISK (built with devicepersistency=by-label)
 ├─ ESP            label: e.g. EFI
 ├─ root           label: <ROOT_LABEL>      <- REWRITTEN on recovery
 ├─ swap
 └─ config         label: CONFIG            <- PRESERVED on recovery
DATA DISKS (separate)                        <- never touched
```

`config` is a KIWI custom `<partition name="config">` (label uppercased →
`CONFIG`). Recovery finds partitions by label, so it never depends on device
names (`/dev/sda` vs `nvme…`).

---

## Boot menu (install media)

Add a second GRUB entry to the **install ISO** bootloader:

```
menuentry "Install EasyNAS (ERASE disk)" { ... normal kiwi oem dump ... }
menuentry "Recover EasyNAS (keep settings)" {
    linux  ... easynas.recover=1
    initrd ...
}
```

The `easynas.recover=1` kernel arg selects the recovery path instead of the
default install/deploy path.

> Integration note: the install media boot menu is produced by KIWI. You already
> use an `editbootinstall` hook (RPi). The exact wiring (custom install dracut
> module vs. a live menu) must be validated on a real build — see §"Open".

---

## Recovery algorithm

Run by `recover.sh` in the ISO's install environment:

```
1. SAFETY: find a partition labelled "CONFIG".
   - none found -> ABORT with a message: "No existing EasyNAS install;
     use Install (erase disk) instead." (never silently wipe)

2. Identify the ROOT partition on the SAME disk as "CONFIG" (by label).

3. Confirm with the user (show disk, root part, config part). Require explicit
   yes before writing anything.

4. Source the fresh OS root filesystem from the ISO image
   (loop-mount the deployed image / squashfs shipped on the media).

5. Replace the OS on the existing root partition ONLY:
   - mkfs the root partition (same fs as the image, ext4), or rsync --delete.
   - copy the fresh OS root into it.
   - DO NOT touch the config or data partitions.

6. Fix up the new root's /etc/fstab:
   - ensure the config mount entry exists (by LABEL=CONFIG -> /config).
   - data-pool mounts are managed by EasyNAS at runtime; leave them.

7. Reinstall GRUB to the disk ESP, pointing at the recovered root.

8. Reboot.
```

After reboot, `firstboot.sh` runs, sees `config` already populated, and leaves
it as-is → **settings preserved**. A fresh `config` (full install) is seeded
from defaults → **settings reset**. Same script, opposite outcome — exactly the
two behaviours we want.

---

## Alternative: KIWI native recovery (`oem-recovery`)

KIWI has a built-in recovery system (confirmed in this build's schema):

| Element | Effect |
|---------|--------|
| `<oem-recovery>true</oem-recovery>` | create a recovery archive of the system |
| `<oem-inplace-recovery>true` | build the archive at install time (not stored in the image) |
| `<oem-recovery-part-size>` | size of the on-disk recovery partition (MB) |
| `<oem-recoveryID>` | recovery partition ID (default 83) |

This creates an **on-disk recovery partition** holding a factory archive of the
**root** system; a boot-time recovery restores root from it. Combined with the
separate `config` partition (not part of the root archive), it restores the OS
and **leaves settings intact** — the same outcome as the custom script, but:

- **Pro:** native/maintained by KIWI; recovers from the local disk (no ISO
  needed if root is bootable-enough to reach the recovery entry).
- **Con:** recovery archive lives on the disk, so it can't help if the whole
  disk is lost; for a *fully* dead disk you still boot the ISO.

**Recommendation:** use `oem-recovery` as the primary recovery path (on-disk,
no media), and keep the ISO `recover.sh` as the fallback for a disk that won't
boot at all. Decide before wiring the boot menu.

---

## Safety rules (non-negotiable)

- **Never repartition** in recovery mode.
- **Abort if no `config` partition** is found (don't fall back to wiping).
- **Explicit confirmation** showing exactly which root partition will be
  overwritten before any destructive action.
- Operate strictly by **label**, never by assumed device names.

---

## Open / validate on a real build

- [ ] How the install ISO exposes the boot menu + passes `easynas.recover=1`
      (custom install dracut module vs. live menu vs. `editbootinstall`).
- [ ] Where/what form the OS root fs takes on the install media (raw disk image
      to loop-mount vs. squashfs) — determines step 4.
- [ ] Exact `<ROOT_LABEL>` KIWI assigns to the root partition.
- [ ] GRUB reinstall command set for this firmware (efi) layout.
- [ ] Confirm `config` survives `mkfs` of root (it must — different partition).

---

## Test (extends poc-test.md)

1. Full install; set a marker on `/config`.
2. Break the OS (e.g. `rm` a critical bit, or just simulate).
3. Boot ISO → **Recover (keep settings)**.
4. After reboot: OS is fresh **and** `/config/marker` survived → recovery works.
5. Boot ISO → **Install (erase disk)**; confirm `/config/marker` is gone.
