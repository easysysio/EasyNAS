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

## DECISION A — dedicated staging partition

A dedicated **STAGING** partition on the system disk holds the downloaded
`.raw.xz`. The writer streams it (`xz -dc … | dd`), so it only stores the
**compressed** image; size it for that plus headroom for image growth —
**~4 GB** (current image is ~2 GB compressed). It is:
- big enough for the compressed image (2 GB RAM rules out RAM; CONFIG at 512 MB
  is too small; root can't be used since the writer overwrites it);
- **never** touched by the writer (like CONFIG/swap), so a re-download survives a
  failed write.

New system-disk layout: **EFI · swap · CONFIG · STAGING · root**.

## DECISION B — writer + USB-reinstall recovery

Single root, no A/B. Mitigations:
- **Verify sha256 (and GPG sig) before writing** — never start a write on a bad
  image.
- If a write is interrupted, root is unbootable; recovery is the **USB/ISO
  reinstall**, which always works and **preserves CONFIG + data pools** — so the
  worst case is reinstall-from-USB, not data loss. Documented as the recovery
  path.
- The staged image and flag persist on the STAGING/CONFIG partitions, so a failed
  attempt can be retried from USB or re-flagged.

A/B dual-root (write to inactive slot, bootloader flip, auto-rollback) stays on
the roadmap for atomic, self-healing updates — a later, bigger project.

---

## 5. Naming / UI

- **Update** (existing Firmware page) → the App/RPM track.
- **Core Update** / **Firmware Update** → this image track (new action/page).

## 6. Phases

1. [x] **Publishing** — `build.sh` `publish_core_image()`: `.raw.xz` + `.sha256` +
   `latest.<arch>` manifest in OUTPUT_DIR (commit 138186f). GPG `.sig` still TODO.
2. [x] **Appliance check** — `firmware.pm` `core_update_available()` compares the
   channel `latest.<arch>` version to `/etc/ImageVersion`; the Firmware page shows
   "A core update is available: X" (commit 97f41c9).
3. [ ] **STAGING partition** — add `EFI·swap·CONFIG·STAGING·root` to the KIWI blocks.
4. [ ] **Download + verify + stage + flag** — Core Update controller action.
5. [ ] **Writer** — dracut module: write EFI+root from the staged image.
6. [ ] **UI** — Core Update action/page + progress + reboot.

**Known versioning caveat:** `/etc/ImageVersion` is written by the easynas RPM, so
an *app* RPM update also bumps it. The core check therefore compares against the
app version, not a pure OS-image version — good enough now (a newer published
image is offered), but to be precise the OS-image version should be stamped at
image-build time (config.sh), independent of the app RPM. Refine before shipping.
