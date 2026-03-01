#!/bin/bash

NODES=("101.101.0.100" "101.101.0.101" "101.101.0.102" "101.101.0.103")

echo "========================================="
echo "   Verifying Kubernetes Node Setup      "
echo "========================================="

for NODE in "${NODES[@]}"; do
    echo -e "\n---> Checking Node: $NODE <---"
    
    # Check Swap
    echo -n "Swap Disabled: "
    ssh -o StrictHostKeyChecking=no root@$NODE "free -h | awk '/Swap:/ {print \$2}'" | grep -q "0B\|0" && echo "✅" || echo "❌ (Swap is ON)"
    
    # Check containerd status
    echo -n "containerd running: "
    ssh -o StrictHostKeyChecking=no root@$NODE "systemctl is-active containerd" | grep -q "active" && echo "✅" || echo "❌"
    
    # Check SystemdCgroup configuration in containerd
    echo -n "containerd SystemdCgroup: "
    ssh -o StrictHostKeyChecking=no root@$NODE "grep 'SystemdCgroup = true' /etc/containerd/config.toml > /dev/null" && echo "✅" || echo "❌"

    # Check kubelet status (it might be crashlooping until kubeadm init is run, but it should be enabled)
    echo -n "kubelet installed/enabled: "
    ssh -o StrictHostKeyChecking=no root@$NODE "systemctl is-enabled kubelet" | grep -q "enabled" && echo "✅" || echo "❌"

    # Check kubeadm and kubectl exist
    echo -n "kubeadm version: "
    ssh -o StrictHostKeyChecking=no root@$NODE "kubeadm version -o short" || echo "❌"
    
    # Check sysctl variables
    echo -n "IPv4 Forwarding (1): "
    ssh -o StrictHostKeyChecking=no root@$NODE "sysctl net.ipv4.ip_forward" | awk '{print $3}' | grep -q "1" && echo "✅" || echo "❌"

    echo -n "Bridge iptables (1): "
    ssh -o StrictHostKeyChecking=no root@$NODE "sysctl net.bridge.bridge-nf-call-iptables" | awk '{print $3}' | grep -q "1" && echo "✅" || echo "❌"
done

echo -e "\n========================================="
echo "              Verification Complete        "
echo "========================================="
