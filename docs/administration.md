# Administration

## Settings

**Admin → Settings**:

- **Hostname** — the NAS's network name
- **Web UI port** — default `1443` (HTTPS); stored in the persistent configuration, so it
  survives updates
- **Language** — after installing a [language add-on](addons.md#languages)

## Users & groups

**Admin → Users / Groups** manage the accounts that sharing protocols authenticate
against. Creating a user sets up shell and Samba credentials together; volumes can be
owned by a user/group from the Storage pages.

<!-- TODO: roles/permissions model; planned directory integration -->

## Updates

**Admin → Firmware** checks the EasyNAS repository and installs updates to EasyNAS and
its add-ons. The console menu (option 5) does the same from the terminal.

<!-- TODO: OS security updates policy; document once the update channel strategy ships -->

## Network

**Admin → Network** configures interfaces: DHCP or static IPv4, gateway, and DNS.
Console menu option 3 restarts networking if you lock yourself out.

## Logs

EasyNAS writes an application log to `/var/log/easynas/easynas.log` (shell access via
console menu option 8, or SSH).

## Factory reset

Console menu option **4 (Reset to default settings)** restores the default configuration
and reboots.

<!-- TODO: exactly what is reset vs preserved (data pools are untouched) -->
