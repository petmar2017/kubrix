#!/bin/bash

# Script to update /etc/hosts with Kubrix entries

echo "=== Updating /etc/hosts for Kubrix ==="
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo access to update /etc/hosts"
    echo "Please run: sudo ./update-hosts.sh"
    exit 1
fi

# Backup current hosts file
cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)
echo "Created backup of /etc/hosts"

# Check if Kubrix entries already exist
if grep -q "kubrix.local" /etc/hosts; then
    echo "Kubrix entries already exist in /etc/hosts"
    echo "Removing old entries..."
    # Remove old kubrix entries
    sed -i.bak '/kubrix.local/d' /etc/hosts
fi

# Add new entries
echo "" >> /etc/hosts
echo "# Kubrix IDP Services" >> /etc/hosts
echo "192.168.64.4 argocd.kubrix.local" >> /etc/hosts
echo "192.168.64.4 backstage.kubrix.local" >> /etc/hosts
echo "192.168.64.4 keycloak.kubrix.local" >> /etc/hosts
echo "192.168.64.4 kargo.kubrix.local" >> /etc/hosts
echo "192.168.64.4 vault.kubrix.local" >> /etc/hosts
echo "192.168.64.4 grafana.kubrix.local" >> /etc/hosts
echo "192.168.64.4 prometheus.kubrix.local" >> /etc/hosts

echo ""
echo "✅ Successfully added Kubrix entries to /etc/hosts"
echo ""
echo "Added entries:"
tail -8 /etc/hosts

echo ""
echo "Testing DNS resolution..."
for domain in argocd backstage keycloak kargo vault grafana prometheus; do
    if ping -c 1 -W 1 $domain.kubrix.local > /dev/null 2>&1; then
        echo "✅ $domain.kubrix.local - OK"
    else
        echo "❌ $domain.kubrix.local - Failed"
    fi
done