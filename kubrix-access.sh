#!/bin/bash

# Convenience script to access Kubrix services

echo "=== Kubrix Service Access Helper ==="
echo ""
echo "Direct Access URLs:"
echo "• ArgoCD:  http://localhost:8080  (admin/aFsfe93a-OgZSpby)"
echo "• Grafana: http://localhost:3000"
echo ""
echo "Via Ingress Controller (localhost:8880):"
echo "• ArgoCD:  curl -H 'Host: argocd.kubrix.local' http://localhost:8880"
echo "• Grafana: curl -H 'Host: grafana.kubrix.local' http://localhost:8880"
echo ""

# Function to open service in browser
open_service() {
    case $1 in
        argocd)
            echo "Opening ArgoCD..."
            open http://localhost:8080
            ;;
        grafana)
            echo "Opening Grafana..."
            open http://localhost:3000
            ;;
        *)
            echo "Unknown service: $1"
            ;;
    esac
}

# Check port-forward status
check_status() {
    echo "Checking port-forward status..."
    ps aux | grep "kubectl port-forward" | grep -v grep
}

# Restart port-forwards
restart_forwards() {
    echo "Restarting port-forwards..."
    pkill -f "kubectl port-forward"
    sleep 2
    kubectl port-forward svc/sx-argocd-server -n argocd 8080:80 > /dev/null 2>&1 &
    kubectl port-forward svc/sx-grafana -n grafana 3000:80 > /dev/null 2>&1 &
    kubectl port-forward svc/sx-ingress-nginx-controller -n ingress-nginx 8880:80 > /dev/null 2>&1 &
    echo "✅ Port-forwards restarted"
}

# Menu
if [ $# -eq 0 ]; then
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  open argocd   - Open ArgoCD in browser"
    echo "  open grafana  - Open Grafana in browser"
    echo "  status        - Check port-forward status"
    echo "  restart       - Restart all port-forwards"
    echo ""
else
    case $1 in
        open)
            open_service $2
            ;;
        status)
            check_status
            ;;
        restart)
            restart_forwards
            ;;
        *)
            echo "Unknown command: $1"
            ;;
    esac
fi