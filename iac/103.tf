resource "proxmox_lxc_guest" "basic" {
  guest_id = 103
  name     = "jellystats"
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
        cores = 1
    }

  memory = 512
  swap = 512

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