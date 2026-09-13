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
| `fs-ftp` | FTP server (pure-ftpd) |
| `fs-afp` | AFP for older macOS (netatalk) |
| `fs-tftp` | TFTP server |
| `fs-rsyncd` | rsync daemon |
| `stg-iscsi` | iSCSI target |

### Media

| Add-on | Provides |
|---|---|
| `mm-dlna` | DLNA media server (minidlna) |
| `mm-plex` | Plex Media Server |

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

<!-- TODO: keep this list generated/synced with the repository -->
