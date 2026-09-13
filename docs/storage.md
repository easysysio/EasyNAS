# Storage

EasyNAS storage is built on **Btrfs**: pools span disks with a chosen RAID profile, and
**volumes** (Btrfs subvolumes) are the units you share, snapshot, and quota.

```
Disks  ──►  File System (Btrfs pool, RAID/compression)  ──►  Volumes  ──►  Shares
```

## Disks

**Storage → Disk** lists every drive with model, capacity, and status:

- **System** — the disk EasyNAS runs from (protected)
- **Used** — part of a filesystem
- **Free** — available for a new filesystem
- **Failed** — SMART problems detected

Disk health (SMART self-test results and Btrfs error counters) is surfaced on the dashboard.

<!-- TODO: wipe/format flow, disk info popup -->

## File systems (pools)

**Storage → File System → Create**:

| Option | Choices | Notes |
|---|---|---|
| Disks | 1..n free disks | |
| RAID profile | JBOD (single), RAID 0, 1, 10, 5, 6 | RAID 5/6 require 3/4+ disks |
| Compression | none, fast (lzo), better (zlib) | transparent, per-pool |
| Mount options | read-write / read-only | |

Existing pools can be mounted/unmounted, renamed, grown by adding devices, and monitored
(usage, health, degraded-array warnings).

<!-- TODO: per-action walkthroughs; scrub scheduling -->

## Volumes

**Storage → Volume** manages subvolumes on a pool: create, delete, set the owner
(user/group), and take **snapshots**.

<!-- TODO: snapshot scheduling and restore flow -->

!!! info "Where your data lives"
    Pools are mounted under `/mnt/<pool>` and volumes at `/mnt/<pool>/<volume>` — these
    are the paths sharing protocols export.
