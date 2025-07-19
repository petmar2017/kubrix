#!/bin/bash

# Monitor script for Kubrix bootstrap

echo "Starting Kubrix bootstrap monitor..."
echo "This will show progress in a separate window"
echo ""

# Function to show progress
show_progress() {
    while true; do
        clear
        echo "=== KUBRIX BOOTSTRAP MONITOR ==="
        echo "Time: $(date)"
        echo ""
        
        echo "=== ArgoCD Applications ==="
        kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not ready yet..."
        echo ""
        
        echo "=== Pod Count by Namespace ==="
        kubectl get pods -A --no-headers 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr || echo "No pods yet..."
        echo ""
        
        echo "=== Recent Events ==="
        kubectl get events -A --sort-by='.lastTimestamp' | tail -5
        echo ""
        
        sleep 10
    done
}

# Start monitoring in background
show_progress &
MONITOR_PID=$!

echo "Monitor started with PID: $MONITOR_PID"
echo "To stop monitoring: kill $MONITOR_PID"
echo ""
echo "Starting bootstrap in 5 seconds..."
sleep 5

# Source environment and run bootstrap
source .env
export KUBRIX_CUSTOMER_REPO KUBRIX_CUSTOMER_REPO_TOKEN KUBRIX_CUSTOMER_TARGET_TYPE KUBRIX_CUSTOMER_DNS_PROVIDER KUBRIX_CUSTOMER_DOMAIN

echo "Running bootstrap..."
./scripts/bootstrap-kubrix.sh

# Stop monitor
kill $MONITOR_PID 2>/dev/null

echo "Bootstrap completed!"