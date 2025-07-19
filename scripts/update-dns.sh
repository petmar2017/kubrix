#!/bin/bash

# Script to update /etc/hosts for Kubrix

echo "Adding Kubrix DNS entries to /etc/hosts..."
echo ""
echo "The following entries will be added:"
echo "192.168.64.4 argocd.kubrix.local"
echo "192.168.64.4 backstage.kubrix.local"
echo "192.168.64.4 keycloak.kubrix.local"
echo "192.168.64.4 kargo.kubrix.local"
echo "192.168.64.4 vault.kubrix.local"
echo "192.168.64.4 grafana.kubrix.local"
echo "192.168.64.4 prometheus.kubrix.local"
echo ""

# Create the entries
cat << EOF > /tmp/kubrix-hosts
# Kubrix IDP Services
192.168.64.4 argocd.kubrix.local
192.168.64.4 backstage.kubrix.local
192.168.64.4 keycloak.kubrix.local
192.168.64.4 kargo.kubrix.local
192.168.64.4 vault.kubrix.local
192.168.64.4 grafana.kubrix.local
192.168.64.4 prometheus.kubrix.local
EOF

echo "Please run the following command to add these entries:"
echo ""
echo "sudo sh -c 'cat /tmp/kubrix-hosts >> /etc/hosts'"
echo ""
echo "Or manually add the above entries to /etc/hosts"