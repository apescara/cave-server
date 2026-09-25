# Backups

The Proxmox host has two daily jobs writing to `/seagate4t/backups`:

| Time (host local) | Job | Retention |
| --- | --- | --- |
| 04:30 | Proxmox `cave-daily`: snapshot-mode backups of all LXCs and VMs to `cave-backups` | Three latest per guest |
| 06:30 | `scripts/backup-critical-data.sh`: app configuration, logical database dumps, latest Immich SQL export, and host configuration | Seven days of completed runs |

The first job includes guest root disks, including migrated SSD app data under
`/var/lib/cave-appdata`, but **not** host bind mounts such as
`/lake1t/data` or `/seagate4t/data`. It excludes `/var/lib/docker`,
`/var/lib/containerd`, and `/root/.config/bookshelf` inside guests. Docker
images can be repulled; the latter path was unreadable in LXC 102 during the
first backup. The second job copies the repository from
`/lake1t/data/cave-server`, including Compose files and `.env` files, while
excluding migrated, stale app data directories. It also
creates live logical dumps for Jellystat PostgreSQL and Grimmory MariaDB. It
copies the newest Immich database export made by Immich itself. A temporary
ZFS snapshot provides a point-in-time source for the file copy, and is removed
when the job ends. Generated Jellyfin cache, logs, and metadata, and Immich's
raw PostgreSQL files are excluded from the second job. Restore the current
Immich database from the guest backup, or use its SQL export for logical recovery.

These jobs do **not** back up the bulk media libraries, downloads, or Immich
photo and video originals. The Seagate disk does not have enough free space for
a full copy of `lake1t`. Data already on `seagate4t` is not protected from a
failure of that disk. Use an external disk, NAS, or Proxmox Backup Server for
complete independent protection.

## Check a backup

```bash
pvesh get /cluster/backup
ls -lh /seagate4t/backups/proxmox/dump/
readlink -f /seagate4t/backups/critical/latest
ls -lh /seagate4t/backups/critical/latest/databases/
tail -50 /var/log/cave-critical-backup.log
```

Proxmox guest archives can be restored from Datacenter > Backup in the UI.
For SSD application data, restore the whole guest or restore its archive to a
temporary guest ID, stop the affected service in the original guest, and copy
the relevant `/var/lib/cave-appdata/` directory from the temporary guest.
Restore Compose and `.env` files from
`/seagate4t/backups/critical/latest/cave-server/docker/`. The logical database
dumps are in `databases/`; the Immich export is in `immich-db/`. Backup
directories contain credentials and are intended to be readable only by the
host administrator.

Do not treat archive creation as a restore test. Periodically restore a guest
to a temporary ID and verify a database dump or application on a test system.
