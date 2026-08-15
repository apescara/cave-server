# LXC 105 — Immich

Immich is intended to run alone in LXC 105 because photo uploads, thumbnails,
machine-learning jobs, Redis/Valkey, and PostgreSQL can be resource intensive.

## LXC definition

The intended Proxmox definition is [`iac/105.tf`](../../iac/105.tf):

| Property | Intended value |
| --- | --- |
| Proxmox node | `cave` |
| LXC name | `immich` |
| Privilege | Privileged, nesting enabled |
| CPU / memory / swap | 4 cores / 8 GiB / 8 GiB |
| Network | `vmbr0`, DHCP for IPv4 and IPv6 |
| Root filesystem | `local-lvm`, 8 GiB |

Intended mounts:

| Host path | LXC path |
| --- | --- |
| `/lake1t/data` | `/mnt/lake1t` |
| `/seagate4t/data` | `/mnt/seagate4t` |

### IaC issue to resolve

`iac/105.tf` currently declares `guest_id = 104`, which conflicts with the
monitoring LXC. Confirm and correct this to `105` before applying Terraform.

## Compose services

The project entry point includes `immich/docker-compose.immich.yml`:

| Container | Port | Role |
| --- | ---: | --- |
| `immich-server` | `2283` | Immich API and web application |
| `immich-machine-learning` | internal | Thumbnail and recognition jobs |
| `database` | internal | PostgreSQL with vector extensions |
| `redis` | internal | Valkey job/cache service |

Photo uploads are mounted from `${UPLOAD_LOCATION}` to `/data` and database
data from `${DB_DATA_LOCATION}` to `/var/lib/postgresql/data`. These locations
and `IMMICH_VERSION`, `DB_PASSWORD`, `DB_USERNAME`, and `DB_DATABASE_NAME` are
defined in the untracked `docker/105/.env` file.

The Compose file is copied from the Immich deployment format; follow the
[official Immich Docker installation guide](https://docs.immich.app/install/docker-compose)
when updating it, because release files may not remain compatible.

## Operations

Run from this directory inside LXC 105:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100 immich-server database redis
```

Back up the upload directory and PostgreSQL data before upgrades. Hardware
acceleration is not enabled in the current Compose file; enable the matching
Immich acceleration configuration only after validating the LXC device setup.
