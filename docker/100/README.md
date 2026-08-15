# LXC 100 — Jellyfin

Jellyfin is isolated in LXC 100 so media playback and hardware transcoding do
not compete directly with download, indexing, or monitoring services.

## LXC definition

The Proxmox definition is [`iac/100.tf`](../../iac/100.tf):

| Property | Value |
| --- | --- |
| Proxmox node | `cave` |
| LXC name | `jellyfin` |
| Privilege | Privileged, nesting enabled |
| CPU / memory / swap | 8 cores / 8 GiB / 8 GiB |
| Network | `vmbr0`, DHCP for IPv4 and IPv6 |
| Root filesystem | `local-lvm`, 8 GiB |

Mounts exposed by the LXC:

| Host path | LXC path |
| --- | --- |
| `/lake1t/data` | `/mnt/lake1t` |
| `/seagate4t/data` | `/mnt/seagate4t` |

## Compose project

The project entry point is `docker-compose.yml`; it includes
`jellyfin/docker-compose.jellyfin.yml`.

| Container | Image | Ports | Purpose |
| --- | --- | --- | --- |
| `jellyfin` | `jellyfin/jellyfin:latest` | host network; normally `8096/tcp`, `7359/udp` | Media server |

The container mounts local `cache/`, `config/`, and `logs/` directories. It
also mounts both LXC media paths as `/lake1t` and `/seagate4t` and receives
`/dev/dri/renderD128` for hardware transcoding. The `JELLYFIN_PublishedServerUrl`
value is currently `https://jellyfin.dacave.org/`.

## Operations

Run from this directory inside LXC 100:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100 jellyfin
```

Keep `PUID`, `PGID`, and `TZ` in the untracked `.env` file. Verify the GPU
device and permissions inside the LXC if transcoding is unavailable.
