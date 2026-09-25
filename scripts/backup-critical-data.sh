#!/usr/bin/env bash
set -Eeuo pipefail

# Run as root on the Proxmox host. Proxmox vzdump covers SSD-backed LXC app
# data; this job saves the repository, environment files, and logical database
# exports to the separate Seagate pool.
umask 077
exec 9>/run/lock/cave-critical-backup.lock
flock -n 9 || { echo 'A critical-data backup is already running.' >&2; exit 1; }

source_dataset=lake1t/data
backup_root=/seagate4t/backups/critical
stamp=$(date +%Y%m%d-%H%M%S)
snapshot="${source_dataset}@critical-backup-${stamp}"
destination="${backup_root}/daily/${stamp}"
snapshot_path="/lake1t/data/.zfs/snapshot/critical-backup-${stamp}"

[[ ${EUID} -eq 0 ]] || { echo 'Run as root.' >&2; exit 1; }
mountpoint -q /seagate4t || { echo 'Seagate pool is not mounted.' >&2; exit 1; }
zfs list -H "${source_dataset}" >/dev/null
mkdir -p "${backup_root}/daily" "${destination}/databases"
chmod 0700 "${backup_root}" "${backup_root}/daily" "${destination}"
backup_complete=0
snapshot_created=0
cleanup() {
  if (( snapshot_created )); then
    zfs destroy "${snapshot}"
  fi
  if (( ! backup_complete )); then
    rm -rf -- "${destination}"
  fi
}
trap cleanup EXIT

# Logical dumps make the active PostgreSQL and MariaDB data restorable without
# depending on the crash consistency of a file-level database copy.
pct exec 103 -- docker exec jellystat-db pg_dumpall -U postgres \
  | gzip -1 >"${destination}/databases/jellystat.sql.gz"
pct exec 102 -- docker exec 102-mariadb-1 sh -c \
  'exec mariadb-dump --single-transaction --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip -1 >"${destination}/databases/grimmory.sql.gz"

zfs snapshot "${snapshot}"
snapshot_created=1

previous=
if [[ -L "${backup_root}/latest" ]]; then
  previous=$(readlink -f "${backup_root}/latest")
fi

rsync_options=(-aHAX --numeric-ids)
if [[ -n "${previous}" && -d "${previous}/cave-server" ]]; then
  rsync_options+=("--link-dest=${previous}/cave-server")
fi
mkdir -p "${destination}/cave-server"
rsync "${rsync_options[@]}" \
  --exclude='/.git/' --exclude='/graphify-out/' \
  --exclude='/docker/100/jellyfin/cache/' \
  --exclude='/docker/100/jellyfin/logs/' \
  --exclude='/docker/100/jellyfin/config/' \
  --exclude='/docker/101/qbittorrent/config/' \
  --exclude='/docker/102/audiobookshelf/config/' \
  --exclude='/docker/102/audiobookshelf/metadata/' \
  --exclude='/docker/102/bazarr/config/' \
  --exclude='/docker/102/grimmory/data/' \
  --exclude='/docker/102/grimmory/mariadb/config/' \
  --exclude='/docker/102/prowlarr/config/' \
  --exclude='/docker/102/radarr/config/' \
  --exclude='/docker/102/shelfarr/data/' \
  --exclude='/docker/102/sonarr/config/' \
  --exclude='/docker/103/jellyseerr/config/' \
  --exclude='/docker/103/jellystat/postgres-data/' \
  --exclude='/docker/103/jellystat/jellystat-backup-data/' \
  --exclude='/docker/104/homarr/appdata/' \
  --exclude='/docker/104/filebrowser/config/' \
  --exclude='/docker/104/filebrowser/database/' \
  --exclude='/docker/105/immich/postgres/' \
  "${snapshot_path}/cave-server/" "${destination}/cave-server/"

# Immich writes its own database exports; keep the newest one beside the
# application configuration without copying every historical export.
latest_immich=$(find "${snapshot_path}/library/backups" -maxdepth 1 -type f \
  -name 'immich-db-backup-*.sql.gz' | sort | tail -n 1)
[[ -n "${latest_immich}" ]] || { echo 'No Immich database export found.' >&2; exit 1; }
mkdir -p "${destination}/immich-db"
cp -a "${latest_immich}" "${destination}/immich-db/"

tar -C /etc -czf "${destination}/proxmox-host-config.tar.gz" \
  pve/storage.cfg pve/datacenter.cfg pve/user.cfg pve/vzdump.cron \
  pve/nodes/cave/lxc pve/nodes/cave/qemu-server network/interfaces

printf '%s\n' "${snapshot}" >"${destination}/source-snapshot.txt"
ln -sfn "daily/${stamp}" "${backup_root}/latest.new"
mv -Tf "${backup_root}/latest.new" "${backup_root}/latest"
backup_complete=1

# Remove old completed application copies only after the new copy succeeds.
find "${backup_root}/daily" -mindepth 1 -maxdepth 1 -type d -mtime +6 \
  ! -path "${destination}" -exec rm -rf -- {} +
echo "Critical-data backup complete: ${destination}"
