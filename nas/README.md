# Private network share

This is a dedicated SMB share for Windows and macOS on the home LAN.

| Item | Value |
| --- | --- |
| Proxmox container | 108 (`girlfriend-nas`, Debian 13, unprivileged) |
| Host folder | `/lake1t/girlfriend-nas` |
| Container mount | `/srv/nas` |
| Share | `Files` |
| SMB user | `nas` |
| Current DHCP address | `192.168.100.210` (reserve this lease in the router) |
| Windows path | `\\192.168.100.210\Files` |
| macOS path | `smb://192.168.100.210/Files` |

The password was randomly generated during setup. On the Proxmox host, retrieve
it with `pct exec 108 -- cat /root/nas-credentials`. The file is mode `0600`
inside the container. The password is not stored in this repository.

On Windows, open the path above in File Explorer, sign in as `nas`, then use
**This PC > Map network drive** if a persistent drive letter is wanted. On
macOS, use Finder's **Go > Connect to Server** and the `smb://` path.

The checked-in [smb.conf](smb.conf) is the active configuration at
`/etc/samba/smb.conf` in container 108. It accepts SMB2 or newer, requires the
`nas` account, and listens only on the loopback and `192.168.100.0/24` IPv4
interfaces. Port 445 is the only SMB port used; `nmbd` is disabled. If the LAN
subnet changes, update both `interfaces` and `hosts allow`, then copy the file
into the container and restart Samba:

```bash
pct push 108 nas/smb.conf /etc/samba/smb.conf
pct exec 108 -- testparm -s
pct exec 108 -- systemctl restart smbd
```

The share folder belongs to UID/GID `101000` on the host, which maps to the
`nas` account (UID/GID `1000`) in the unprivileged container. Keep the host
folder private; changing its owner to the existing `dockeruser` would break
isolation. Do not mount `/lake1t/data` into this container.

The folder is a Proxmox bind mount, so a container backup does **not** include
its contents. Add `/lake1t/girlfriend-nas` to the host's file backup routine.
The existing pool protects against a disk failure, but it is not a substitute
for an independent backup.

## Maintenance

```bash
pct status 108
pct exec 108 -- systemctl status smbd --no-pager
pct exec 108 -- journalctl -u smbd -n 50 --no-pager
pct exec 108 -- apt-get update
pct exec 108 -- apt-get upgrade
```

To change the password interactively, run `pct exec 108 -- smbpasswd nas`.
Update or remove `/root/nas-credentials` inside the container after a password
change, since that file will otherwise contain the old password.
