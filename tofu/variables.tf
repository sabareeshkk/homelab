variable "proxmox_api_url" {
  type        = string
  description = "The URL of the Proxmox API (e.g., https://192.168.1.100:8006/api2/json)"
  default     = "https://192.168.1.200:8006/api2/json"
}

variable "vm_nodes" {
  type = map(object({
    name        = string
    vm_id       = number
    cpu_cores   = number
    memory      = number
    ip_address  = string
    target_node = string
  }))
  description = "Configuration for the cluster nodes"
  default = {
    "master-01" = {
      name        = "k8s-master-01"
      vm_id       = 9001
      cpu_cores   = 2
      memory      = 2048
      ip_address  = "101.101.0.100/24"
      target_node = "venus"
    }
    "worker-01" = {
      name        = "k8s-worker-01"
      vm_id       = 9002
      cpu_cores   = 2
      memory      = 2048
      ip_address  = "101.101.0.101/24"
      target_node = "mars"
    }
    "worker-02" = {
      name        = "k8s-worker-02"
      vm_id       = 9003
      cpu_cores   = 2
      memory      = 2048
      ip_address  = "101.101.0.102/24"
      target_node = "mercury"
    }
  }
}

variable "vm_gateway" {
  type        = string
  description = "The gateway IP for the VM"
  default     = "101.101.0.1"
}

variable "vm_user" {
  type        = string
  description = "The username for the VM"
  default     = "root"
}
