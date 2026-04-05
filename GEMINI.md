# Cave server

Personal Homelab for media and complementary services.

## Architecture

This is a single machine running proxmox, with a:

- 12 core Ryzen CPU
- 16 GB of RAM
- A Radeon 5600XT GPU
- 3 ZFS pools:
    - seagate4t: a single 4TB HDD
    - lake1t: 6 1TB HDD in RAID1 
    - toshiba1t: a single 1TB HDD
- A 500GB SSD spolited in:
    - 100GB for proxmox OS
    - 400GB available CT volumes and VM Disks

## Current status

Today the server is split in 2 big VMs. The first with all the Docker images (200 from now on) and another with Home Assistant OS.

The images VM has all the seagate4t and toshiba1t pools reserved in its totallity.

There is a single docker image running directly in proxmox and is a Cloudflare tunnel that lets the services be available to the network with a custom domain. 

In this repo there are 3 folders:

1. iac: Terraform code to admin lxc's
2. media: Docker compose files to manage the media side of the server
3. monitoring:  Docker compose files to monitor the vm status and the drives real usage

## Migration plan

To improve its usage and to move to a more fragmented aproach, I want ot transform 200 to multiple LXC images. Almost one for each service, that way all can mount to the available pools.

But i need to do it in the following steps: 

### 1. Data backup

I need to move all the available files from 200's mounts on the seagate4t and toshiba1t to lake1t for backup.

In lake1t the data from toshiba1t will be saved directly in /lake1t/data and the data from seagate4t will be saved into /lake1t/backups/seagate4t

### 2. Clean and reorginize drives

After the backup i want to free the 200's VK disks in seagate4t and toshiba1t. And join the toshiba1t's drive into the lake1t RAID.

After that i want to move the backup of seagate4t back into it. This will be moved back to /seagate4t/data.

### 3. Create the LXCs and deploy the services

Finally, the LXC must be created, all with 100s id, in incremental order. There is no hard restriction to use 1 LXC for 1 service, bust just use complementary services in the same machine. 

The only services that must remain in their own are:

- Jellyfin
- qBittorrent
- seanime