output "vm_names" {
  value = { for k, v in proxmox_virtual_environment_vm.nodes : k => v.name }
}

output "vm_ids" {
  value = { for k, v in proxmox_virtual_environment_vm.nodes : k => v.vm_id }
}

output "vm_ips" {
  value       = { for k, v in proxmox_virtual_environment_vm.nodes : k => v.ipv4_addresses }
  description = "The IPv4 addresses of the VMs"
}

output "downloaded_image_paths" {
  value       = { for k, v in proxmox_virtual_environment_download_file.ubuntu_cloud_image : k => v.id }
  description = "The path on the Proxmox nodes where the image was downloaded."
}
