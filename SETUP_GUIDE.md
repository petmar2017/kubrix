# Kubrix Complete Setup Guide

This guide provides detailed steps for deploying Kubrix as a complete IDP solution on your k3s cluster.

## Pre-Installation Steps

### 1. System Requirements

Ensure your k3s cluster meets these requirements:
- **CPU**: 8+ cores
- **RAM**: 16GB+ 
- **Storage**: 100GB+ available
- **K3s Version**: v1.25+ recommended

Check resources:
```bash
kubectl top nodes
kubectl describe nodes | grep -E "Capacity|Allocatable"
```

### 2. Backup Existing Setup

If you have an existing platform:
```bash
# Create backup of current configuration
./scripts/backup-existing-setup.sh

# This creates a timestamped backup in:
# /Users/petermager/Downloads/code/backstage_coder/backups/
```

### 3. Clean Existing Installation

Remove any conflicting components:
```bash
# This will remove Backstage, Coder, and related namespaces
./scripts/cleanup-existing-setup.sh

# Verify cleanup
kubectl get namespaces
kubectl get pods -A
```

## GitHub Setup

### 1. Create Repositories

Create two **empty** repositories (no README):

1. **Platform Repository** (e.g., `kubrix-platform`)
   - Will store platform configuration
   - Must be completely empty

2. **Demo Apps Repository** (e.g., `kubrix-demo-apps`)
   - Will store demo applications
   - Can have a README

### 2. Generate Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (all)
   - `workflow` (optional, for GitHub Actions)
4. Generate and save the token

## Environment Configuration

### 1. Create Environment File

```bash
cd /Users/petermager/Downloads/code/kubrix
cp .env.example .env
```

### 2. Edit Environment Variables

Edit `.env`:
```bash
# Your GitHub platform repo (empty repo)
KUBRIX_CUSTOMER_REPO=https://github.com/YOUR_USERNAME/kubrix-platform

# Your GitHub PAT
KUBRIX_CUSTOMER_REPO_TOKEN=ghp_YOUR_TOKEN_HERE

# Keep these defaults for initial setup
KUBRIX_CUSTOMER_TARGET_TYPE=DEMO-STACK
KUBRIX_CUSTOMER_DNS_PROVIDER=local
KUBRIX_CUSTOMER_DOMAIN=kubrix.local
```

### 3. Source Environment

```bash
source .env

# Verify variables
env | grep KUBRIX
```

## DNS Configuration

### For Local Development

1. Get your k3s node IP:
   ```bash
   kubectl get nodes -o wide
   # Note the INTERNAL-IP
   ```

2. Edit `/etc/hosts`:
   ```bash
   sudo nano /etc/hosts
   
   # Add these lines (replace with your node IP):
   192.168.1.100 argocd.kubrix.local
   192.168.1.100 backstage.kubrix.local
   192.168.1.100 keycloak.kubrix.local
   192.168.1.100 kargo.kubrix.local
   192.168.1.100 vault.kubrix.local
   192.168.1.100 grafana.kubrix.local
   192.168.1.100 prometheus.kubrix.local
   ```

3. Test DNS:
   ```bash
   ping backstage.kubrix.local
   ```

### For Production

Configure your DNS provider in `.env`:
- `cloudflare`
- `route53` 
- `azure-dns`
- `google-dns`

Then create the appropriate secret during bootstrap.

## Running the Bootstrap

### 1. Start Installation

```bash
./scripts/bootstrap-kubrix.sh
```

The script will:
1. Check prerequisites
2. Create namespaces
3. Configure DNS
4. Clone Kubrix repository
5. Deploy Argo CD
6. Deploy all platform components

### 2. Monitor Progress

In another terminal:
```bash
# Watch Argo CD applications
watch kubectl get applications -n argocd

# Monitor pod creation
kubectl get pods -A -w | grep -v Running

# Check specific namespace
kubectl get pods -n argocd
kubectl get pods -n kubrix-backstage
```

### 3. Expected Timeline

- Argo CD deployment: 2-3 minutes
- Platform apps sync: 5-10 minutes
- All pods running: 15-20 minutes
- Full initialization: 20-30 minutes

## Post-Installation

### 1. Verify Installation

```bash
# Check all applications are synced
kubectl get applications -n argocd

# Verify all pods are running
kubectl get pods -A | grep -v Running | grep -v Completed

# Check ingress
kubectl get ingress -A
```

### 2. Access Credentials

Credentials are saved to `credentials.txt`:
```bash
cat credentials.txt
```

### 3. Initial Login

1. **Argo CD**:
   - URL: https://argocd.kubrix.local
   - Username: admin
   - Password: (from credentials.txt)

2. **Backstage**:
   - URL: https://backstage.kubrix.local
   - Login via Keycloak SSO

3. **Keycloak**:
   - URL: https://keycloak.kubrix.local
   - Admin console: /admin

## First Steps After Installation

### 1. Change Default Passwords

```bash
# Argo CD
argocd account update-password

# Keycloak
# Access admin console and update
```

### 2. Configure Backstage

1. Access Backstage
2. Configure GitHub integration
3. Set up catalog locations

### 3. Onboard First Team

1. Go to Backstage
2. Click "Create"
3. Select "Team Onboarding"
4. Fill in team details

### 4. Deploy First App

1. Create app in team repo
2. Use Kargo for promotion
3. Monitor in Argo CD

## Troubleshooting

### Common Issues

**Pods stuck in Pending**:
```bash
kubectl describe pod <pod-name> -n <namespace>
# Check for resource constraints or volume issues
```

**Ingress not working**:
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Test with port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

**Certificate issues**:
```bash
# Check cert-manager
kubectl get certificates -A
kubectl describe certificate -n <namespace>
```

### Recovery Options

If installation fails:
1. Check logs: `kubectl logs -n argocd deployment/argocd-server`
2. Delete and retry: `./scripts/cleanup-existing-setup.sh`
3. Restore backup if needed

## Next Steps

1. **Security Hardening**:
   - Enable RBAC
   - Configure network policies
   - Set up backup strategy

2. **Customization**:
   - Modify platform-apps for your needs
   - Add custom Backstage plugins
   - Configure monitoring dashboards

3. **Team Onboarding**:
   - Document your process
   - Create team templates
   - Set up automation

## Support Resources

- Kubrix Documentation: https://github.com/suxess-it/kubriX
- Argo CD Docs: https://argo-cd.readthedocs.io/
- Backstage Docs: https://backstage.io/docs
- Troubleshooting: Check logs and events