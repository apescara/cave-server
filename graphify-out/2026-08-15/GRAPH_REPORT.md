# Graph Report - cave-server  (2026-08-15)

## Corpus Check
- Corpus is ~7,368 words - fits in a single context window. You may not need a graph.

## Summary
- 66 nodes · 57 edges · 20 communities (8 shown, 12 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Host Storage
- Image Update Scripts
- Migration Plan
- Media Automation
- Monitoring Stack
- Arr Services
- Download Services
- Photo Library
- Media Analytics
- Permissions Setup
- Telegraf Provisioning
- Image Updates
- Bookshelf Service
- Indexer Service
- Request Management
- Dashboard Service
- Home Dashboard
- Container Updates
- Machine Learning
- Anime Streaming

## God Nodes (most connected - your core abstractions)
1. `Migration plan VM 200 to multi-LXC architecture` - 5 edges
2. `Repository operational architecture` - 5 edges
3. `radarr` - 5 edges
4. `sonarr` - 5 edges
5. `Cave server architecture` - 4 edges
6. `Multi-LXC migration` - 4 edges
7. `docker/102 Compose project` - 4 edges
8. `lazylibrarian` - 4 edges
9. `update-images.sh script` - 3 edges
10. `check_id()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Repository operational architecture` --references--> `Migration plan VM 200 to multi-LXC architecture`  [EXTRACTED]
  README.md → MIGRATION.md
- `Jellyfin Compose service` --references--> `Jellyfin GPU passthrough`  [INFERRED]
  docker/100/jellyfin/docker-compose.jellyfin.yml → MIGRATION.md
- `lazylibrarian` --semantically_similar_to--> `shelfarr`  [INFERRED] [semantically similar]
  docker/102/lazylibrarian/docker-compose.lazylibrarian.yml → docker/102/shelfarr/docker-compose.shelfarr.yml
- `docker/100 Compose project` --references--> `Jellyfin Compose service`  [EXTRACTED]
  docker/100/docker-compose.yml → docker/100/jellyfin/docker-compose.jellyfin.yml
- `docker/101 Compose project` --references--> `ProtonVPN Gluetun service`  [EXTRACTED]
  docker/101/docker-compose.yml → docker/101/protonvpn/docker-compose.protonvpn.yml

## Import Cycles
- None detected.

## Communities (20 total, 12 thin omitted)

### Community 0 - "Host Storage"
Cohesion: 0.25
Nodes (8): Cave server architecture, Cloudflare tunnel, lake1t ZFS pool, Multi-LXC migration, Proxmox host, seagate4t ZFS pool, toshiba1t drive, Docker images VM 200

### Community 1 - "Image Update Scripts"
Cohesion: 0.36
Nodes (7): check_id(), contains_id(), LOCK_FILE, REPO_ROOT, update-images.sh script, usage(), VALID_IDS

### Community 2 - "Migration Plan"
Cohesion: 0.29
Nodes (7): docker/100 Compose project, Jellyfin Compose service, Jellyfin GPU passthrough, Migration plan VM 200 to multi-LXC architecture, rsync data backup, Terraform-managed LXCs, ZFS RAIDZ expansion

### Community 3 - "Media Automation"
Cohesion: 0.52
Nodes (7): lazylibrarian, radarr, swaparr-radarr, shelfarr, sonarr, swaparr-sonarr, filebrowser

### Community 4 - "Monitoring Stack"
Cohesion: 0.29
Nodes (7): Grafana, InfluxDB telegraf bucket, LXC 100 Jellyfin, LXC 101 qBittorrent, LXC 102 arr-stack, Repository operational architecture, Telegraf LXC monitoring

### Community 5 - "Arr Services"
Cohesion: 0.40
Nodes (6): Audiobookshelf service, Bazarr service, docker/102 Compose project, FlareSolverr service, Grimmory and MariaDB services, lake1t media libraries

### Community 6 - "Download Services"
Cohesion: 0.67
Nodes (4): docker/101 Compose project, ProtonVPN Gluetun service, qBittorrent service, Transmission service

### Community 7 - "Photo Library"
Cohesion: 0.67
Nodes (3): database, immich-server, redis

## Knowledge Gaps
- **37 isolated node(s):** `fix-perms.sh script`, `setup-telegraf-lxcs.sh script`, `REPO_ROOT`, `LOCK_FILE`, `VALID_IDS` (+32 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Migration plan VM 200 to multi-LXC architecture` connect `Migration Plan` to `Monitoring Stack`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `Repository operational architecture` connect `Monitoring Stack` to `Migration Plan`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **What connects `fix-perms.sh script`, `setup-telegraf-lxcs.sh script`, `REPO_ROOT` to the rest of the system?**
  _37 weakly-connected nodes found - possible documentation gaps or missing edges._