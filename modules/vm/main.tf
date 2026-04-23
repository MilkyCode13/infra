resource "openwrt_dhcp_domain" "dns" {
  name = var.name
  ip   = split("/", var.config.ip_cidr)[0]
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.name
  node_name = var.config.node
  vm_id     = var.config.vm_id

  clone {
    vm_id = var.config.template_id
    full  = false
  }

  cpu {
    cores = var.config.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.config.memory
    floating  = var.config.memory
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.config.vlan_id
  }

  initialization {
    dns {
      domain  = var.config.domain
      servers = var.config.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.config.ip_cidr
        gateway = var.config.gateway
      }
    }

    user_account {
      username = var.config.username
      keys     = var.config.ssh_keys
    }
  }
}
