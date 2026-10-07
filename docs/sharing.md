# Sharing

Sharing protocols expose your volumes to the network. NFS, Samba, and SSH ship with the
base image; more protocols install as [add-ons](addons.md).

## NFS

For Linux/UNIX clients.

1. **Sharing → NFS** — enable the service with the toggle.
2. **Add share**: choose a volume and permissions (read-only / read-write).
3. Mount on a client:
   ```bash
   sudo mount -t nfs <nas-ip>:/mnt/<pool>/<volume> /mnt/nas
   ```

Shares are exported to all hosts (`*`) with `sync,no_subtree_check`.
<!-- TODO: per-host export rules -->

## Samba (SMB)

For Windows, macOS, and mixed networks.

<!-- TODO: full Samba page after the module port: enable, add share, guest vs user access,
     Windows/macOS connect walkthrough -->

User accounts created in EasyNAS automatically get Samba credentials.

## SSH / SFTP

**Sharing → SSH** — toggle the dedicated EasyNAS SSH service on/off. Users can then reach
their volumes over SFTP.

## File manager (web)

The **File Manager** add-on (`fs-files`) puts the volumes in the browser: browse,
download, upload, copy, move, rename and delete, with no client to set up.

- **Admin → Add-ons**, install *File Manager*. It appears under **Sharing**.
- NAS users sign in at the same address as the administrator, with the account
  created under **Admin → Users**. They see the file manager and nothing else.
- Everything runs as the signed-in Linux account, so a user can do exactly what
  they could over Samba or SSH: ownership and permission bits decide, and
  membership of a share's group is what gives access to it.
- Pools and volumes themselves are read-only here — create and remove those
  under **Storage**. Files and folders inside a volume are fair game.
- Uploads are sent in pieces, so there is no size limit, and a file only
  appears under its name once it has arrived completely.

!!! note "NAS accounts and the web interface"
    Installing this add-on is what lets NAS accounts sign in to the web
    interface at all; without it, only the administrator can. Remove the add-on
    and they can no longer sign in.

## Other protocols (add-ons)

| Protocol | Add-on | Typical use |
|---|---|---|
| FTP | `fs-ftp` | legacy clients |
| AFP | `fs-afp` | older macOS |
| TFTP | `fs-tftp` | network boot |
| rsync daemon | `fs-rsyncd` | backups/replication |
| iSCSI | `stg-iscsi` | block storage for hypervisors |
| DLNA | `mm-dlna` | media players/TVs |
| Plex | `mm-plex` | media server |

See [Add-ons](addons.md) for installation.
