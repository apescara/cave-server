Clean docker images:

```bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

Run/stop docker:

```bash
docker-compose up -d
docker-compose down
```

Update

```bash
docker-compose down
docker-compose pull
docker-compose up --force-recreate --build -d
docker image prune -f
```
