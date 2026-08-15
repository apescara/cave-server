# Updating Docker images

Images are normally updated manually so an upgrade can be observed and
rolled back. Run the command for the LXC you want to update on the Proxmox
host. It enters the LXC, pulls configured images, recreates services, and
prints their status.

```bash
LXC_ID=102
pct exec "$LXC_ID" -- bash -lc \
  'cd /mnt/lake1t/cave-server/docker/'"$LXC_ID"' && \
   docker compose pull && \
   docker compose up -d && \
   docker compose ps'
```

Equivalent explicit commands:

```bash
pct exec 100 -- bash -lc 'cd /mnt/lake1t/cave-server/docker/100 && docker compose pull && docker compose up -d && docker compose ps'
pct exec 101 -- bash -lc 'cd /mnt/lake1t/cave-server/docker/101 && docker compose pull && docker compose up -d && docker compose ps'
pct exec 102 -- bash -lc 'cd /mnt/lake1t/cave-server/docker/102 && docker compose pull && docker compose up -d && docker compose ps'
pct exec 103 -- bash -lc 'cd /mnt/lake1t/cave-server/docker/103 && docker compose pull && docker compose up -d && docker compose ps'
pct exec 104 -- bash -lc 'cd /mnt/lake1t/cave-server/docker/104 && docker compose pull && docker compose up -d && docker compose ps'
pct exec 105 -- bash -lc 'cd /mnt/lake1t/cave-server/docker/105 && docker compose pull && docker compose up -d && docker compose ps'
```

Before updating a stateful service:

1. Check release notes and the current image tag.
2. Back up its bind-mounted configuration and database data.
3. Run `docker compose config` and confirm the expected `.env` values.
4. Update one LXC at a time and inspect `docker compose logs --tail=100`.
5. Verify the application UI and dependent services before continuing.

Avoid `docker system prune --volumes` in routine updates. It can delete
unused Docker volumes, including data not currently referenced by the Compose
project. Clean up only after identifying the exact objects to remove.

## Automatic updates

`docker/104/watchtower/docker-compose.watchtower.yml` enables Watchtower with
a 24-hour interval. This conflicts with the manual-update policy above. Until
that is resolved, assume services may update automatically and check the
Watchtower logs when an image changes unexpectedly:

```bash
pct exec 104 -- docker logs --tail=100 watchtower
```
