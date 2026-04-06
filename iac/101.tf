resource "proxmox_lxc_guest" "qbittorrent" {
  guest_id = 101
  name     = "qbittorrent"
  target_node  = "cave"
  password     = var.lxc_password
  unprivileged = true
  start_at_node_boot = true

  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }

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
        cores = 2
    }

  memory = 1024
  swap = 1024

  // Terraform will crash without rootfs defined
  root_mount  {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    id = 0
    name   = "eth0"
    bridge = "vmbr0"
    ipv4_dhcp     = true
    ipv6_dhcp     = true
  }


  mount {
    slot    = "mp0"
    host_path = "/lake1t/data"
    guest_path = "/mnt/lake1t"
    type= "bind"
  }
}