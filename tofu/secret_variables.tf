variable "proxmox_token_id" {
  description = "Proxmox API token id (format: user@pve!tokenname)"
  type        = string
  sensitive   = true
}

variable "proxmox_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "vm_password" {
  description = "The password for the VM user"
  type        = string
  sensitive   = true
}
