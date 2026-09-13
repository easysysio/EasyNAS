# Supported hardware

EasyNAS ships one image per platform. All images contain the same system — only the boot
mechanics differ.

## Platforms

| Platform | Image | Notes |
|---|---|---|
| **x86_64 PC / server** | Install ISO | Requires **UEFI** firmware (roughly 2012 or newer). Legacy-BIOS-only machines are not supported. |
| **Raspberry Pi** | Raw SD/USB image | 64-bit models: **Pi 3 rev 1.2+, Pi 4, Pi 400, Pi 5**. Flash and boot — firmware is included in the image. |
| **Generic ARM64 boards** | Raw disk image (UEFI) | Boards that provide their own UEFI firmware, e.g. **RK3588** family (FriendlyElec CM3588, Orange Pi 5 series) with the EDK2 firmware on SPI flash. |
| **Virtual machine** | qcow2 disk image | KVM / Proxmox / QEMU with UEFI (OVMF). Import and boot — no installer pass. |

## Will my ARM board work?

Three questions, in order:

1. **Is it 64-bit ARM?** If not — no. 32-bit support (ARM and x86) has been discontinued.
2. **Is it a Raspberry Pi?** Use the Raspberry Pi image; the boot firmware is baked in.
3. **Can the board hold UEFI firmware itself** (SPI flash + an EDK2 port or EFI-capable
   U-Boot)? Then flash that firmware once and use the generic ARM64 image. This covers the
   RK3588 family and most "PC-like" ARM boards.

Boards that answer *no* to 2 and 3 (for example most Allwinner-based Orange Pi models) would
need a board-specific image and are **not supported**.

## Minimum requirements

<!-- TODO: validate these numbers on real hardware -->

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 2 GB | 4 GB+ |
| System disk | 8 GB | 16 GB+ (SSD/eMMC/SD) |
| Data disks | 1 | 2+ for RAID |
| Network | 1 GbE | 2.5 GbE+ |

!!! tip "Separate system and data"
    EasyNAS installs the OS on one disk and manages your **data pools on separate disks**.
    The installer erases the system disk only — but keep data disks disconnected during
    installation if you want to be extra safe.
