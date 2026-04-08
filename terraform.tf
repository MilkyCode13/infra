terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.100.0"
    }

    openwrt = {
      source  = "ORFops/openwrt"
      version = "0.1.29"
    }
  }
}