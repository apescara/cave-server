# Graph Report - cave-server  (2026-08-15)

## Corpus Check
- 24 files · ~9,336 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 99 nodes · 83 edges · 27 communities (14 shown, 13 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `55510152`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Cave server architecture
- update-images.sh
- Migration plan VM 200 to multi-LXC architecture
- radarr
- Repository operational architecture
- docker/102 Compose project
- docker/101 Compose project
- immich-server
- jellystat
- fix-perms.sh
- setup-telegraf-lxcs.sh
- Manual Docker image updates
- Bookshelf service
- prowlarr
- jellyseerr
- dashdot
- homearr
- watchtower
- immich-machine-learning
- seanime
- LXC 105 — Immich
- LXC 100 — Jellyfin
- LXC 101 — qBittorrent
- LXC 102 — Arr stack
- LXC 103 — Jellystat and Jellyseerr
- LXC 104 — Monitoring and service portal
- AGENTS.md

## God Nodes (most connected - your core abstractions)
1. `Migration plan VM 200 to multi-LXC architecture` - 5 edges
2. `radarr` - 5 edges
3. `sonarr` - 5 edges
4. `Repository operational architecture` - 5 edges
5. `LXC 100 — Jellyfin` - 4 edges
6. `LXC 101 — qBittorrent` - 4 edges
7. `LXC 102 — Arr stack` - 4 edges
8. `LXC 103 — Jellystat and Jellyseerr` - 4 edges
9. `LXC 104 — Monitoring and service portal` - 4 edges
10. `LXC 105 — Immich` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Jellyfin Compose service` --references--> `Jellyfin GPU passthrough`  [INFERRED]
  docker/100/jellyfin/docker-compose.jellyfin.yml → MIGRATION.md
- `Repository operational architecture` --references--> `Migration plan VM 200 to multi-LXC architecture`  [EXTRACTED]
  README.md → MIGRATION.md
- `lazylibrarian` --semantically_similar_to--> `shelfarr`  [INFERRED] [semantically similar]
  docker/102/lazylibrarian/docker-compose.lazylibrarian.yml → docker/102/shelfarr/docker-compose.shelfarr.yml
- `docker/100 Compose project` --references--> `Jellyfin Compose service`  [EXTRACTED]
  docker/100/docker-compose.yml → docker/100/jellyfin/docker-compose.jellyfin.yml
- `lazylibrarian` --shares_data_with--> `radarr`  [EXTRACTED]
  docker/102/lazylibrarian/docker-compose.lazylibrarian.yml → docker/102/radarr/docker-compose.radarr.yml

## Import Cycles
- None detected.

## Communities (27 total, 13 thin omitted)

### Community 0 - "Cave server architecture"
Cohesion: 0.25
Nodes (8): Cave server architecture, Cloudflare tunnel, lake1t ZFS pool, Multi-LXC migration, Proxmox host, seagate4t ZFS pool, toshiba1t drive, Docker images VM 200

### Community 1 - "update-images.sh"
Cohesion: 0.36
Nodes (7): check_id(), contains_id(), LOCK_FILE, REPO_ROOT, update-images.sh script, usage(), VALID_IDS

### Community 2 - "Migration plan VM 200 to multi-LXC architecture"
Cohesion: 0.29
Nodes (7): docker/100 Compose project, Jellyfin Compose service, Jellyfin GPU passthrough, Migration plan VM 200 to multi-LXC architecture, rsync data backup, Terraform-managed LXCs, ZFS RAIDZ expansion

### Community 3 - "radarr"
Cohesion: 0.52
Nodes (7): lazylibrarian, radarr, swaparr-radarr, shelfarr, sonarr, swaparr-sonarr, filebrowser

### Community 4 - "Repository operational architecture"
Cohesion: 0.29
Nodes (7): Grafana, InfluxDB telegraf bucket, LXC 100 Jellyfin, LXC 101 qBittorrent, LXC 102 arr-stack, Repository operational architecture, Telegraf LXC monitoring

### Community 5 - "docker/102 Compose project"
Cohesion: 0.40
Nodes (6): Audiobookshelf service, Bazarr service, docker/102 Compose project, FlareSolverr service, Grimmory and MariaDB services, lake1t media libraries

### Community 6 - "docker/101 Compose project"
Cohesion: 0.67
Nodes (4): docker/101 Compose project, ProtonVPN Gluetun service, qBittorrent service, Transmission service

### Community 7 - "immich-server"
Cohesion: 0.67
Nodes (3): database, immich-server, redis

### Community 20 - "LXC 105 — Immich"
Cohesion: 0.33
Nodes (5): Compose services, IaC issue to resolve, LXC 105 — Immich, LXC definition, Operations

### Community 21 - "LXC 100 — Jellyfin"
Cohesion: 0.40
Nodes (4): Compose project, LXC 100 — Jellyfin, LXC definition, Operations

### Community 22 - "LXC 101 — qBittorrent"
Cohesion: 0.40
Nodes (4): Compose project, LXC 101 — qBittorrent, LXC definition, Operations

### Community 23 - "LXC 102 — Arr stack"
Cohesion: 0.40
Nodes (4): Active Compose services, LXC 102 — Arr stack, LXC definition, Operations

### Community 24 - "LXC 103 — Jellystat and Jellyseerr"
Cohesion: 0.40
Nodes (4): Compose services, LXC 103 — Jellystat and Jellyseerr, LXC definition, Operations

### Community 25 - "LXC 104 — Monitoring and service portal"
Cohesion: 0.40
Nodes (4): Active Compose services, LXC 104 — Monitoring and service portal, LXC definition, Operations

## Knowledge Gaps
- **56 isolated node(s):** `fix-perms.sh script`, `setup-telegraf-lxcs.sh script`, `REPO_ROOT`, `LOCK_FILE`, `VALID_IDS` (+51 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Migration plan VM 200 to multi-LXC architecture` connect `Migration plan VM 200 to multi-LXC architecture` to `Repository operational architecture`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `Repository operational architecture` connect `Repository operational architecture` to `Migration plan VM 200 to multi-LXC architecture`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `fix-perms.sh script`, `setup-telegraf-lxcs.sh script`, `REPO_ROOT` to the rest of the system?**
  _56 weakly-connected nodes found - possible documentation gaps or missing edges._