#!/bin/bash

MASTER="101.101.0.100"

echo -e "\033[1;36m=========================================\033[0m"
echo -e "\033[1;36m   Verifying Kubernetes Cluster State    \033[0m"
echo -e "\033[1;36m=========================================\033[0m"
echo ""

# Helper to check a condition and print an animated spinner
check_status() {
    local description="$1"
    local command="$2"
    
    # Print the description without a newline
    printf "⏳ %-40s" "$description..."
    
    # Run the SSH command in the background
    ssh -o StrictHostKeyChecking=no root@$MASTER "$command" > /dev/null 2>&1 &
    local pid=$!
    
    # Spinner animation
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b\b\b\b"
    done
    
    # Wait for the process to actually finish and grab exit code
    wait $pid
    local status=$?
    
    # Print result based on exit code
    if [ $status -eq 0 ]; then
        printf "\r\033[1;32m✅ %-40s [ OK ]\033[0m\n" "$description"
    else
        printf "\r\033[1;31m❌ %-40s [ FAILED ]\033[0m\n" "$description"
    fi
}

echo -e "\033[1;33m---> Core Cluster Components <---\033[0m"
check_status "All 3 Nodes are Ready" "[[ \$(kubectl get nodes | grep -w 'Ready' | wc -l) -eq 3 ]]"
check_status "Flannel CNI Running" "kubectl get pods -n kube-flannel | grep -q 'Running'"
check_status "CoreDNS Running" "kubectl get pods -n kube-system -l k8s-app=kube-dns | grep -q 'Running'"
check_status "Kube-Proxy Running" "kubectl get pods -n kube-system -l k8s-app=kube-proxy | grep -q 'Running'"

echo -e "\n\033[1;33m---> Installed Addons <---\033[0m"
check_status "ArgoCD Server Running" "kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server | grep -q 'Running'"
check_status "MetalLB Controller Running" "kubectl get pods -n metallb-system -l app.kubernetes.io/component=controller | grep -q 'Running'"
check_status "MetalLB Speaker Running" "kubectl get pods -n metallb-system -l app.kubernetes.io/component=speaker | grep -q 'Running'"

echo -e "\n\033[1;36m=========================================\033[0m"
echo -e "\033[1;36m              Verification Complete        \033[0m"
echo -e "\033[1;36m=========================================\033[0m"
