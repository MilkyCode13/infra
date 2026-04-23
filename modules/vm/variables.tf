variable "name" {
  type = string
}

variable "config" {
  type = object({
    node = string
    vm_id = number
    template_id = number
    cpu_cores = number
    memory = number
    ip_cidr = string
    gateway = string
    domain = string
    dns_servers = list(string)
    vlan_id = optional(number)
    username = optional(string, "deploy")
    ssh_keys = list(string)
  })
}
