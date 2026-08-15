# Updating Docker images

Images are normally updated manually so an upgrade can be observed and
rolled back. Run `update-images.sh` on the Proxmox host. It validates the
target, prevents concurrent runs, validates Compose configuration, enters the
LXC, pulls configured images, recreates services, and prints their status.

```bash
./update-images.sh 102
```

Validate configuration without changing anything:

```bash
./update-images.sh --check 100 101 102 103 104 105

# Update every LXC, stopping only the failed LXC and reporting failures at end
./update-images.sh --all
```

Before updating a stateful service:

1. Check release notes and the current image tag.
2. Back up its bind-mounted configuration and database data.
3. Run `docker compose config` and confirm the expected `.env` values.
4. Update one LXC at a time and inspect `docker compose logs --tail=100`.
5. Verify the application UI and dependent services before continuing.

The script does not make backups. Before updating a stateful service, take a
known-good backup or Proxmox snapshot according to that service's recovery
procedure. Avoid `docker system prune --volumes` in routine updates. It can delete
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
