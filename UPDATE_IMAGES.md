# Update docker images in the lxc

Cus I'm 2 lazy to remember the commands and I don't trust an auto updater

100:

```bash
pct exec 100 -- bash -c "cd /mnt/lake1t/cave-server/docker/100/ && docker compose pull && docker compose up -d && docker system prune -af --volumes"
```

101:

```bash
pct exec 101 -- bash -c "cd /mnt/lake1t/cave-server/docker/101/ && docker compose pull && docker compose up -d && docker system prune -af --volumes"
```

102:

```bash
pct exec 102 -- bash -c "cd /mnt/lake1t/cave-server/docker/102/ && docker compose pull && docker compose up -d && docker system prune -af --volumes"
```

103:

```bash
pct exec 103 -- bash -c "cd /mnt/lake1t/cave-server/docker/103/ && docker compose pull && docker compose up -d && docker system prune -af --volumes"
```

104:

```bash
pct exec 104 -- bash -c "cd /mnt/lake1t/cave-server/docker/104/ && docker compose pull && docker compose up -d && docker system prune -af --volumes" 
```

105:

```bash
pct exec 105 -- bash -c "cd /mnt/lake1t/cave-server/docker/105/ && docker compose pull && docker compose up -d && docker system prune -af --volumes"
```
