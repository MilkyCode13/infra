variable "pve_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "openwrt_password" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "proxmox" {
  endpoint  = "https://nas.home.shduo.ru:8006/api2/json"
  insecure  = true
  api_token = var.pve_token
}

provider "openwrt" {
  hostname = "gw.home.shduo.ru"
  username = "root"
  password = var.openwrt_password
}

resource "openwrt_dhcp_domain" "kube_master" {
  name = "kube-master"
  ip = "10.19.1.20"
}

module "kube_master1" {
  source = "./modules/vm"

  name = "kube-master1"
  node = "nas"
  vm_id = 101
  template_id = 9001
  cpu_cores = 2
  memory = 2048
  ip_cidr = "10.19.1.21/24"
}

module "kube_node1" {
  source = "./modules/vm"

  name = "kube-node1"
  node = "nas"
  vm_id = 201
  template_id = 9001
  cpu_cores = 8
  memory = 8192
  ip_cidr = "10.19.1.31/24"
}
