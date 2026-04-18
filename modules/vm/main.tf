resource "openwrt_dhcp_domain" "dns" {
  name = var.name
  ip = split("/", var.ip_cidr)[0]
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.name
  node_name = var.node
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_id
    full  = false
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
    floating  = var.memory
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    dns {
      domain  = "home.shduo.ru"
      servers = ["10.19.1.1"]
    }

    ip_config {
      ipv4 {
        address = var.ip_cidr
        gateway = "10.19.1.1"
      }
    }

    user_account {
      username = "deploy"
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIZak62dHFoQL3Co/XYs8SC6Lc/FnCT8xOiHu2SJAWO"]
    }
  }
}
