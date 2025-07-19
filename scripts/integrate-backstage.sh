#!/bin/bash

# Script to integrate Kubrix with existing Backstage installation

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check existing Backstage
check_existing_backstage() {
    print_status "Checking existing Backstage installation..."
    
    if kubectl get namespace backstage &> /dev/null; then
        print_status "Found existing Backstage namespace"
        
        # Get Backstage service details
        BACKSTAGE_SVC=$(kubectl get svc -n backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        if [ -n "$BACKSTAGE_SVC" ]; then
            print_status "Found Backstage service: $BACKSTAGE_SVC"
        fi
    else
        print_warning "No existing Backstage namespace found"
    fi
}

# Create integration ConfigMap
create_integration_config() {
    print_status "Creating integration configuration..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubrix-backstage-integration
  namespace: kubrix-platform
data:
  integration.yaml: |
    # Integration configuration between Kubrix and existing Backstage
    integration:
      existingBackstage:
        url: http://backstage.backstage.svc.cluster.local
        namespace: backstage
      kubrixBackstage:
        url: http://backstage.kubrix-backstage.svc.cluster.local
        namespace: kubrix-backstage
      sharedAuth:
        enabled: true
        provider: keycloak
        keycloakUrl: http://keycloak.kubrix-keycloak.svc.cluster.local
EOF
}

# Create network policies for cross-namespace communication
create_network_policies() {
    print_status "Creating network policies for integration..."
    
    # Allow Kubrix Backstage to communicate with existing Backstage
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kubrix-to-backstage
  namespace: backstage
spec:
  podSelector:
    matchLabels:
      app: backstage
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: kubrix-backstage
    ports:
    - protocol: TCP
      port: 7007
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backstage-to-kubrix
  namespace: kubrix-backstage
spec:
  podSelector:
    matchLabels:
      app: backstage
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: backstage
    ports:
    - protocol: TCP
      port: 7007
EOF
}

# Create shared catalog location
create_shared_catalog() {
    print_status "Setting up shared catalog configuration..."
    
    cat <<EOF > /Users/petermager/Downloads/code/kubrix/configs/shared-catalog.yaml
# Shared catalog configuration for both Backstage instances
apiVersion: v1
kind: ConfigMap
metadata:
  name: shared-catalog-config
  namespace: kubrix-platform
data:
  catalog-info.yaml: |
    apiVersion: backstage.io/v1alpha1
    kind: Location
    metadata:
      name: kubrix-services
      description: Kubrix platform services
    spec:
      targets:
        - ./platform-apps/*/catalog-info.yaml
        - ./team-apps/*/catalog-info.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: integration-docs
  namespace: kubrix-platform
data:
  README.md: |
    # Kubrix and Backstage Integration

    This setup runs two Backstage instances:
    
    1. **Existing Backstage** (namespace: backstage)
       - Your current developer portal
       - Integrated with Coder OSS
       - Available at your existing URL
    
    2. **Kubrix Backstage** (namespace: kubrix-backstage)
       - Part of the Kubrix IDP
       - Integrated with Argo CD and Kargo
       - Available at backstage.kubrix.local
    
    ## Shared Features
    
    - **Authentication**: Both instances can use Keycloak for SSO
    - **Catalog**: Services can be discovered across both instances
    - **APIs**: REST APIs can be accessed cross-namespace
    
    ## Access Points
    
    - Existing Backstage: http://your-existing-backstage-url
    - Kubrix Backstage: https://backstage.kubrix.local
    - Shared Keycloak: https://keycloak.kubrix.local
EOF
}

# Update existing Backstage configuration
update_existing_backstage() {
    print_status "Creating patch for existing Backstage to add Kubrix catalog..."
    
    cat <<EOF > /Users/petermager/Downloads/code/kubrix/configs/backstage-patch.yaml
# Patch to add Kubrix catalog to existing Backstage
# Apply with: kubectl patch configmap app-config -n backstage --patch-file backstage-patch.yaml
data:
  app-config.production.yaml: |
    catalog:
      locations:
        # Existing locations...
        # Add Kubrix services
        - type: url
          target: http://backstage.kubrix-backstage.svc.cluster.local:7007/api/catalog/locations
    
    # Optional: Add Kubrix as an external service
    proxy:
      '/kubrix':
        target: http://backstage.kubrix-backstage.svc.cluster.local:7007
        changeOrigin: true
EOF
    
    print_warning "To integrate catalogs, apply the patch to your existing Backstage config"
}

# Main execution
main() {
    print_status "Starting Backstage integration setup..."
    
    check_existing_backstage
    create_integration_config
    create_network_policies
    create_shared_catalog
    update_existing_backstage
    
    print_status "Integration setup complete!"
    print_status "Next steps:"
    echo "1. Apply the Backstage patch if you want catalog integration"
    echo "2. Configure Keycloak for both Backstage instances"
    echo "3. Update DNS entries for both services"
}

main "$@"