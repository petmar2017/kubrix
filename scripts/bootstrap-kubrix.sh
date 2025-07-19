#!/bin/bash

# Kubrix Bootstrap Script for K3s - Full Replacement Setup
# This script sets up Kubrix IDP as a complete platform solution

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Check cluster resources
    print_status "Checking cluster resources..."
    kubectl top nodes || print_warning "Metrics server not available, cannot check resource usage"
    
    # Check required environment variables
    required_vars=(
        "KUBRIX_CUSTOMER_REPO"
        "KUBRIX_CUSTOMER_REPO_TOKEN"
        "KUBRIX_CUSTOMER_TARGET_TYPE"
        "KUBRIX_CUSTOMER_DNS_PROVIDER"
        "KUBRIX_CUSTOMER_DOMAIN"
    )
    
    print_status "Checking environment variables..."
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            print_error "Required environment variable $var is not set"
            print_error "Please source your .env file: source .env"
            exit 1
        fi
    done
    
    # Verify clean state
    print_status "Verifying cluster is clean..."
    if kubectl get namespace backstage &> /dev/null || kubectl get namespace coder &> /dev/null; then
        print_error "Existing Backstage/Coder installation detected!"
        print_error "Please run ./scripts/cleanup-existing-setup.sh first"
        exit 1
    fi
    
    print_status "All prerequisites met!"
}

# Create all required namespaces
create_namespaces() {
    print_header "Creating Namespaces"
    
    namespaces=(
        "argocd"
        "cert-manager"
        "crossplane-system"
        "external-dns"
        "external-secrets"
        "ingress-nginx"
        "keycloak"
        "kyverno"
        "kubrix-platform"
        "kubrix-backstage"
        "kubrix-kargo"
        "kubrix-vault"
    )
    
    for ns in "${namespaces[@]}"; do
        kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
        kubectl label namespace "$ns" name="$ns" --overwrite
        print_status "Namespace $ns created/verified"
    done
}

# Setup DNS configuration
setup_dns() {
    print_header "Configuring DNS"
    
    if [ "$KUBRIX_CUSTOMER_DNS_PROVIDER" == "local" ]; then
        print_status "Setting up local DNS entries..."
        
        # Get k3s node IP
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        
        print_warning "Add these entries to your /etc/hosts file:"
        echo ""
        echo "# Kubrix IDP Services"
        echo "$NODE_IP argocd.$KUBRIX_CUSTOMER_DOMAIN"
        echo "$NODE_IP backstage.$KUBRIX_CUSTOMER_DOMAIN"
        echo "$NODE_IP keycloak.$KUBRIX_CUSTOMER_DOMAIN"
        echo "$NODE_IP kargo.$KUBRIX_CUSTOMER_DOMAIN"
        echo "$NODE_IP vault.$KUBRIX_CUSTOMER_DOMAIN"
        echo "$NODE_IP grafana.$KUBRIX_CUSTOMER_DOMAIN"
        echo "$NODE_IP prometheus.$KUBRIX_CUSTOMER_DOMAIN"
        echo ""
        
        echo "Note: Remember to add these entries to /etc/hosts for domain access"
        echo "Continuing with bootstrap..."
    else
        create_external_dns_secret
    fi
}

# Create external-dns secret
create_external_dns_secret() {
    print_status "Setting up external DNS provider: $KUBRIX_CUSTOMER_DNS_PROVIDER"
    
    case "$KUBRIX_CUSTOMER_DNS_PROVIDER" in
        "cloudflare")
            print_warning "Create Cloudflare API token secret:"
            echo "kubectl create secret generic external-dns -n external-dns --from-literal=cloudflare_api_token='YOUR_TOKEN'"
            ;;
        "route53")
            print_warning "Create AWS credentials secret:"
            echo "kubectl create secret generic external-dns -n external-dns --from-literal=aws_access_key_id='YOUR_KEY' --from-literal=aws_secret_access_key='YOUR_SECRET'"
            ;;
        "azure-dns")
            print_warning "Create Azure credentials secret:"
            echo "kubectl create secret generic external-dns -n external-dns --from-file=azure.json=/path/to/azure.json"
            ;;
        *)
            print_warning "Please create the external-dns secret for your provider: $KUBRIX_CUSTOMER_DNS_PROVIDER"
            ;;
    esac
    
    read -p "Press enter once you've created the secret..."
}

# Prepare Kubrix configuration
prepare_kubrix_config() {
    print_header "Preparing Kubrix Configuration"
    
    # Create local directories
    mkdir -p /Users/petermager/Downloads/code/kubrix/{platform-apps,team-apps,configs,temp}
    
    # Clone Kubrix repository to temp directory
    print_status "Cloning Kubrix repository..."
    TEMP_DIR="/Users/petermager/Downloads/code/kubrix/temp/kubrix-$(date +%s)"
    git clone https://github.com/suxess-it/kubriX.git "$TEMP_DIR"
    
    # Copy necessary files
    print_status "Copying Kubrix files..."
    cp -r "$TEMP_DIR/bootstrap" /Users/petermager/Downloads/code/kubrix/
    cp -r "$TEMP_DIR/platform-apps" /Users/petermager/Downloads/code/kubrix/
    cp -r "$TEMP_DIR/team-apps" /Users/petermager/Downloads/code/kubrix/
    
    print_status "Kubrix files prepared"
}

# Create custom values for full IDP
create_custom_values() {
    print_header "Creating Custom Configuration"
    
    cat > /Users/petermager/Downloads/code/kubrix/configs/custom-values.yaml << EOF
# Custom values for Kubrix full IDP deployment
global:
  domain: $KUBRIX_CUSTOMER_DOMAIN
  dnsProvider: $KUBRIX_CUSTOMER_DNS_PROVIDER
  
# Enable all platform components
platformComponents:
  argocd:
    enabled: true
    ingress:
      enabled: true
      hostname: argocd.$KUBRIX_CUSTOMER_DOMAIN
  
  backstage:
    enabled: true
    ingress:
      enabled: true
      hostname: backstage.$KUBRIX_CUSTOMER_DOMAIN
  
  keycloak:
    enabled: true
    ingress:
      enabled: true
      hostname: keycloak.$KUBRIX_CUSTOMER_DOMAIN
  
  kargo:
    enabled: true
    ingress:
      enabled: true
      hostname: kargo.$KUBRIX_CUSTOMER_DOMAIN
  
  vault:
    enabled: true
    ingress:
      enabled: true
      hostname: vault.$KUBRIX_CUSTOMER_DOMAIN
  
  monitoring:
    enabled: true
    prometheus:
      ingress:
        enabled: true
        hostname: prometheus.$KUBRIX_CUSTOMER_DOMAIN
    grafana:
      ingress:
        enabled: true
        hostname: grafana.$KUBRIX_CUSTOMER_DOMAIN

# Resource limits for k3s
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
EOF
    
    print_status "Custom configuration created"
}

# Run the Kubrix bootstrap
run_bootstrap() {
    print_header "Running Kubrix Bootstrap"
    
    cd /Users/petermager/Downloads/code/kubrix
    
    print_status "Starting Kubrix bootstrap process..."
    print_warning "This will take approximately 20-30 minutes"
    
    # Export additional variables for bootstrap
    export KUBRIX_CUSTOM_VALUES="/Users/petermager/Downloads/code/kubrix/configs/custom-values.yaml"
    
    # Run the bootstrap
    if [ -f "./bootstrap/bootstrap.sh" ]; then
        bash ./bootstrap/bootstrap.sh
    else
        print_error "Bootstrap script not found!"
        exit 1
    fi
}

# Post-installation setup
post_install_setup() {
    print_header "Post-Installation Setup"
    
    # Get initial passwords
    print_status "Retrieving initial passwords..."
    
    # ArgoCD admin password
    ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    # Create credentials file
    cat > /Users/petermager/Downloads/code/kubrix/credentials.txt << EOF
# Kubrix IDP Credentials
# Generated: $(date)

## ArgoCD
URL: https://argocd.$KUBRIX_CUSTOMER_DOMAIN
Username: admin
Password: $ARGOCD_PASS

## Keycloak
URL: https://keycloak.$KUBRIX_CUSTOMER_DOMAIN
Username: admin
Password: (check keycloak secret or logs)

## Backstage
URL: https://backstage.$KUBRIX_CUSTOMER_DOMAIN
Login: Via Keycloak SSO

## Grafana
URL: https://grafana.$KUBRIX_CUSTOMER_DOMAIN
Username: admin
Password: (check grafana secret)

## Vault
URL: https://vault.$KUBRIX_CUSTOMER_DOMAIN
Token: (check vault init logs)
EOF
    
    print_status "Credentials saved to credentials.txt"
    print_warning "Keep this file secure!"
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    print_status "Checking Argo CD applications..."
    kubectl get applications -n argocd
    
    print_status "Checking pod status..."
    kubectl get pods -A | grep -E 'argocd|backstage|keycloak|kargo|vault' | head -20
    
    print_status "Checking ingress..."
    kubectl get ingress -A
    
    print_warning "Use 'kubectl get pods -A -w' to monitor pod creation"
}

# Main execution
main() {
    print_header "Kubrix IDP Full Installation"
    
    check_prerequisites
    create_namespaces
    setup_dns
    prepare_kubrix_config
    create_custom_values
    
    print_status "Ready to start Kubrix bootstrap"
    print_warning "This will deploy a complete IDP with:"
    echo "  - Argo CD (GitOps)"
    echo "  - Backstage (Developer Portal)"
    echo "  - Keycloak (SSO)"
    echo "  - Kargo (Progressive Delivery)"
    echo "  - Vault (Secrets Management)"
    echo "  - Monitoring Stack (Prometheus/Grafana)"
    echo "  - And more..."
    echo ""
    echo "Starting bootstrap process..."
    
    run_bootstrap
    post_install_setup
    verify_installation
    
    print_header "Installation Complete!"
    print_status "Access your new IDP at:"
    echo "  - Developer Portal: https://backstage.$KUBRIX_CUSTOMER_DOMAIN"
    echo "  - GitOps: https://argocd.$KUBRIX_CUSTOMER_DOMAIN"
    echo "  - SSO: https://keycloak.$KUBRIX_CUSTOMER_DOMAIN"
    echo ""
    print_status "Check credentials.txt for login information"
}

# Run main function
main "$@"