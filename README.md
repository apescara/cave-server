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
