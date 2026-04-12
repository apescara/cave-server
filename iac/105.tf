resource "proxmox_lxc_guest" "immich" {
  guest_id = 104
  name     = "immich"
  target_node  = "cave"
  password     = var.lxc_password
  privileged = true
  start_at_node_boot = true

  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }
  
  features {
        privileged {
            nesting = true
        }
    }

  template {
        file    = "debian-13-standard_13.1-2_amd64.tar.zst"
        storage = "local"
    }

  cpu {
        cores = 4
    }

  memory = 8192
  swap = 8192

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

  mount {
    slot    = "mp1"
    host_path = "/seagate4t/data"
    guest_path = "/mnt/seagate4t"
    type= "bind"
  }
}