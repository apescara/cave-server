# Cave Server

Personal Proxmox homelab for media, downloads, home media management, and
photo storage. Services run as Docker Compose projects inside separate LXCs.

This repository is the operational source of truth:

- `iac/` contains Terraform definitions for the Proxmox LXCs.
- `docker/` contains the Compose projects deployed inside those LXCs.
- `media/` contains the Seanime Compose project.
- `fix-perms.sh` repairs permissions on shared media mounts.
- `MIGRATION.md` records the migration from the old monolithic VM.
- `UPDATE_IMAGES.md` contains manual image update commands.

## Architecture

The host is a Proxmox node named `cave`.

| LXC | Name | Compose project | Main services | Mounts |
| --- | --- | --- | --- | --- |
| 100 | `jellyfin` | `docker/100` | Jellyfin | `/mnt/lake1t`, `/mnt/seagate4t` |
| 101 | `qbittorrent` | `docker/101` | qBittorrent + Gluetun/ProtonVPN | `/mnt/lake1t` |
| 102 | `arr-stack` | `docker/102` | Prowlarr, Radarr, Sonarr, Bazarr, FlareSolverr, AudioBookShelf, Shelfarr | both data mounts |
| 103 | `jellystats` | `docker/103` | Jellystat + PostgreSQL, Jellyseerr | both data mounts |
| 104 | `monitoring` | `docker/104` | Homarr, File Browser, Watchtower | both data mounts |
| 105* | `immich` | `docker/105` | Immich + PostgreSQL + Valkey | both data mounts |
| 106 | `grafana` | NA | Graphana | mode=generated var_ctid="106" var_pw="***" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/grafana.sh)" |
| 107 | `influxdb` | NA | InfluxDB | mode=generated var_ctid="107" var_pw="***" bash -c "$(curl -fsSL https://raw.githubu
sercontent.com/community-scripts/ProxmoxVE/main/ct/influxdb.sh)" |


Seanime is separate from the Terraform-managed LXCs and is defined in
`media/`. It expects `/mnt/series/anime` inside its Docker environment.

The paths above are paths inside an LXC. Terraform binds them from the
Proxmox host's `/lake1t/data` and `/seagate4t/data` datasets. The directory
layout is therefore part of the host storage configuration, not created by
Compose.

### Storage and hardware

The documented host hardware is a 12-core Ryzen system with 16 GB RAM, a
Radeon 5600XT, and these ZFS pools:

- `lake1t`: six 1 TB disks in a RAIDZ1 pool according to the migration notes.
- `seagate4t`: a single 4 TB HDD.
- `toshiba1t`: a single 1 TB HDD, referenced by the migration plan.
- A 500 GB SSD split between Proxmox and CT/VM storage.

Jellyfin receives `/dev/dri/renderD128` for hardware transcoding. GPU mapping
and host-level LXC configuration are not fully represented in Terraform; see
the GPU notes in `MIGRATION.md`.

## First-time setup

These steps assume an LXC has already been created by Proxmox and that the
repository is available at `/mnt/lake1t/cave-server`.

1. Install Docker Engine and the Compose plugin in the LXC.
2. Clone or update this repository inside the LXC.
3. Create the required untracked `.env` file in the relevant project
   directory. Never commit credentials, VPN values, API keys, or secrets.
4. Create host directories used by Compose bind mounts and set ownership to
   match `PUID` and `PGID`.
5. Validate and start the project:

   ```bash
   cd /mnt/lake1t/cave-server/docker/102
   docker compose config
   docker compose up -d
   docker compose ps
   ```

Compose files use `include` and are intended to be run from their numbered
project directory, not from an individual service subdirectory.

## Common operations

Run these inside the target LXC:

```bash
cd /mnt/lake1t/cave-server/docker/XXX

# Inspect status and recent logs
docker compose ps
docker compose logs --tail=100 SERVICE

# Stop and start without removing persistent bind-mounted data
docker compose down
docker compose up -d

# Pull updated images and recreate services
docker compose pull
docker compose up -d
```

For host-side updates across LXCs, use [`update-images.sh`](update-images.sh)
and read [UPDATE_IMAGES.md](UPDATE_IMAGES.md). The script validates Compose
configuration, serializes runs, and reports failed LXCs.
Do not use `docker system prune --volumes` casually: it can remove unused
volumes that are not represented by the current Compose project.

## Configuration and secrets

`.env` files are ignored by Git. Variables currently used by one or more
projects include:

- `PUID`, `PGID`, `TZ`
- `QBITTORRENT_WEBUI_PORT`, `PATH_MEDIA`
- VPN provider, type, credentials, port-forwarding, and server variables
- `RADARR_API_KEY`, `SONARR_API_KEY`
- Immich's `IMMICH_VERSION`, `UPLOAD_LOCATION`, `DB_DATA_LOCATION`,
  `DB_PASSWORD`, `DB_USERNAME`, and `DB_DATABASE_NAME`

The checked-in Compose files also contain application secrets and placeholder
passwords. Treat these as credentials that should be rotated and moved to
environment files or a secret manager before exposing services beyond the
trusted LAN.

## Terraform / Proxmox

From a machine with access to the Proxmox API:

```bash
cd iac
terraform init
terraform plan
terraform apply
```

Terraform variables are declared in `iac/variables.tf`; provide them through
`terraform.tfvars` or `TF_VAR_*` environment variables, and keep both out of
Git. Review the plan carefully because LXC IDs, bind mounts, and storage
changes affect the host directly.

## Known caveats

- `iac/105.tf` declares `guest_id = 104` while naming the resource `immich`.
  Confirm the intended Proxmox ID before applying Terraform; the table above
  reflects the intended 105 assignment, not the current Terraform value.
- Watchtower is enabled in `docker/104`, while the repository also prefers
  manual image updates. Decide which policy is authoritative before relying
  on reproducible upgrades.
- Several images use `latest`; upgrades can change behavior without a diff.
  Pin versions after validating a stable release.
- IP addresses and public DNS/Cloudflare tunnel configuration are managed
  outside this repository. Update integrations when an LXC address changes.

## Recovery and migration

Read [MIGRATION.md](MIGRATION.md) before changing ZFS pools, VM disks, or LXC
mounts. It contains migration history, rsync examples, and notes about
permissions and Jellyfin GPU passthrough. Always verify backups, pool health,
and destination paths before using `rsync --delete`.

When adding or moving a service, update the Compose include, this service
table, required environment variables and mounted paths, and any update,
backup, DNS, or authentication procedure.

\* The Terraform definition currently needs review before LXC 105 is applied;
see the caveat above.
