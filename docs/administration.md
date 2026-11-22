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

### Your own password

**User Profile** (your name at the top right) changes the password of the
account you're signed in with, after you enter the current one. For `admin`
that is the web interface's password; for any other account it is also their
password for the file shares (Samba, SSH, FTP). NAS users signed in to the
[File Manager](sharing.md#file-manager-web) reach the same page. Wrong current
passwords count towards the same lockout as wrong sign-ins.

### Administrators

Tick **Administrator** when you create a user (or later, in the user's
**Settings**) to let that person run the appliance with their own account. They
sign in at the same address as `admin`, with their own user name and password,
and can change every setting, just like `admin`.

- Untick it, or delete the user, and their open sessions end on their next
  click: they are sent back to the sign-in page.
- Each sign-in as an administrator, and each change to the flag, is logged.
- The flag is membership of the `easynas-admins` system group, which the
  **Groups** page doesn't list.

!!! warning
    An administrator's password is also their password for the file shares
    (Samba, SSH, FTP). Make it as strong as the `admin` password.

## Updates

**Admin → Add-ons** checks the EasyNAS repository and installs updates to EasyNAS and
its add-ons: the EasyNAS tile updates the core, **Update all** updates everything
that has an update. The console menu (option 5) does the same from the terminal.

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
