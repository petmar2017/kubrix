#!/bin/bash

# Script to enable browser access to Kubrix services
# This creates a local proxy that forwards standard ports to k3s NodePorts

echo "=== Enabling Browser Access for Kubrix Services ==="
echo ""

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        echo "✓ Running with root privileges"
        return 0
    else
        echo "✗ Not running as root"
        return 1
    fi
}

# Kill existing port forwards
cleanup() {
    echo "Cleaning up existing port forwards..."
    sudo pkill -f "ssh.*-L.*80:" 2>/dev/null
    sudo pkill -f "ssh.*-L.*443:" 2>/dev/null
    sudo pkill -f "kubectl port-forward.*:80" 2>/dev/null
    pkill -f "kubectl port-forward.*:8880" 2>/dev/null
    sleep 2
}

# Option 1: Update hosts file to use localhost
update_hosts_localhost() {
    echo "Updating /etc/hosts to use localhost..."
    
    # Backup hosts file
    sudo cp /etc/hosts /etc/hosts.backup.browser.$(date +%Y%m%d_%H%M%S)
    
    # Update entries to use localhost
    sudo sed -i.bak 's/192.168.64.4 \(.*\.kubrix\.local\)/127.0.0.1 \1/g' /etc/hosts
    
    echo "✓ Updated /etc/hosts to use localhost"
    
    # Start port forward on 8880
    echo "Starting port forward to ingress..."
    kubectl port-forward svc/sx-ingress-nginx-controller -n ingress-nginx 8880:80 > /dev/null 2>&1 &
    
    # For privileged port 80 (requires sudo)
    echo ""
    echo "To use standard port 80 (recommended), run:"
    echo "sudo kubectl port-forward svc/sx-ingress-nginx-controller -n ingress-nginx 80:80"
}

# Option 2: Use SSH tunnel (requires VM access)
create_ssh_tunnel() {
    echo "Creating SSH tunnel to k3s VM..."
    echo "You'll be prompted for the VM password..."
    
    # Non-privileged ports
    ssh -N -L 8080:localhost:30404 -L 8443:localhost:30583 $USER@192.168.64.4 &
    SSH_PID=$!
    
    echo "SSH tunnel created (PID: $SSH_PID)"
    echo "Access services at:"
    echo "  http://localhost:8080 (use Host header)"
}

# Option 3: Direct NodePort access instructions
show_nodeport_access() {
    echo "=== Direct NodePort Access ==="
    echo ""
    echo "You can access services directly via NodePort:"
    echo ""
    echo "• ArgoCD:    http://192.168.64.4:30404  (Host: argocd.kubrix.local)"
    echo "• Grafana:   http://192.168.64.4:30404  (Host: grafana.kubrix.local)"
    echo "• Backstage: http://192.168.64.4:30404  (Host: backstage.kubrix.local)"
    echo ""
    echo "Note: Some browsers don't send Host header correctly."
    echo "Use curl or browser extensions to set custom headers."
}

# Main menu
echo "Choose access method:"
echo "1) Update hosts to localhost + port forward (Recommended)"
echo "2) SSH tunnel to VM"
echo "3) Show direct NodePort URLs"
echo "4) Cleanup only"
echo ""
read -p "Enter choice (1-4): " choice

cleanup

case $choice in
    1)
        update_hosts_localhost
        echo ""
        echo "✅ Setup complete!"
        echo ""
        echo "Access services at:"
        echo "• http://backstage.kubrix.local:8880"
        echo "• http://argocd.kubrix.local:8880"
        echo "• http://grafana.kubrix.local:8880"
        echo ""
        echo "For standard ports, run the sudo command shown above."
        ;;
    2)
        create_ssh_tunnel
        ;;
    3)
        show_nodeport_access
        ;;
    4)
        echo "Cleanup complete"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "To test access:"
echo "curl http://backstage.kubrix.local:8880"