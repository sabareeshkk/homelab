provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_secret}"
  insecure  = true
}

moved {
  from = proxmox_virtual_environment_vm.ubuntu_noble
  to   = proxmox_virtual_environment_vm.nodes["master-01"]
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  for_each     = toset(distinct([for n in var.vm_nodes : n.target_node]))
  content_type = "import"
  datastore_id = "local"
  node_name    = each.value
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each  = var.vm_nodes
  name      = each.value.name
  node_name = each.value.target_node
  vm_id     = each.value.vm_id

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
    floating  = each.value.memory
  }

  # Root disk from cloud image
  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.ubuntu_cloud_image[each.value.target_node].id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  # Set boot order to ensure VM boots from the imported disk
  boot_order = ["virtio0"]

  network_device {
    bridge = "vmbr0"
  }

  # 🔥 cloud-init
  initialization {
    user_account {
      username = var.vm_user
      keys     = [trimspace(file(var.ssh_public_key_path))]
      password = var.vm_password
    }

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }
}
