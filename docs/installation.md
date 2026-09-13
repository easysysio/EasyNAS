# Installation

<!-- TODO: add download links / mirror table once 2.0 images are published -->

## 1. Download

Get the image for your platform from the [downloads page](https://repo.easysys.io/easynas){ .md-button }

| Platform | File |
|---|---|
| x86_64 PC | `EasyNAS.x86_64-<version>.install.iso` |
| Raspberry Pi | `EasyNAS.aarch64-<version>.raw.xz` |
| Generic ARM64 (UEFI) — flash | `EasyNAS.arm64efi-<version>.raw.xz` |
| Generic ARM64 (UEFI) — installer | `EasyNAS.arm64efi-<version>.install.iso` |
| VM (KVM/Proxmox) | `EasyNAS.x86_64-<version>.qcow2` |

## 2. Install

=== "x86_64 PC"

    1. Write the ISO to a USB stick (e.g. with [balenaEtcher](https://etcher.balena.io/) or `dd`).
    2. Boot the target machine from the stick (UEFI mode).
    3. Choose **Install EasyNAS** — this **erases the system disk** and performs a full,
       unattended installation.
    4. Remove the stick when the machine reboots.

    !!! warning
        A full installation wipes everything on the system disk, **including previous
        EasyNAS settings**.

=== "Raspberry Pi"

    1. Decompress and flash the raw image to an SD card or USB/NVMe disk:
       ```bash
       xz -d EasyNAS.aarch64-<version>.raw.xz
       sudo dd if=EasyNAS.aarch64-<version>.raw of=/dev/sdX bs=4M status=progress
       ```
       Pi 4/400/5 boot directly from USB disks (and Pi 5 from NVMe) — flashing the image
       straight onto the disk *is* the installation.
    2. Insert and power on. First boot expands the filesystem to the medium automatically.

    !!! note "Compute Modules (eMMC)"
        On a CM4/CM5, expose the onboard eMMC to your PC with
        [`rpiboot`/usbboot](https://github.com/raspberrypi/usbboot) and flash the same raw
        image directly to it.

=== "Generic ARM64 board"

    One-time board preparation first: install UEFI firmware (e.g. **EDK2 for RK3588**) to
    the board's SPI flash, per your board's documentation. Then choose one of two paths:

    **Flash (removable media, or eMMC/NVMe reachable from a PC):**
    write the raw image to the boot medium exactly as in the Raspberry Pi instructions,
    insert, boot.

    **Installer (onboard eMMC/NVMe you cannot flash externally):**

    1. Write `EasyNAS.arm64efi-<version>.install.iso` to a USB stick.
    2. Boot the board from the stick.
    3. Choose **Install EasyNAS** and select the internal disk (eMMC/NVMe) as the target —
       this erases it and installs, just like the x86 flow.
    4. Remove the stick when the board reboots.

=== "Virtual machine"

    1. Import the qcow2 as a VM disk (Proxmox: `qm importdisk`, or attach in the UI).
    2. Use **UEFI firmware (OVMF)** for the VM; 2+ GB RAM.
    3. Boot — there is no installer pass; first boot expands to the virtual disk size.
    4. Pass through your data disks to the VM for storage pools.

## 3. First boot

On first boot EasyNAS generates its own SSL certificate and seeds its configuration, then
shows the **console menu** with the address of the web UI:

```
Browse to https://<ip-address>:1443 to configure EasyNAS
```

Continue with [Getting started](getting-started.md).

## Install vs. recover

<!-- TODO: document the recovery boot option once it ships; see the design notes -->

EasyNAS keeps your settings on a dedicated partition, separate from the operating system.
A **full installation** recreates everything, settings included. A future **recover**
option will reinstall only the OS and preserve settings.
