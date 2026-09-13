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
