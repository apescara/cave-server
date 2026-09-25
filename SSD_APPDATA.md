# SSD app data migration

The active Docker configuration and databases below live on each LXC's
`local-lvm` root disk at `/var/lib/cave-appdata`. Media, downloads, and Immich
uploads remain on their existing `lake1t` or `seagate4t` bind mounts. Docker
images and layers remain under `/var/lib/docker` on the guest root disk.

| LXC | SSD app data |
| --- | --- |
| 100 | Jellyfin config, cache, logs |
| 101 | qBittorrent config |
| 102 | Prowlarr, Radarr, Sonarr, Bazarr, Shelfarr, Audiobookshelf, Grimmory data and MariaDB |
| 103 | Seerr config, Jellystat data and PostgreSQL |
| 104 | Homarr data, File Browser database and config |
| 105 | Immich PostgreSQL (`DB_DATA_LOCATION` in its untracked `.env`) |

The old app data directories in the repository were retained for rollback, but
they are no longer live and are excluded from the nightly critical-data copy.
The 04:30 Proxmox backups to `cave-backups` include `/var/lib/cave-appdata`.
The 06:30 critical-data job saves Compose and `.env` files plus logical
database exports. See [BACKUPS.md](BACKUPS.md) for the restore procedure and
remaining coverage gaps.

## Rollback one service

Stop the affected Compose service, then copy its current SSD directory back to
the corresponding old repository directory with `rsync -aHAX --numeric-ids`.
Change that service's Compose bind mount back to the old path and restart only
that service. For Immich, change `DB_DATA_LOCATION` in
`docker/105/immich/.env` back to `./postgres` instead. Always copy SSD data back
before switching the mount, or changes made since migration will be lost.

Check disk space with `pct exec ID -- df -h /var/lib/cave-appdata` and the
actual mounts with `pct exec ID -- docker inspect CONTAINER --format
'{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}'`.
