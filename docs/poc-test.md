# Proof-of-Concept Test — Persistent Config Partition

Goal: prove the two behaviours from the immutable design **before** building the
full integration. Not all NAS features need to work — only:

1. **Upgrade is persistent** — an in-place OS upgrade keeps the config partition.
2. **Full install rewrites everything** — installing from the ISO wipes it.

This PoC uses a neutral `/config` mount (not `/etc/easynas`) so we test the
mechanism without the `/etc/easynas` shadowing/seeding work. See
[immutable-design.md](immutable-design.md) §8.

## What was changed

- `EasyNAS-build/config/EasyNAS.kiwi`, **Testing.x86_64** profile: a custom
  `<partitions>` entry — a 512 MB ext4 `config` partition mounted at `/config`.

> KIWI NG custom-partition syntax (`<partitions><partition .../></partitions>`
> at the `<type>` level). The legacy `spare_part` form is NOT in current KIWI.
> The filesystem label is the partition name uppercased → **`CONFIG`**.
> Note: `spare` is a reserved partition name and cannot be used.

## Key idea

| Operation | Mechanism | Expected effect on `/config` |
|-----------|-----------|------------------------------|
| **Full install** | boot the Testing ISO, install (repartitions disk) | recreated **empty** |
| **Upgrade** | **in-place** `transactional-update dup` / `zypper up` from the repo | **untouched** |

"Upgrade" is an online, in-place update on the running system — **not**
re-running the ISO. Re-running the ISO is always a full install.

## Test procedure

### 1. Build the testing ISO
```bash
cd EasyNAS-build
./build.sh --testing
```

### 2. Full install into a VM
Boot the ISO in a VM (QEMU/VirtualBox), let it install, reboot into the system.

### 3. Confirm the config partition and drop a marker
```bash
mount | grep /config            # spare_part mounted at /config
cat /etc/ImageVersion           # note the OS image version
echo "persist-test-1" > /config/marker
```

### 4. Perform an in-place upgrade
Publish a newer `easynas` RPM to the repo (bump Release), then on the VM:
```bash
# transactional model:
transactional-update dup && reboot
# or plain:
zypper ref && zypper up easynas && reboot
```

### 5. Verify upgrade persistence  ✅ test 1
```bash
cat /etc/ImageVersion           # CHANGED -> the OS/app upgraded
cat /config/marker              # still "persist-test-1" -> config SURVIVED
```
Pass = version changed **and** marker survived.

### 6. Full reinstall from the ISO  ✅ test 2
Boot the Testing ISO again and reinstall to the same disk. After reboot:
```bash
cat /config/marker              # No such file -> config WIPED
```
Pass = marker is gone.

## If it passes

The concept holds: config persists across in-place upgrades and is wiped on full
install. Next steps are the real integration — mount the config partition at the
actual Layer 2 locations and seed them (immutable-design §8.2–8.3), and adopt
`transactional-update dup` as the official upgrade path (§9.2).

## If the config partition doesn't persist

1. Confirm the `<partitions>` entry produced a `CONFIG`-labelled partition on
   the installed disk (`blkid`, `lsblk`).
2. If the OEM installer wipes it on *recovery* too, recovery must rewrite only
   the root partition (see iso-recovery-design.md), not repartition the disk.
3. Longer term, the btrfs-subvolume approach used by the RPi profile, or KIWI's
   native `oem-recovery` archive (restores root, leaves `config` intact).
