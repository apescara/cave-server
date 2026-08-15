# LXC 104 — Monitoring and service portal

LXC 104 provides the local service dashboard, shared-storage browser, and
automatic Docker image updates. Host-level metrics are collected by Telegraf
installed directly in the LXC; Telegraf is not a container in this project.

## LXC definition

The Proxmox definition is [`iac/104.tf`](../../iac/104.tf):

| Property | Value |
| --- | --- |
| Proxmox node | `cave` |
| LXC name | `monitoring` |
| Privilege | Privileged, nesting enabled |
| CPU / memory / swap | 1 core / 512 MiB / 512 MiB |
| Network | `vmbr0`, DHCP for IPv4 and IPv6 |
| Root filesystem | `local-lvm`, 8 GiB |

Mounts:

| Host path | LXC path |
| --- | --- |
| `/lake1t/data` | `/mnt/lake1t` |
| `/seagate4t/data` | `/mnt/seagate4t` |

## Active Compose services

| Service | Port | Role |
| --- | ---: | --- |
| Homarr | `7575` | Service dashboard |
| File Browser | `58080` | Browser for both shared data mounts |
| Watchtower | — | Pulls and recreates updated images daily |
| Dashdot | `3001` | Optional host dashboard; currently disabled |

Homarr and Watchtower mount `/var/run/docker.sock`. This grants Docker API
control to Watchtower and visibility to Homarr, so review those mounts before
exposing the LXC beyond the trusted network. File Browser stores its database
and config in `database/` and `config/`, and exposes the lake and seagate
mounts read/write through `/srv`.

## Operations

Run from this directory inside LXC 104:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100 SERVICE
```

Telegraf checks are documented in the repository root README. The Dashdot
Compose file is available for reference but is not included by the current
entry point.
