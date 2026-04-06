resource "proxmox_lxc_guest" "jellystats" {
  guest_id = 103
  name     = "jellystats"
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
        cores = 1
    }

  memory = 512
  swap = 512

  // Terraform will crash without rootfs defined
  root_mount  {
    storage = "local-lvm"
    size    = "8G"
  }

  dns {
    nameserver = ["1.1.1.1","8.8.8.8"]
  }

  network {
    id = 0
    name   = "eth0"
    bridge = "vmbr0"
    ipv4_dhcp     = true
  }


  mount {
    slot    = "mp0"
    host_path = "/lake1t/data"
    guest_path = "/mnt/lake1t"
    type= "bind"
  }

  mount {
    slot    = "mp1"
    host_path = "/seagate4t/data"
    guest_path = "/mnt/seagate4t"
    type= "bind"
  }
}