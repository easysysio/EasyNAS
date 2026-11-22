# Add-ons

EasyNAS is modular: the base image stays small, and optional functionality installs as
**add-ons** from the EasyNAS package repository — directly from the web UI.

## Installing

**Admin → Add-ons** lists everything available for your version with install/remove
buttons. Add-ons are ordinary signed packages; updates arrive together with EasyNAS
updates.

<!-- TODO: screenshot; note about restarting the web service after install -->

## Available add-ons

### Sharing protocols

| Add-on | Provides |
|---|---|
| `fs-files` | Web file manager — NAS users sign in with their own account |
| `fs-ftp` | FTP server (pure-ftpd) |
| `fs-afp` | AFP for older macOS (netatalk) |
| `fs-tftp` | TFTP server |
| `fs-rsyncd` | rsync daemon |
| `stg-iscsi` | iSCSI target |

### Media

| Add-on | Provides |
|---|---|
| `mm-dlna` | DLNA media server (minidlna) |

### Services

| Add-on | Provides |
|---|---|
| `srv-lxc` | Linux containers with web terminal |
| `srv-mariadb` | MariaDB database server |
| `srv-radius` | FreeRADIUS server |

### Languages

The web UI is English by default; language packs add translations:

| Add-on | Language |
|---|---|
| `lang-german` | Deutsch |
| `lang-polish` | Polski |
| `lang-portuguese` | Português (BR) |
| `lang-chinese` | 简体中文 |

After installing a language pack, select the language in **Admin → Settings**.

## Containers (LXC)

**Services → Virtualization** runs Linux containers: a whole Linux system
(Debian, Ubuntu, Alpine, openSUSE and more) sharing the NAS's kernel.

1. **Keep them on a volume first.** Click *Keep them on a volume* (or
   *Change*) and pick one. Containers left on the system disk are lost at the
   next firmware update.
2. **Create new System**: name it, pick an image (downloaded from
   images.linuxcontainers.org for your machine), and pick the network:
    - **Private**: an address on a network inside the NAS (10.0.3.x). It
      reaches the internet; other devices can't reach it.
    - **Your network**: its own address from your router. Other devices can
      reach it, but the NAS itself can't.
3. Downloading takes a few minutes; the list shows it as *Creating...* and
   updates by itself.

Then start it, open a **terminal** into it (a new tab on port 8080, for that
one session), turn **Start at boot** on, or delete it. Problems are logged in
`/var/log/easynas/lxc.log`.

<!-- TODO: keep this list generated/synced with the repository -->
