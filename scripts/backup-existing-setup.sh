#!/bin/bash

# Backup script for existing Backstage/Coder setup before Kubrix replacement

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

# Create backup directory
BACKUP_DIR="/Users/petermager/Downloads/code/backstage_coder/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_status "Creating backup in: $BACKUP_DIR"

# Backup existing configurations
backup_configs() {
    print_status "Backing up Kubernetes configurations..."
    
    # Backup Backstage namespace
    if kubectl get namespace backstage &> /dev/null; then
        kubectl get all,configmap,secret,ingress -n backstage -o yaml > "$BACKUP_DIR/backstage-namespace.yaml"
        print_status "Backed up Backstage namespace resources"
    fi
    
    # Backup Coder namespace
    if kubectl get namespace coder &> /dev/null; then
        kubectl get all,configmap,secret,ingress -n coder -o yaml > "$BACKUP_DIR/coder-namespace.yaml"
        print_status "Backed up Coder namespace resources"
    fi
    
    # Backup other relevant namespaces
    for ns in monitoring ingress-nginx; do
        if kubectl get namespace "$ns" &> /dev/null; then
            kubectl get all,configmap,secret -n "$ns" -o yaml > "$BACKUP_DIR/${ns}-namespace.yaml"
            print_status "Backed up $ns namespace resources"
        fi
    done
}

# Export Helm releases
backup_helm() {
    print_status "Backing up Helm releases..."
    
    # List all Helm releases
    helm list -A -o json > "$BACKUP_DIR/helm-releases.json"
    
    # Export specific releases
    for release in $(helm list -A -q); do
        namespace=$(helm list -A -o json | jq -r ".[] | select(.name==\"$release\") | .namespace")
        helm get values "$release" -n "$namespace" > "$BACKUP_DIR/helm-values-${release}.yaml" 2>/dev/null || true
        print_status "Backed up Helm release: $release"
    done
}

# Backup PVCs and data
backup_data() {
    print_status "Backing up persistent volume claims..."
    
    kubectl get pvc -A -o yaml > "$BACKUP_DIR/all-pvcs.yaml"
    
    # Create a summary of PVCs
    kubectl get pvc -A > "$BACKUP_DIR/pvc-summary.txt"
}

# Create restoration script
create_restore_script() {
    print_status "Creating restoration script..."
    
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Restoration script for Backstage/Coder setup

echo "This script will help restore the previous setup if needed."
echo "WARNING: This should only be used if you need to rollback Kubrix installation"
echo ""
echo "To restore:"
echo "1. kubectl apply -f backstage-namespace.yaml"
echo "2. kubectl apply -f coder-namespace.yaml"
echo "3. Review and apply other namespace configs as needed"
echo ""
echo "For Helm releases, reinstall with:"
echo "helm install [release-name] [chart] -f helm-values-[release-name].yaml"
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
}

# Document current setup
document_setup() {
    print_status "Documenting current setup..."
    
    cat > "$BACKUP_DIR/current-setup.md" << EOF
# Current Setup Documentation
Created: $(date)

## Cluster Information
- Cluster: $(kubectl config current-context)
- K3s Version: $(kubectl version --short 2>/dev/null | grep Server)

## Deployed Services
$(kubectl get svc -A | grep -E 'backstage|coder|monitoring' || echo "No matching services found")

## Ingress Configuration
$(kubectl get ingress -A || echo "No ingress resources found")

## Important URLs
- Check your existing platform.yaml for service URLs
- Review ingress configurations for external access points

## Notes
- This backup includes all Kubernetes resources from relevant namespaces
- Helm values are exported separately for each release
- PVC data is documented but not backed up (would require volume snapshots)
EOF
}

# Main execution
main() {
    print_status "Starting backup of existing setup..."
    
    backup_configs
    backup_helm
    backup_data
    create_restore_script
    document_setup
    
    print_status "Backup complete!"
    print_status "Backup location: $BACKUP_DIR"
    print_warning "Keep this backup safe in case you need to restore"
    
    # Create a symlink to latest backup
    ln -sfn "$BACKUP_DIR" "/Users/petermager/Downloads/code/backstage_coder/backups/latest"
    
    echo ""
    print_status "Next step: Run the cleanup script to remove existing deployments"
}

main "$@"