variable "pve_tokens" {
  type      = map(string)
  sensitive = true
  ephemeral = true
}

variable "openwrt_password" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "proxmox" {
  alias     = "nas"
  endpoint  = "https://nas.home.shduo.ru:8006/api2/json"
  insecure  = true
  api_token = var.pve_tokens.nas
}

provider "proxmox" {
  alias     = "xeon"
  endpoint  = "https://xeon.home.shduo.ru:8006/api2/json"
  insecure  = true
  api_token = var.pve_tokens.xeon
}

provider "openwrt" {
  hostname = "gw.home.shduo.ru"
  username = "root"
  password = var.openwrt_password
}

variable "networks" {
  type = map(object({
    vlan_id     = optional(number)
    domain      = string
    dns_servers = list(string)
    gateway     = string
  }))
  default = {
    "mgmt" = {
      domain      = "home.shduo.ru"
      dns_servers = ["10.19.1.1"]
      gateway     = "10.19.1.1"
    }
    "test-mgmt" = {
      vlan_id     = 201
      domain      = "test.shduo.ru"
      dns_servers = ["10.19.201.1"]
      gateway     = "10.19.201.1"
    }
  }
}

variable "vms" {
  type = map(object({
    node      = string
    vm_id     = number
    cpu_cores = number
    memory    = number
    network   = string
    ip_cidr   = string
    hostname  = optional(string)
  }))
  default = {
    "kube-master1" = {
      node      = "nas"
      vm_id     = 101
      cpu_cores = 4
      memory    = 4096
      network   = "mgmt"
      ip_cidr   = "10.19.1.21/24"
    }
    "kube-node1" = {
      node      = "nas"
      vm_id     = 201
      cpu_cores = 8
      memory    = 8192
      network   = "mgmt"
      ip_cidr   = "10.19.1.31/24"
    }
    "ipa1-test" = {
      node      = "xeon"
      vm_id     = 2001
      cpu_cores = 2
      memory    = 2048
      network   = "test-mgmt"
      ip_cidr   = "10.19.201.11/24"
      hostname  = "ipa1"
    }
    "ipa2-test" = {
      node      = "xeon"
      vm_id     = 2002
      cpu_cores = 2
      memory    = 2048
      network   = "test-mgmt"
      ip_cidr   = "10.19.201.12/24"
      hostname  = "ipa2"
    }
  }
}

variable "ssh_keys" {
  type    = list(string)
  default = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIZak62dHFoQL3Co/XYs8SC6Lc/FnCT8xOiHu2SJAWO"]
}

resource "openwrt_dhcp_domain" "kube_master" {
  name = "kube-master"
  ip   = "10.19.1.20"
}

locals {
  nodes = ["nas", "xeon"]
  vm_configs = {
    for node in local.nodes : node => {
      for name, vm in var.vms : name => {
        node        = vm.node
        vm_id       = vm.vm_id
        template_id = 9001
        cpu_cores   = vm.cpu_cores
        memory      = vm.memory
        ip_cidr     = vm.ip_cidr
        vlan_id     = var.networks[vm.network].vlan_id
        domain      = var.networks[vm.network].domain
        dns_servers = var.networks[vm.network].dns_servers
        gateway     = var.networks[vm.network].gateway
        ssh_keys    = var.ssh_keys
        hostname    = vm.hostname
      }
      if node == vm.node
    }
  }
}

module "vm_nas" {
  for_each = local.vm_configs["nas"]

  source = "./modules/vm"
  providers = {
    proxmox = proxmox.nas
  }

  name   = each.key
  config = each.value
}

module "vm_xeon" {
  for_each = local.vm_configs["xeon"]

  source = "./modules/vm"
  providers = {
    proxmox = proxmox.xeon
  }

  name   = each.key
  config = each.value
}

moved {
  from = module.kube_master1
  to   = module.vm_nas["kube-master1"]
}

moved {
  from = module.kube_node1
  to   = module.vm_nas["kube-node1"]
}
