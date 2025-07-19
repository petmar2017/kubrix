#!/bin/bash

echo "=== Backstage Access Fix ==="
echo ""
echo "The URL http://backstage.kubrix.local doesn't work because it tries port 80"
echo "but the service is available on NodePort 30404."
echo ""
echo "Choose a solution:"
echo ""
echo "1) Use localhost with port forwarding (Recommended)"
echo "   URL: http://localhost:8880"
echo "   Requirement: Browser extension to set Host header"
echo ""
echo "2) Use NodePort URL"
echo "   URL: http://backstage.kubrix.local:30404"
echo "   Works directly in browser"
echo ""
echo "3) Update /etc/hosts to use localhost"
echo "   This allows http://backstage.kubrix.local:8880"
echo ""
read -p "Choose option (1-3): " choice

case $choice in
  1)
    echo ""
    echo "Testing localhost access..."
    curl -s -H "Host: backstage.kubrix.local" http://localhost:8880 | grep -q "Scaffolded Backstage App" && \
      echo "✅ Working! Access http://localhost:8880 with Host header" || \
      echo "❌ Not working. Check port forwarding: make port-forward"
    ;;
  2)
    echo ""
    echo "Opening http://backstage.kubrix.local:30404 in browser..."
    open http://backstage.kubrix.local:30404 2>/dev/null || xdg-open http://backstage.kubrix.local:30404 2>/dev/null
    ;;
  3)
    echo ""
    echo "To update /etc/hosts:"
    echo "sudo sed -i '' 's/192.168.64.4 backstage.kubrix.local/127.0.0.1 backstage.kubrix.local/' /etc/hosts"
    echo ""
    echo "Then access: http://backstage.kubrix.local:8880"
    ;;
esac