# Proxmox Homelab

This repository contains Infrastructure as Code (IaC) and configuration management to provision and configure a Kubernetes cluster on a Proxmox Virtual Environment.

It consists of two main components:
1. **OpenTofu (`/tofu`)**: For provisioning virtual machines on Proxmox.
2. **Ansible (`/ansible`)**: For configuring the VMs and setting up a Kubernetes cluster.

## Architecture Structure

- **Proxmox VE**: The hypervisor to run the virtual machines.
- **VM OS**: Ubuntu 24.04 (Noble Numbat) using cloud-init images.
- **Kubernetes Cluster**: 3 Master nodes and 3 Worker nodes.
- **High Availability**: Managed by `kube-vip` for the Control Plane VIP.
- **Node IPs**: `101.101.0.100` (VIP), `101.101.0.1..106` (Physical Nodes).

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

### 2. Kubernetes Configuration (`ansible/`)
The `ansible/` directory contains playbooks to configure the VMs and manage the cluster lifecycle.

* **`setup-k8s.yml`**: Provisions a Highly Available (HA) cluster with 3 Master nodes and 3 Worker nodes using `kube-vip` for Control Plane HA.
* **`setup-addons.yml`**: Installs base infrastructure:
  - **ArgoCD**: The GitOps engine managing all cluster state.
  - **MetalLB**: Provides LoadBalancer IP addresses for services.
  - **Envoy Gateway**: Modern Gateway API implementation for routing.
  - **Kube-Prometheus-Stack**: Monitoring and observability (Prometheus & Grafana).

## Service Access

The cluster uses a mix of direct LoadBalancers (for management) and a Gateway Proxy (for applications).

| Service | Access URL | Method | IP Address |
|---------|------------|--------|------------|
| **ArgoCD** | https://argocd.homelab.local | Direct LB | `101.101.0.130` |
| **Grafana** | http://grafana.homelab.local | Envoy Gateway | `101.101.0.132` |

### Local DNS Setup
To access these services from your machine, add the following to your `/etc/hosts`:
```text
101.101.0.132 grafana.homelab.local
101.101.0.130 argocd.homelab.local
```

## GitOps Workflow

This project follows a GitOps pattern using ArgoCD. Application manifests are located in `kubernetes/argocd-apps/`.

1. **Modify** manifests in the `kubernetes/` directory.
2. **Push** changes to the `main` branch.
3. **ArgoCD** automatically detects and applies changes to the cluster.

## Prerequisites
- **OpenTofu**: Installed locally for VM provisioning.
- **Ansible**: Installed locally for cluster setup.
- **Proxmox**: Running VE server with API access.

