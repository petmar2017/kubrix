#!/bin/bash

# Cleanup script to remove existing Backstage/Coder setup for Kubrix replacement

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Safety check
safety_check() {
    print_warning "This script will remove the existing Backstage/Coder deployment!"
    print_warning "Make sure you have run backup-existing-setup.sh first!"
    echo ""
    read -p "Have you created a backup? (yes/no): " response
    
    if [[ "$response" != "yes" ]]; then
        print_error "Please run ./scripts/backup-existing-setup.sh first!"
        exit 1
    fi
    
    echo ""
    print_warning "This will delete the following namespaces and their resources:"
    echo "  - backstage"
    echo "  - coder"
    echo "  - monitoring (optional)"
    echo "  - ingress-nginx (will be replaced by Kubrix)"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Remove Helm releases
remove_helm_releases() {
    print_status "Removing Helm releases..."
    
    # List of Helm releases to remove
    releases=("backstage" "coder" "prometheus" "grafana" "nginx-ingress")
    
    for release in "${releases[@]}"; do
        if helm list -A | grep -q "^${release}"; then
            namespace=$(helm list -A | grep "^${release}" | awk '{print $2}')
            print_status "Uninstalling Helm release: $release from namespace: $namespace"
            helm uninstall "$release" -n "$namespace" || true
        fi
    done
}

# Delete namespaces
delete_namespaces() {
    print_status "Deleting namespaces..."
    
    # Namespaces to delete
    namespaces=("backstage" "coder" "monitoring" "ingress-nginx")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            print_status "Deleting namespace: $ns"
            kubectl delete namespace "$ns" --wait=false
        else
            print_status "Namespace $ns not found, skipping"
        fi
    done
    
    # Wait for namespace deletion
    print_status "Waiting for namespaces to be deleted..."
    for ns in "${namespaces[@]}"; do
        while kubectl get namespace "$ns" &> /dev/null; do
            echo -n "."
            sleep 5
        done
    done
    echo ""
}

# Clean up CRDs
cleanup_crds() {
    print_status "Cleaning up Custom Resource Definitions..."
    
    # Remove Prometheus CRDs
    kubectl delete crd prometheuses.monitoring.coreos.com &> /dev/null || true
    kubectl delete crd prometheusrules.monitoring.coreos.com &> /dev/null || true
    kubectl delete crd servicemonitors.monitoring.coreos.com &> /dev/null || true
    kubectl delete crd podmonitors.monitoring.coreos.com &> /dev/null || true
    kubectl delete crd alertmanagers.monitoring.coreos.com &> /dev/null || true
    kubectl delete crd alertmanagerconfigs.monitoring.coreos.com &> /dev/null || true
    
    print_status "CRDs cleaned up"
}

# Clean up PVCs
cleanup_pvcs() {
    print_status "Listing PVCs that will remain (data preservation)..."
    
    kubectl get pvc -A | grep -E 'backstage|coder|prometheus|grafana' || true
    
    print_warning "PVCs are preserved by default. Delete manually if needed:"
    echo "kubectl delete pvc -n <namespace> <pvc-name>"
}

# Reset ingress
reset_ingress() {
    print_status "Cleaning up ingress resources..."
    
    # Delete all ingress resources
    kubectl delete ingress -A --all || true
    
    print_status "Ingress resources cleaned up"
}

# Final cleanup
final_cleanup() {
    print_status "Performing final cleanup..."
    
    # Remove any cluster-wide resources
    kubectl delete clusterrolebinding -l app.kubernetes.io/part-of=backstage || true
    kubectl delete clusterrolebinding -l app.kubernetes.io/part-of=coder || true
    kubectl delete clusterrole -l app.kubernetes.io/part-of=backstage || true
    kubectl delete clusterrole -l app.kubernetes.io/part-of=coder || true
    
    print_status "Cluster-wide resources cleaned up"
}

# Verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    echo ""
    echo "Remaining namespaces:"
    kubectl get namespaces
    
    echo ""
    echo "Remaining pods in all namespaces:"
    kubectl get pods -A | grep -v -E 'kube-system|default' || echo "No non-system pods found"
    
    echo ""
    echo "Remaining services:"
    kubectl get svc -A | grep -v -E 'kube-system|default' || echo "No non-system services found"
}

# Main execution
main() {
    print_status "Starting cleanup of existing setup..."
    
    safety_check
    remove_helm_releases
    delete_namespaces
    cleanup_crds
    cleanup_pvcs
    reset_ingress
    final_cleanup
    verify_cleanup
    
    print_status "Cleanup complete!"
    print_status "The cluster is now ready for Kubrix installation"
    print_warning "Note: PVCs were preserved. Delete manually if needed."
    
    echo ""
    print_status "Next step: Configure and run the Kubrix bootstrap"
}

main "$@"