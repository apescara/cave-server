# LXC 103 — Jellystat and Jellyseerr

LXC 103 contains the Jellyfin usage dashboard and the request-management
frontend. It is separate from the media automation services in LXC 102.

## LXC definition

The Proxmox definition is [`iac/103.tf`](../../iac/103.tf):

| Property | Value |
| --- | --- |
| Proxmox node | `cave` |
| LXC name | `jellystats` |
| Privilege | Privileged, nesting enabled |
| CPU / memory / swap | 1 core / 512 MiB / 512 MiB |
| Network | `vmbr0`, DHCP for IPv4; DNS `1.1.1.1`, `8.8.8.8` |
| Root filesystem | `local-lvm`, 8 GiB |

Mounts:

| Host path | LXC path |
| --- | --- |
| `/lake1t/data` | `/mnt/lake1t` |
| `/seagate4t/data` | `/mnt/seagate4t` |

## Compose services

| Service | Port | Persistent data | Role |
| --- | ---: | --- | --- |
| `jellystat` | `3000` | `jellystat/jellystat-backup-data` | Jellyfin statistics |
| `jellystat-db` | internal `5432` | `jellystat/postgres-data` | PostgreSQL database |
| `jellyseerr` | `5055` | `jellyseerr/config` | Media requests |

Jellystat depends on a healthy PostgreSQL container. Its checked-in Compose
file currently contains database credentials and a JWT secret; treat these as
credentials and move them to `.env` or rotate them before exposing the service.

## Operations

Run from this directory inside LXC 103:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100 jellystat jellystat-db jellyseerr
```
