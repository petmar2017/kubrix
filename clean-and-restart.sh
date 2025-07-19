#!/bin/bash

echo "=== Complete Kubrix Cleanup and Restart ==="

# Kill any running bootstrap processes
echo "Stopping any running bootstrap processes..."
pkill -f bootstrap || true
pkill -f install-platform || true

# Clean up all Kubrix namespaces
echo "Cleaning up namespaces..."
for ns in argocd cert-manager crossplane-system external-dns external-secrets ingress-nginx keycloak kyverno kubrix-platform kubrix-backstage kubrix-kargo kubrix-vault; do
    kubectl delete namespace $ns --force --grace-period=0 2>/dev/null || true
done

# Wait for cleanup
echo "Waiting for cleanup to complete..."
sleep 10

# Verify clean state
echo "Current namespaces:"
kubectl get namespaces

# Clean temp files
echo "Cleaning temporary files..."
rm -rf temp/* bootstrap.log
rm -rf ~/bootstrap-kubriX

# Source environment
echo "Setting up environment..."
source .env
export KUBRIX_CUSTOMER_REPO KUBRIX_CUSTOMER_REPO_TOKEN KUBRIX_CUSTOMER_TARGET_TYPE KUBRIX_CUSTOMER_DNS_PROVIDER KUBRIX_CUSTOMER_DOMAIN

# Run bootstrap
echo "Starting fresh bootstrap..."
./scripts/bootstrap-kubrix.sh