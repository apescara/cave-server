# Graph Report - cave-server  (2026-09-24)

## Corpus Check
- 27 files · ~10,715 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 7 file(s) not represented in the graph (top: (none) 7)

## Summary
- 115 nodes · 106 edges · 28 communities (13 shown, 15 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7817e1bf`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Cave server architecture
- update-images.sh
- Repository operational architecture
- radarr
- move-anime-seasons.sh
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
- Migration plan VM 200 to multi-LXC architecture
- Backups
- LXC 103 — Jellystat and Jellyseerr
- LXC 104 — Monitoring and service portal
- AGENTS.md
- backup-critical-data.sh

## God Nodes (most connected - your core abstractions)
1. `Repository operational architecture` - 11 edges
2. `move-anime-seasons.sh script` - 5 edges
3. `Migration plan VM 200 to multi-LXC architecture` - 5 edges
4. `radarr` - 5 edges
5. `sonarr` - 5 edges
6. `LXC 100 — Jellyfin` - 4 edges
7. `LXC 101 — qBittorrent` - 4 edges
8. `LXC 102 — Arr stack` - 4 edges
9. `LXC 103 — Jellystat and Jellyseerr` - 4 edges
10. `LXC 104 — Monitoring and service portal` - 4 edges

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

## Communities (28 total, 15 thin omitted)

### Community 0 - "Cave server architecture"
Cohesion: 0.25
Nodes (8): Cave server architecture, Cloudflare tunnel, lake1t ZFS pool, Multi-LXC migration, Proxmox host, seagate4t ZFS pool, toshiba1t drive, Docker images VM 200

### Community 1 - "update-images.sh"
Cohesion: 0.36
Nodes (7): check_id(), contains_id(), LOCK_FILE, REPO_ROOT, update-images.sh script, usage(), VALID_IDS

### Community 2 - "Repository operational architecture"
Cohesion: 0.12
Nodes (15): Compose project, LXC 101 — qBittorrent, LXC definition, Operations, Active Compose services, LXC 102 — Arr stack, LXC definition, Operations (+7 more)

### Community 3 - "radarr"
Cohesion: 0.52
Nodes (7): lazylibrarian, radarr, swaparr-radarr, shelfarr, sonarr, swaparr-sonarr, filebrowser

### Community 4 - "move-anime-seasons.sh"
Cohesion: 0.29
Nodes (9): die(), record(), rule_end, rule_season, rule_start, season_for_episode(), season_rules, move-anime-seasons.sh script (+1 more)

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

### Community 22 - "Migration plan VM 200 to multi-LXC architecture"
Cohesion: 0.29
Nodes (7): docker/100 Compose project, Jellyfin Compose service, Jellyfin GPU passthrough, Migration plan VM 200 to multi-LXC architecture, rsync data backup, Terraform-managed LXCs, ZFS RAIDZ expansion

### Community 24 - "LXC 103 — Jellystat and Jellyseerr"
Cohesion: 0.40
Nodes (4): Compose services, LXC 103 — Jellystat and Jellyseerr, LXC definition, Operations

### Community 25 - "LXC 104 — Monitoring and service portal"
Cohesion: 0.40
Nodes (4): Active Compose services, LXC 104 — Monitoring and service portal, LXC definition, Operations

## Knowledge Gaps
- **62 isolated node(s):** `backup-critical-data.sh script`, `fix-perms.sh script`, `season_rules`, `rule_start`, `rule_end` (+57 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 68 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Repository operational architecture` connect `Repository operational architecture` to `LXC 105 — Immich`, `LXC 100 — Jellyfin`, `Migration plan VM 200 to multi-LXC architecture`, `LXC 103 — Jellystat and Jellyseerr`, `LXC 104 — Monitoring and service portal`?**
  _High betweenness centrality (0.133) - this node is a cross-community bridge._
- **Why does `Migration plan VM 200 to multi-LXC architecture` connect `Migration plan VM 200 to multi-LXC architecture` to `Repository operational architecture`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **What connects `backup-critical-data.sh script`, `fix-perms.sh script`, `season_rules` to the rest of the system?**
  _62 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Repository operational architecture` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._