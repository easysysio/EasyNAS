<div align="center">

# EasyNAS

**A free, open-source Network Attached Storage appliance**

Turn any 64-bit machine — a spare PC, a home server, or an ARM board — into a
full-featured NAS with a clean web interface, btrfs storage, and one-click
file sharing.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Built on openSUSE](https://img.shields.io/badge/built%20on-openSUSE%20Tumbleweed-73ba25.svg)](https://www.opensuse.org/)
![Platform](https://img.shields.io/badge/arch-x86__64%20%7C%20aarch64-informational.svg)

[Website](https://www.easynas.org) · [Documentation](https://docs.easysys.io/easynas) · [Downloads](https://repo.easysys.io/easynas)

</div>

---

## Overview

EasyNAS is a self-contained storage appliance built on **openSUSE Tumbleweed**
and packaged as a bootable installer image with the [KIWI](https://osinside.github.io/kiwi/)
appliance builder. You install it to a disk, answer a short first-boot wizard,
then manage everything from your browser — no Linux administration required.

The management interface is a [Mojolicious](https://mojolicious.org/) (Perl) web
application. Storage is built on **btrfs**, giving you software RAID, transparent
compression, snapshots, and self-healing pools that survive an OS reinstall.

> EasyNAS is part of the [EasySYS](https://www.easysys.org) family of open
> infrastructure appliances.

## Features

- **btrfs storage pools** — single-disk, RAID 0/1/5/6/10, add or remove disks
  online, transparent compression, and scrubbing.
- **Self-describing pools** — storage carries its own identity on-disk, so pools
  are rediscovered automatically after an OS reinstall or hardware move.
- **One-click file sharing** — Samba (SMB/CIFS), NFS, FTP, AFP, TFTP, rsync, and
  SSH, each installable as an optional add-on.
- **Dashboard monitoring** — live CPU, memory, and filesystem usage at a glance.
- **Web management** — disks, volumes, shares, users, groups, and networking from
  an HTTPS interface (self-signed certificate generated on first boot).
- **Console menu** — a text menu on the local console for IP/status, reinstall,
  restart, shutdown, and a rescue shell.
- **First-boot wizard** — timezone, license agreement, and network setup on the
  very first power-on.
- **Multi-architecture** — x86_64, Raspberry Pi, and generic ARM64 boards, plus a
  ready-to-run virtual-machine image.
- **Stable & testing channels** — signed zypper repositories with automatic
  update checks.

## Add-ons

Optional capabilities ship as separate packages so the base appliance stays lean.
Install them from the **Add-ons** page in the web interface.

| Category | Add-ons |
|----------|---------|
| **File sharing** | Samba, NFS, FTP, AFP, TFTP, rsync, SSH |
| **Media** | DLNA, Plex |
| **Services** | LXC containers, MariaDB, RADIUS |
| **Storage** | iSCSI target |
| **Languages** | German, Portuguese, Chinese, Polish |

## Supported platforms

| Image | Target | Format |
|-------|--------|--------|
| `x86_64` | Standard PCs and servers (BIOS/UEFI) | Install ISO |
| `Raspberry Pi` | Raspberry Pi 3/4/CM (aarch64) | Raw disk image |
| `ARM64` | Generic UEFI ARM64 boards (Orange Pi, Rock, CM3588, …) | Raw + installer |
| `VM` | Virtual machines (KVM/QEMU, Proxmox) | qcow2 |

## Installation

1. Download the image for your platform from **[repo.easysys.io/easynas](https://repo.easysys.io/easynas)**.
2. Write it to a USB stick or disk:
   ```bash
   # x86_64 installer ISO
   sudo dd if=EasyNAS.x86_64-1.99.install.iso of=/dev/sdX bs=4M status=progress oflag=sync

   # ARM board raw image (decompress first if .xz)
   xzcat EasyNAS.aarch64-1.99.raw.xz | sudo dd of=/dev/sdX bs=4M status=progress oflag=sync
   ```
3. Boot the target machine from it. The x86_64 installer copies EasyNAS to the
   internal disk and reboots; ARM images boot directly from the written media.
4. Complete the **first-boot wizard** (timezone, license, network).

## Getting started

Once installed, the console shows the address to connect to:

```
Browse to https://<appliance-ip>:1443 to configure EasyNAS
```

Open that URL in your browser (accept the self-signed certificate) and sign in
with the administrator account created during first boot. From there you can:

1. **Disks** → wipe and prepare drives.
2. **Volumes** → create a btrfs pool (choose your RAID level).
3. **Filesystems** → create and mount subvolumes.
4. **Add-ons** → enable Samba/NFS/… and publish shares.

The local console also offers a menu for status, reinstall, and a rescue shell.
The web interface listens on port **1443** by default; change it in
`/etc/easynas/easynas.conf` (`EASYNAS_PORT=`).

## Architecture

```
┌──────────────────────────────────────────────┐
│  Web UI  (Mojolicious / Perl, HTTPS :1443)     │
│  script/easy_nas → lib/EasyNAS/Controller/*.pm │
├──────────────────────────────────────────────┤
│  Add-ons (RPM subpackages: fs-*, srv-*, mm-*)  │
├──────────────────────────────────────────────┤
│  Storage: btrfs pools, self-describing, self-  │
│  healing after reinstall                       │
├──────────────────────────────────────────────┤
│  Base OS: openSUSE Tumbleweed (KIWI appliance) │
└──────────────────────────────────────────────┘
```

- Configuration lives on a dedicated **config partition** (`/config`) that is
  independent of the OS, so a reinstall preserves settings and storage.
- Updates replace the OS/application via signed zypper repositories rather than
  patching in place, keeping every appliance on a known-good image.

## Repository layout

| Path | Purpose |
|------|---------|
| `script/easy_nas` | Mojolicious application entry point |
| `lib/EasyNAS/Controller/` | Web controllers (dashboard, disk, volume, filesystem, samba, nfs, …) |
| `templates/`, `public/` | Views and static assets |
| `lang/` | Translations |
| `addons/*.easynas` | Add-on manifests (name, service, dependencies) |
| `startup/` | Console menu (`easynas.sh`), first-boot wizard, update checker |
| `docs/` | Design documents |

## Documentation

Full documentation is hosted at **[docs.easysys.io/easynas](https://docs.easysys.io/easynas)**.
Design notes for internals (immutable OS, storage recovery, snapshots, identity)
live under [`docs/`](docs/).

## Contributing

Issues and pull requests are welcome. The web application is written in Perl
(Mojolicious); add-ons follow the pattern in `lib/EasyNAS/Controller/` and a
matching `addons/<name>.easynas` manifest.

## License

EasyNAS is free software, released under the **GNU General Public License v3.0**.
See [LICENSE](https://www.gnu.org/licenses/gpl-3.0) for details.

Created by **Yariv Hakim** — © 2012–2026.
