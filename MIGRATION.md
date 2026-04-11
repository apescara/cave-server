# Migration Plan: VM 200 to Multi-LXC Architecture

This document outlines the step-by-step process for migrating services from the monolithic Docker VM (200) to a distributed LXC architecture.

## Phase 1: Data Backup

Before touching any virtual disks or modifying the ZFS pools, we must ensure all data from VM 200 is safely backed up to the `lake1t` pool.

### Tasks
- [x] SSH into VM 200 and stop all running Docker containers to prevent data corruption during transfer.
- [x] Identify the exact mount paths for `toshiba1t` and `seagate4t` inside VM 200 (or on the Proxmox host).
- [x] Create the target backup directories on `lake1t` directly in the Proxmox host.
- [x] Execute `rsync` commands to copy the data.
- [x] Verify data integrity (check sizes and file counts) on the destination.

### Bash Commands
```bash
# 1. Stop all docker containers in VM 200 (run inside VM 200)
docker-compose down
# Or forcefully stop everything if compose isn't managing all containers:
# docker stop $(docker ps -a -q)

# 2. Create target directories (Run this ON THE PROXMOX HOST)
mkdir -p /lake1t/data
mkdir -p /lake1t/backups/seagate4t

# 3. Synchronize toshiba1t data to lake1t (Run this INSIDE VM 200)
# Pushes data from the VM to the Proxmox host over SSH. Replace PROXMOX_IP.
rsync -avhP -e ssh --delete /mnt/movies/ root@192.168.100.17:/lake1t/data/

# 4. Synchronize seagate4t data to lake1t (Run this INSIDE VM 200)
# Pushes data from the VM to the Proxmox host over SSH. Replace PROXMOX_IP.
rsync -avhP -e ssh --delete /mnt/series/ root@192.168.100.17:/lake1t/backups/seagate4t/
```

## Phase 2: Clean and Reorganize Drives

Once data is verified, we can free up the disks, modify the ZFS pools, and restore the `seagate4t` data back to its original drive.

### Tasks
- [x] Shut down VM 200.
- [x] Detach and destroy VM 200's virtual disks located on `seagate4t` and `toshiba1t` via the Proxmox UI.
- [ ] Wipe the physical `toshiba1t` drive.
- [ ] Attach the `toshiba1t` drive to the `lake1t` ZFS RAID1 pool.
- [ ] Restore data from `/lake1t/backups/seagate4t` back to `/seagate4t/data`.
- [ ] Verify the restored data and optionally delete the backup from `lake1t` to free up space.

### Bash Commands
```bash
# 1. Free VM disks (Best done via Proxmox Web GUI -> VM 200 -> Hardware -> Detach -> Remove)
# Alternatively via CLI:
# pvesm free seagate4t:vm-200-disk-1
# pvesm free toshiba1t:vm-200-disk-1

# 2. Identify the toshiba drive ID (look for ata-TOSHIBA...)
ls -l /dev/disk/by-id/

# 3. Add toshiba1t to the lake1t pool
# Expand the existing 5-disk raidz1-0 vdev by attaching the new disk directly to it.
# This will initiate an online RAIDZ expansion.
zpool attach lake1t raidz1-0 /dev/disk/by-id/ata-TOSHIBA_HDWD110_97T7X4YFS

# 4. Move seagate data back
mkdir -p /seagate4t/data
rsync -avhP --delete /lake1t/backups/seagate4t/ /seagate4t/data/
```

**Recommendation**: ZFS does not allow you to easily remove vdevs if you make a mistake. Double-check `zpool status lake1t` before adding the disk to ensure you don't accidentally stripe a single disk across a redundant pool.

## Phase 3: Create LXCs and Deploy Services

Deploy the individual LXC containers incrementally using Terraform. We will use the 100s range. Ensure Jellyfin, qBittorrent, and Seanime are isolated.

### Tasks
- [ ] Create `101.tf` for Jellyfin.
- [ ] Create `102.tf` for qBittorrent.
- [ ] Create `103.tf` for Seanime.
- [ ] Create `104.tf`+ for grouped/complementary services (e.g., *arr stack).
- [ ] Apply Terraform configurations (`terraform init` && `terraform apply`).
- [ ] Migrate the `docker-compose.yml` files for each service to their respective LXCs.
- [ ] Update your Cloudflare Tunnel configuration to point to the new individual LXC IPs instead of the old VM 200 IP.

### Terraform Examples

**`iac/101.tf` - Jellyfin (Requires GPU)**
```hcl
resource "proxmox_lxc_guest" "jellyfin" {
  guest_id     = 101
  name         = "jellyfin"
  target_node  = "cave"
  password     = var.lxc_password
  unprivileged = true

  features {
    unprivileged {
      nesting = true
    }
  }

  template {
    file    = "debian-13-standard_13.1-2_amd64.tar.zst"
    storage = "local"
  }

  cpu {
    cores = 4 # Transcoding benefits from more cores alongside the GPU
  }
  memory = 2048
  swap   = 2048

  root_mount {
    storage = "local-lvm"
    size    = "16G"
  }

  network {
    id        = 0
    name      = "eth0"
    bridge    = "vmbr0"
    ipv4_dhcp = true
  }

  mount {
    slot       = "mp0"
    host_path  = "/seagate4t/data"
    guest_path = "/mnt/media"
    type       = "bind"
  }
}
```

**`iac/102.tf` - qBittorrent**
```hcl
resource "proxmox_lxc_guest" "qbittorrent" {
  guest_id     = 102
  name         = "qbittorrent"
  target_node  = "cave"
  password     = var.lxc_password
  unprivileged = true

  features {
    unprivileged { nesting = true }
  }

  template {
    file    = "debian-13-standard_13.1-2_amd64.tar.zst"
    storage = "local"
  }

  cpu { cores = 2 }
  memory = 1024
  swap = 1024

  root_mount {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    id        = 0
    name      = "eth0"
    bridge    = "vmbr0"
    ipv4_dhcp = true
  }

  mount {
    slot       = "mp0"
    host_path  = "/lake1t/data/downloads"
    guest_path = "/mnt/downloads"
    type       = "bind"
  }
}
```
*(Note: `103.tf` for Seanime will follow the exact same structure as `102.tf` above, customized with its required mount points).*

### Final Recommendations
1. **UID/GID Mapping**: Because you are using `unprivileged = true`, the `root` user inside the LXC maps to `100000` on the Proxmox host. Ensure directories like `/seagate4t/data` have the correct ownership/permissions to be writable by your LXC apps (e.g., `chown -R 100000:100000 /lake1t/data/cave-server/docker/102` on the host), or configure custom `lxc.idmap` rules to map UID 1000 directly.
2. **GPU Passthrough**: For Jellyfin (101) to utilize the Radeon 5600XT, you will likely need to map `/dev/dri/renderD128` into the LXC via custom `lxc.cgroup2.devices.allow` and `lxc.mount.entry` rules in the Proxmox LXC config file `/etc/pve/lxc/101.conf`.