# EasyNAS Update Model — App (RPM) + Core (RAW image)

Two independent update tracks, on purpose:

| Track | What | How | Cadence |
|-------|------|-----|---------|
| **App update** | all `easynas*` packages (base storage-management UI **and** the service addons — samba, ssh, nfs, ftp, dlna, iscsi, …) | `zypper update --repo <EasyNAS channel>` (see `firmware.pm`) | instant, granular |
| **Core update** ("Firmware update") | the OS + base system as one tested unit | download a signed **RAW image** and write it with a boot-time **writer** | deliberate, less frequent |

The App track is implemented. This doc designs the **Core update**.

---

## 1. Why a writer (not `zypper dup`)

The base is Tumbleweed (rolling). A live `zypper dup` pulls a huge slice of the
rolling stream, fights the appliance's build-only packages (it downgraded
`dracut-kiwi-*` and reset the Plymouth theme), and has no atomic rollback. Instead
the OS ships as a **versioned, tested RAW image**, and a core update replaces the
OS partitions from that image — the same artifact users install from, so what's
tested is what runs.

This fits the existing layout: the persistent **CONFIG partition** already
"survives an in-place upgrade, wiped on full install". A core update rewrites
**EFI + root** and leaves **CONFIG + swap + data pools** intact.

## 2. Publishing

Under `repo.easysys.io/easynas/{stable,testing}/RAW/`:
- `EasyNAS.x86_64-<version>.raw.xz` — the compressed image
- `EasyNAS.x86_64-<version>.raw.xz.sha256` — checksum
- `EasyNAS.x86_64-<version>.raw.xz.sig` — GPG signature (recommended)
- `latest` — a small manifest: current version + filename + sha256

The appliance compares its running core version (`/etc/ImageVersion`) to `latest`.

## 3. Flow

1. **Check** — fetch `latest`; if newer, surface "Core update available: X".
2. **Download** — fetch the `.raw.xz` to the staging area (§5); verify sha256 (and
   GPG sig) *before* trusting it.
3. **Stage + flag** — leave the image where the initramfs can reach it and write a
   one-shot flag (image path + sha256) on the CONFIG partition.
4. **Reboot.**
5. **Writer (initramfs, before root is mounted)** — a dracut module sees the flag,
   re-verifies the checksum, then writes **only the OS partitions**:
   - extract the RAW's EFI and root partitions (loop + partition offsets) and
     `dd` each onto the system disk's matching partition;
   - **do not** touch the system disk's CONFIG or swap, and never the data disks;
   - clear the flag, reboot.
6. **New system boots** — `firstboot.sh` re-applies config from CONFIG; data pools
   are rediscovered from their in-volume markers.

Writing from the initramfs is the key: root isn't mounted yet, so its partition
can be overwritten safely.

## 4. Partition mapping

System disk (from `EasyNAS.kiwi`): **EFI · swap · CONFIG · root**. The new RAW has
the same layout. The writer copies **EFI → EFI** and **root → root** from the RAW
to the system disk, leaving **CONFIG** and **swap** as they are. Match partitions
by GPT name/label (`p.UEFI`, `p.lxroot`, `CONFIG`), not by index, so a layout
change doesn't clobber the wrong slot.

---

## OPEN PROBLEM A — where to stage a ~5.5 GB image on a 2 GB / small-CONFIG box

The `.raw.xz` is ~2 GB compressed, ~5.5 GB uncompressed. Constraints: **2 GB RAM**
(no RAM staging) and a **512 MB CONFIG** partition (too small even for the
compressed file). The writer also can't stage on root (it overwrites root).

Candidate answers (need a decision):
- **Require a data pool** for core updates and stage the `.xz` there; the writer
  reads it from the data disk. Simple, but no core update on a pool-less box.
- **Dedicated staging space** — enlarge CONFIG, or add a small update partition.
- **Stream during the writer** — pull the image over the network *inside* the
  initramfs and write as it downloads (no full local copy). Most flexible, most
  initramfs plumbing (network + verify-while-writing).

## OPEN PROBLEM B — no A/B means a failed write can brick the box

We chose the writer (single root), so a write interrupted mid-way leaves root
corrupt and unbootable — and we can't "retry from the running system" because it's
already gone. Options:
- **Accept it, with a recovery path**: the USB/ISO **reinstall always works** and
  preserves CONFIG + data pools, so "bricked" = reinstall from USB, not data loss.
  Simplest; document it.
- **A/B dual-root** later: write to the inactive slot, flip the bootloader, auto-
  rollback on boot failure. Atomic and safe, but needs a repartition of the image
  and a slot-switcher — a bigger project.

Recommended first version: **writer + USB-reinstall recovery**, decide staging =
"require a data pool" to start, and keep A/B on the roadmap.

---

## 5. Naming / UI

- **Update** (existing Firmware page) → the App/RPM track.
- **Core Update** / **Firmware Update** → this image track (new action/page).

## 6. Phases

1. Publishing: build+push the `.raw.xz` + sha256 + sig + `latest` to the channel.
2. Appliance check: read `/etc/ImageVersion` vs `latest`; surface availability.
3. Download + verify + stage + flag (resolve OPEN PROBLEM A).
4. The initramfs writer dracut module (resolve OPEN PROBLEM B / recovery).
5. UI: the Core Update action, progress, and the reboot.
