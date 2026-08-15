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
- `scripts/setup-telegraf-lxcs.sh` installs and configures Telegraf across LXCs 100–105.

## Architecture

The host is a Proxmox node named `cave`.

| LXC | Name | Compose project | Main services | Mounts |
| --- | --- | --- | --- | --- |
| 100 | `jellyfin` | [`docker/100`](docker/100/README.md) | Jellyfin | `/mnt/lake1t`, `/mnt/seagate4t` |
| 101 | `qbittorrent` | [`docker/101`](docker/101/README.md) | qBittorrent + Gluetun/ProtonVPN | `/mnt/lake1t` |
| 102 | `arr-stack` | [`docker/102`](docker/102/README.md) | Prowlarr, Radarr, Sonarr, Bazarr, FlareSolverr, AudioBookShelf, Shelfarr | both data mounts |
| 103 | `jellystats` | [`docker/103`](docker/103/README.md) | Jellystat + PostgreSQL, Jellyseerr | both data mounts |
| 104 | `monitoring` | [`docker/104`](docker/104/README.md) | Homarr, File Browser, Watchtower | both data mounts |
| 105* | `immich` | [`docker/105`](docker/105/README.md) | Immich + PostgreSQL + Valkey | both data mounts |
| 106 | `grafana` | NA | Graphana | mode=generated var_ctid="106" var_pw="***" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/grafana.sh)" |
| 107 | `influxdb` | NA | InfluxDB | mode=generated var_ctid="107" var_pw="***" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/influxdb.sh)" |


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

## Monitoring

InfluxDB 2.x and Grafana are installed directly on the monitoring system. The
`telegraf` bucket is used for host and Docker metrics; the existing `proxmox`
bucket remains separate for Proxmox data.

Telegraf is installed directly in each running Docker LXC. The setup script
collects CPU, memory, swap, disk, disk I/O, network, kernel, and process
metrics. When `/var/run/docker.sock` exists, it also collects Docker container
metrics. Telegraf is not installed inside individual containers.

Run the setup script from the Proxmox host as root. It skips missing or stopped
LXCs and installs Telegraf from the official InfluxData APT repository when it
is not already present:

```bash
export INFLUX_URL="http://<monitoring-lxc-ip>:8086"
export INFLUX_ORG="dacave"
export INFLUX_BUCKET="telegraf"
read -rsp "InfluxDB token: " INFLUX_TOKEN
echo
export INFLUX_TOKEN

# Optional: enable Phase 2 from an external Telegraf collector.
# Home Assistant runs in VM 201; use that VM's reachable IP or DNS name.
export HA_URL="http://<home-assistant-vm-201-ip>:8123"
export HA_TELEGRAF_LXC_ID=107
read -rsp "Home Assistant long-lived token: " HA_TOKEN
echo
export HA_TOKEN

./scripts/setup-telegraf-lxcs.sh
```

The token is supplied through the environment and is not stored in Git. The
target bucket must exist before running the script:

```bash
influx bucket create --name telegraf --org dacave --retention 90d
```

Check a deployed agent with:

```bash
pct exec 100 -- systemctl status telegraf --no-pager
pct exec 100 -- journalctl -u telegraf -n 30 --no-pager
```

### Phase 1: verify Docker metrics

Run these checks on the Proxmox host for every running Docker LXC (100–105):

```bash
for id in 100 101 102 103 104 105; do
  echo "=== LXC ${id} ==="
  pct exec "${id}" -- systemctl is-active --quiet telegraf \
    && echo "telegraf: active" || echo "telegraf: NOT active"
  pct exec "${id}" -- test -S /var/run/docker.sock \
    && echo "docker socket: present" || echo "docker socket: absent"
  pct exec "${id}" -- getent group docker || true
  pct exec "${id}" -- id telegraf
done
```

On an LXC where the Docker socket is present, verify that the Telegraf service
user can query Docker and that the input emits data:

```bash
pct exec 100 -- runuser -u telegraf -- \
  telegraf --config /etc/telegraf/telegraf.conf \
  --config-directory /etc/telegraf/telegraf.d \
  --test --input-filter docker
```

The output should include `docker`, `docker_container_status`, and usually
`docker_container_cpu`, `docker_container_mem`, and
`docker_container_net`. The exact set depends on the Docker engine and
container state. The Docker input requires access to the Docker Engine API;
the configured Unix socket and membership in the `docker` group provide that
access.

Confirm that points are arriving in InfluxDB before building dashboards:

```bash
influx query --org dacave '
from(bucket: "telegraf")
  |> range(start: -15m)
  |> filter(fn: (r) => r._measurement =~ /^docker/)
  |> limit(n: 20)
'
```

In Grafana Explore, select the InfluxDB data source and run the same Flux
query. At least one recent row should be visible, with tags such as
`engine_host`, `container_name`, and `container_status`. A useful first panel
query is:

```flux
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "docker_container_status")
  |> filter(fn: (r) => r._field == "uptime_ns")
  |> group(columns: ["engine_host", "container_name"])
```

Do not paste the Influx token into the query editor, screenshots, or this
repository. If the service-user test fails, check the socket ownership and
restart Telegraf after changing group membership:

```bash
pct exec 100 -- stat -c '%U:%G %a' /var/run/docker.sock
pct exec 100 -- systemctl restart telegraf
```

### Phase 2: Home Assistant entity metrics

The setup script optionally runs the Home Assistant HTTP input on the LXC
specified by `HA_TELEGRAF_LXC_ID` and stores the resulting points in the
existing `telegraf` bucket. It connects to Home Assistant OS in VM 201,
queries its `/api/states` endpoint, and creates a `homeassistant_state`
measurement with `entity_id`, `state`, and common metadata such as
`unit_of_measurement`, `device_class`, and `friendly_name`.

Create a Home Assistant long-lived access token from the user profile, then set
`HA_URL` and `HA_TOKEN` before running the setup script. The token is written
only to `/etc/telegraf/telegraf.d/homeassistant.token` on the selected LXC,
with `root:telegraf` ownership and mode `640`; it is not written to Git. Use
LXC 107 as the default monitoring collector in this setup, or set
`HA_TELEGRAF_LXC_ID` to another LXC from 100–107. VM 201 must only appear in
`HA_URL`; it is not a valid `pct` container ID.

Verify the service user can query Home Assistant and that Telegraf emits
entity metrics:

```bash
pct exec 107 -- stat -c '%U:%G %a' \
  /etc/telegraf/telegraf.d/homeassistant.conf \
  /etc/telegraf/telegraf.d/homeassistant.token
pct exec 107 -- runuser -u telegraf -- \
  telegraf --config /etc/telegraf/telegraf.conf \
  --config-directory /etc/telegraf/telegraf.d \
  --test --input-filter http
```

The test output should include `homeassistant_state` rows. Confirm that the
points reach InfluxDB:

```bash
influx query --org dacave '
from(bucket: "telegraf")
  |> range(start: -15m)
  |> filter(fn: (r) => r._measurement == "homeassistant_state")
  |> filter(fn: (r) => r._field == "state")
  |> limit(n: 20)
'
```

In Grafana Explore, use the same query and group or filter by `entity_id`.
`state` is intentionally stored as a string because Home Assistant also
returns non-numeric states such as `on`, `off`, and `unavailable`.

The next monitoring phases are ZFS/SMART and temperature data, network
equipment, service uptime checks, Grafana dashboards, and alert rules.

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
