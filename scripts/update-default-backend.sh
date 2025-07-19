#!/bin/bash

# Script to update the ingress default backend with service dashboard

echo "=== Updating Ingress Default Backend ==="
echo ""

# Apply the updated default backend
echo "Applying default backend configuration..."
kubectl apply -f ../k8s-manifests/ingress/default-backend.yaml

# Restart the deployment to pick up changes
echo "Restarting default backend deployment..."
kubectl rollout restart deployment default-backend -n ingress-nginx

# Wait for rollout to complete
echo "Waiting for rollout to complete..."
kubectl rollout status deployment default-backend -n ingress-nginx --timeout=60s

echo ""
echo "✅ Default backend updated successfully!"
echo ""
echo "Access the service dashboard at: http://localhost:8880"
echo "(Make sure port forwarding is active: make port-forward)"