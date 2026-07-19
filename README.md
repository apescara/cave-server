Clean docker images:

```bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

Install Docker on LXC's:

```bash
# Add Docker's official GPG key:
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update

apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Run/stop docker:

```bash
cd /mnt/lake1t/cave-server/docker/XXX
docker compose up -d
docker compose down
```

Update

```bash
docker compose down
docker compose pull
docker compose up --force-recreate --build -d
docker image prune -f
```

Jellyfin with GPU:

Using the Community script: 

```bash
mode=generated var_ctid="106" var_hostname="jellygpu" var_pw="cave281" var_gpu="yes" var_container_storage="local-lvm" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyfin.sh)"

pct set 106 -mp0 /lake1t/data,mp=/mnt/lake1t
pct set 106 -mp1 /seagate4t/data,mp=/mnt/seagate4t
``` 