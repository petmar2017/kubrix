#!/bin/bash

# Script to set up port forwarding for Kubrix services on k3s

echo "=== Setting up Port Forwarding for Kubrix Services ==="
echo ""

# Function to check if port is already in use
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# Kill existing port forwards
echo "Cleaning up existing port forwards..."
pkill -f "kubectl port-forward"
pkill -f "ssh.*-L.*80:.*30080"
pkill -f "ssh.*-L.*443:.*30443"
sleep 2

# Option 1: SSH Tunnel to k3s VM (Recommended)
setup_ssh_tunnel() {
    echo ""
    echo "Option 1: Setting up SSH tunnel to k3s VM..."
    echo "This will forward:"
    echo "  - localhost:80 -> k3s-vm:30080 (HTTP)"
    echo "  - localhost:443 -> k3s-vm:30443 (HTTPS)"
    echo ""
    
    # Check if ports 80/443 are available
    if check_port 80; then
        echo "⚠️  Port 80 is already in use. You may need to use sudo or stop the service using it."
        echo "To use port 8880 instead, uncomment the alternative line in the script."
    fi
    
    # SSH tunnel command (requires SSH access to k3s VM)
    echo "Starting SSH tunnel (you may be prompted for VM password)..."
    
    # If you can't use port 80/443, use these alternatives:
    # ssh -N -L 8880:localhost:30080 -L 8443:localhost:30443 user@192.168.64.4 &
    
    # For standard ports (may require sudo on Mac):
    sudo ssh -N -L 80:localhost:30080 -L 443:localhost:30443 $USER@192.168.64.4 &
    SSH_PID=$!
    
    echo "SSH tunnel started with PID: $SSH_PID"
    echo ""
    echo "✅ You can now access services at:"
    echo "  - http://argocd.kubrix.local"
    echo "  - http://grafana.kubrix.local"
    echo "  - http://keycloak.kubrix.local"
    echo "  - http://vault.kubrix.local"
    echo "  - http://kargo.kubrix.local"
}

# Option 2: Individual kubectl port-forwards
setup_kubectl_forwards() {
    echo ""
    echo "Option 2: Setting up individual kubectl port-forwards..."
    echo ""
    
    # ArgoCD
    echo "Starting ArgoCD port-forward..."
    kubectl port-forward svc/sx-argocd-server -n argocd 8080:80 > /dev/null 2>&1 &
    echo "✅ ArgoCD: http://localhost:8080"
    
    # Grafana
    echo "Starting Grafana port-forward..."
    kubectl port-forward svc/sx-grafana -n grafana 3000:80 > /dev/null 2>&1 &
    echo "✅ Grafana: http://localhost:3000"
    
    # Keycloak (if running)
    if kubectl get svc -n keycloak keycloak >/dev/null 2>&1; then
        echo "Starting Keycloak port-forward..."
        kubectl port-forward svc/keycloak -n keycloak 8081:80 > /dev/null 2>&1 &
        echo "✅ Keycloak: http://localhost:8081"
    fi
    
    # Vault (if running)
    if kubectl get svc -n kubrix-vault vault >/dev/null 2>&1; then
        echo "Starting Vault port-forward..."
        kubectl port-forward svc/vault -n kubrix-vault 8200:8200 > /dev/null 2>&1 &
        echo "✅ Vault: http://localhost:8200"
    fi
    
    # Kargo (if running)
    if kubectl get svc -n kubrix-kargo kargo-api >/dev/null 2>&1; then
        echo "Starting Kargo port-forward..."
        kubectl port-forward svc/kargo-api -n kubrix-kargo 8082:80 > /dev/null 2>&1 &
        echo "✅ Kargo: http://localhost:8082"
    fi
}

# Main menu
echo "Choose port forwarding method:"
echo "1) SSH Tunnel (Recommended - uses domain names)"
echo "2) Individual kubectl port-forwards (different ports)"
echo "3) Both methods"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        setup_ssh_tunnel
        ;;
    2)
        setup_kubectl_forwards
        ;;
    3)
        setup_ssh_tunnel
        setup_kubectl_forwards
        ;;
    *)
        echo "Invalid choice. Defaulting to kubectl port-forwards..."
        setup_kubectl_forwards
        ;;
esac

echo ""
echo "=== Port Forwarding Setup Complete ==="
echo ""
echo "To stop all port forwards, run:"
echo "pkill -f 'kubectl port-forward'"
echo "pkill -f 'ssh.*-L.*80:.*30080'"
echo ""
echo "ArgoCD Credentials:"
echo "Username: admin"
echo "Password: aFsfe93a-OgZSpby"