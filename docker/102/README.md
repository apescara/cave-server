# LXC 102 — Arr stack

LXC 102 groups media discovery, download hand-off, subtitle, audiobook, and
book-management services that operate on the shared libraries.

## LXC definition

The Proxmox definition is [`iac/102.tf`](../../iac/102.tf):

| Property | Value |
| --- | --- |
| Proxmox node | `cave` |
| LXC name | `arr-stack` |
| Privilege | Privileged, nesting enabled |
| CPU / memory / swap | 2 cores / 1 GiB / 1 GiB |
| Network | `vmbr0`, DHCP for IPv4 and IPv6 |
| Root filesystem | `local-lvm`, 8 GiB |

Mounts:

| Host path | LXC path |
| --- | --- |
| `/lake1t/data` | `/mnt/lake1t` |
| `/seagate4t/data` | `/mnt/seagate4t` |

## Active Compose services

The entry point includes the following files:

| Service | Port | Role |
| --- | ---: | --- |
| Prowlarr | `9696` | Indexer manager |
| Radarr | `7878` | Movie automation |
| `swaparr-radarr` | — | Replaces stalled Radarr downloads |
| Sonarr | `8989` | Series automation |
| `swaparr-sonarr` | — | Replaces stalled Sonarr downloads |
| Bazarr | `6767` | Subtitle management |
| FlareSolverr | `8191` | Cloudflare challenge solver |
| Audiobookshelf | `13378` | Audiobook and podcast server |
| Shelfarr | `5056` | Audiobook/ebook automation |
| Grimmory | `6060` | Ebook and audiobook management |
| MariaDB | internal | Grimmory database |

The Compose entry point is `docker-compose.yml`. `bookshelf` and
`lazylibrarian` have Compose files but are commented out and are not active.

Configuration and application data are stored in the service subdirectories.
Shared libraries use paths below `/mnt/lake1t` and `/mnt/seagate4t`; the exact
container paths are visible in each service Compose file. Radarr and Sonarr
also require `RADARR_API_KEY` and `SONARR_API_KEY` for their Swaparr helpers.

## Operations

Run from this directory inside LXC 102:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100 SERVICE
```

Start or stop an optional project only after adding its `include` line to the
entry point. Keep all API keys, database passwords, user IDs, and other
environment values in the untracked `.env` file.
