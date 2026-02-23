# Proxmox Homelab

This repository contains Infrastructure as Code (IaC) and configuration management to provision and configure a Kubernetes cluster on a Proxmox Virtual Environment.

It consists of two main components:
1. **OpenTofu (`/tofu`)**: For provisioning virtual machines on Proxmox.
2. **Ansible (`/ansible`)**: For configuring the VMs and setting up a Kubernetes cluster.

## Architecture Structure

- **Proxmox VE**: The hypervisor to run the virtual machines.
- **VM OS**: Ubuntu 24.04 (Noble Numbat) using cloud-init images.
- **Kubernetes Cluster**: 1 Master node (`101.101.0.100`), 2 Worker nodes (`101.101.0.101`, `101.101.0.102`).

## Components Breakdown

### 1. OpenTofu Provisioning (`tofu/`)
The `tofu/` directory contains OpenTofu (Terraform alternative) configurations to dynamically provision VMs in Proxmox.

* Uses the `bpg/proxmox` provider.
* Automatically downloads the Ubuntu Noble cloud image (`noble-server-cloudimg-amd64.qcow2`).
* Uses cloud-init to configure initialization, SSH keys, user accounts, and static IPs for each node.

**Usage:**
```bash
cd tofu
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

### 2. Ansible Configuration (`ansible/`)
The `ansible/` directory contains Ansible roles and playbooks to configure the provisioned VMs. 

* **`init-cluster.yml` / `setup-k8s.yml`**: Initializes and configures the Kubernetes cluster.
* **`setup-addons.yml`**: Installs essential add-ons (including Helm and ArgoCD on the master node).
* Uses `inventory.ini` to define the target machines logically based on the static IPs assigned in OpenTofu.

**Usage:**
```bash
cd ansible
ansible-playbook -i inventory.ini setup-k8s.yml
```

## Prerequisites
- **OpenTofu**: Installed locally (a Terraform-compatible command-line tool).
- **Ansible**: Installed locally.
- **Proxmox**: A running Proxmox VE server with an API token set up and stored in `secrets.txt` or `.tfvars`.
