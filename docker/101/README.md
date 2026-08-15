# LXC 101 — qBittorrent

LXC 101 is the dedicated download container. qBittorrent shares the network
namespace of Gluetun, forcing torrent traffic through ProtonVPN.

## LXC definition

The Proxmox definition is [`iac/101.tf`](../../iac/101.tf):

| Property | Value |
| --- | --- |
| Proxmox node | `cave` |
| LXC name | `qbittorrent` |
| Privilege | Privileged, nesting enabled |
| CPU / memory / swap | 1 core / 512 MiB / 512 MiB |
| Network | `vmbr0`, DHCP for IPv4 and IPv6 |
| Root filesystem | `local-lvm`, 8 GiB |

The host path `/lake1t/data` is mounted at `/mnt/lake1t`.

## Compose project

The project entry point is `docker-compose.yml`; it includes qBittorrent and
ProtonVPN. The Transmission project is present but commented out and is not
started by the entry point.

| Container | Image | Ports | Purpose |
| --- | --- | --- | --- |
| `protonvpn` | `qmcgaw/gluetun:latest` | `${QBITTORRENT_WEBUI_PORT}` | VPN gateway |
| `qbittorrent` | `linuxserver/qbittorrent:libtorrentv1` | through ProtonVPN | Torrent client |
| `transmission` | `linuxserver/transmission:latest` | `9091`, `51413/tcp+udp` | Optional, currently disabled |

qBittorrent uses `network_mode: service:protonvpn` and depends on the VPN
health check. Its configuration is stored in `qbittorrent/config/`; the
download directory is `${PATH_MEDIA}` on the LXC and `/downloads` in the
container. Gluetun stores VPN state in `protonvpn/vpn/` and requires
`/dev/net/tun`, `NET_ADMIN`, and the VPN credentials in `.env`.

Required settings include `PUID`, `PGID`, `TZ`, `PATH_MEDIA`,
`QBITTORRENT_WEBUI_PORT`, VPN provider/type, OpenVPN credentials, server
selection, and port-forwarding settings. Never commit those values.

## Operations

Run from this directory inside LXC 101:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose logs --tail=100 protonvpn qbittorrent
```

If qBittorrent cannot start, check Gluetun health first, then verify that the
LXC has `/dev/net/tun` and that `PATH_MEDIA` resolves to a writable directory.

The original tun-device setup reference is the [Proxmox OpenVPN-in-LXC
guide](https://pve.proxmox.com/wiki/OpenVPN_in_LXC).
