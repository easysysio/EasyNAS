# Getting started

After installation, EasyNAS boots to the **console menu** on the attached display and serves
its **web UI** on the network.

## 1. Log in

Open `https://<your-nas-ip>:1443` (the exact address is shown on the console).

<!-- TODO: document default credentials & first-login password change policy -->

!!! note "Self-signed certificate"
    EasyNAS generates its own SSL certificate on first boot, so your browser shows a
    one-time security warning. Accept it to continue.

## 2. Set the admin password

Use console menu option **1 (Change admin password)** — or the web UI — before anything
else.

## 3. Tour the dashboard

The dashboard shows the system at a glance:

- **CPU** — usage, load averages, model and core count
- **Memory** — RAM and swap usage
- **Drives** — every disk with health status (SMART)
- **File Systems** — each pool with usage bar and used/total
- Counters for drives, filesystems, volumes, and users

<!-- TODO: dashboard screenshot -->

## 4. Create your first storage

1. **Storage → File System → Create**: pick one or more data disks, a RAID profile, and
   compression. This creates a Btrfs pool.
2. **Storage → Volume → Create**: create a volume (subvolume) on the pool — this is the
   unit you share and snapshot.

See [Storage](storage.md) for concepts and options.

## 5. Share it

1. **Sharing → NFS** (or Samba): enable the service with the toggle.
2. **Add share**, pick your volume and permissions.
3. Mount from a client:
   ```bash
   # NFS example
   sudo mount -t nfs <your-nas-ip>:/mnt/<pool>/<volume> /mnt/nas
   ```

See [Sharing](sharing.md) for per-protocol guides.

## 6. Create users

**Admin → Users**: accounts created here work across the sharing protocols (e.g. Samba
credentials are kept in sync automatically).

## The console menu

The attached display always shows the admin menu:

| Option | Action |
|---|---|
| 1 | Change admin password |
| 2 | Start/Stop EasyNAS web service |
| 3 | Restart network |
| 4 | Reset to default settings |
| 5 | Check for EasyNAS updates |
| 6 | Restart |
| 7 | Shutdown |
| 8 | Shell |
