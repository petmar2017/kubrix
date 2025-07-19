# Kubrix IDP - Complete Platform Solution

This repository contains the setup for Kubrix, a comprehensive Internal Developer Platform (IDP) that provides a complete, integrated solution for Kubernetes-based development.

## 🚀 Overview

Kubrix is an out-of-the-box IDP that integrates:
- **Argo CD** - GitOps continuous delivery
- **Backstage** - Developer portal
- **Keycloak** - Identity and access management  
- **Kargo** - Multi-stage application promotion
- **Vault** - Secrets management
- **Crossplane** - Infrastructure as code
- **External Secrets Operator** - Secrets synchronization
- **Prometheus & Grafana** - Monitoring and observability
- **Cert Manager** - Certificate management
- **NGINX Ingress** - Ingress controller
- **And more...**

## 📋 Prerequisites

1. **K3s Cluster**: 
   - Minimum: 8 CPU cores, 16GB RAM
   - Access via `kubectl` configured

2. **GitHub Setup**:
   - GitHub account with organization (or personal)
   - Personal Access Token (PAT) with `repo` permissions
   - Two empty repositories:
     - Platform configuration repo (e.g., `kubrix-platform`)
     - Demo applications repo (e.g., `kubrix-demo-apps`)

3. **Local Tools**:
   - `kubectl` installed and configured
   - `git` for repository operations
   - `helm` (optional, for manual operations)

## 🛠️ Installation Steps

### 1. Backup Existing Setup (if applicable)
If you have an existing Backstage/Coder installation:
```bash
./scripts/backup-existing-setup.sh
```

### 2. Clean Existing Installation
Remove any existing platform components:
```bash
./scripts/cleanup-existing-setup.sh
```

### 3. Configure Environment
```bash
# Copy and edit environment file
cp .env.example .env

# Edit .env with your values:
# - KUBRIX_CUSTOMER_REPO (your GitHub platform repo)
# - KUBRIX_CUSTOMER_REPO_TOKEN (your GitHub PAT)
# - Keep other defaults for local setup

# Source the environment
source .env
```

### 4. Update DNS
Add to `/etc/hosts` (for local development):
```
127.0.0.1 argocd.kubrix.local
127.0.0.1 backstage.kubrix.local
127.0.0.1 keycloak.kubrix.local
127.0.0.1 kargo.kubrix.local
127.0.0.1 vault.kubrix.local
127.0.0.1 grafana.kubrix.local
127.0.0.1 prometheus.kubrix.local
```

### 5. Run Bootstrap
```bash
./scripts/bootstrap-kubrix.sh
```

This process takes 20-30 minutes and will:
- Create all necessary namespaces
- Deploy Argo CD
- Set up the App of Apps pattern
- Deploy all platform components
- Configure integrations

## 📊 Architecture

Kubrix uses the **App of Apps** pattern with Argo CD as the orchestrator:

```
Argo CD (GitOps Engine)
    ├── Platform Apps
    │   ├── Backstage (Developer Portal)
    │   ├── Keycloak (SSO)
    │   ├── Kargo (Progressive Delivery)
    │   ├── Vault (Secrets)
    │   ├── Monitoring Stack
    │   └── Infrastructure Components
    └── Team Apps
        ├── Team Onboarding
        ├── Application Templates
        └── Multi-stage Deployments
```

## 🔑 Access Points

After installation, access your IDP services:

| Service | URL | Purpose |
|---------|-----|---------|
| Backstage | https://backstage.kubrix.local | Developer Portal |
| Argo CD | https://argocd.kubrix.local | GitOps Management |
| Keycloak | https://keycloak.kubrix.local | Identity Provider |
| Kargo | https://kargo.kubrix.local | Progressive Delivery |
| Vault | https://vault.kubrix.local | Secrets Management |
| Grafana | https://grafana.kubrix.local | Metrics Dashboard |
| Prometheus | https://prometheus.kubrix.local | Metrics Collection |

Credentials are saved to `credentials.txt` after installation.

## 🎯 Key Features

### Team Onboarding
- Self-service team creation via Backstage
- Automated namespace and RBAC setup
- GitOps repository scaffolding

### Application Deployment
- Multi-stage promotion (test → qa → prod)
- GitOps-based deployments
- Automated rollback capabilities

### Security & Compliance
- SSO via Keycloak
- Secrets management with Vault
- Policy enforcement with Kyverno
- Certificate automation

### Observability
- Full metrics stack with Prometheus
- Pre-configured Grafana dashboards
- Application and infrastructure monitoring

## 🧰 Common Operations

### Monitor Installation
```bash
# Watch pod creation
kubectl get pods -A -w

# Check Argo CD apps
kubectl get applications -n argocd

# View logs
kubectl logs -n argocd deployment/argocd-server
```

### Team Onboarding
1. Access Backstage at https://backstage.kubrix.local
2. Navigate to "Create" → "Team Onboarding"
3. Fill in team details
4. Submit to create team resources

### Deploy Application
1. Create application in team's Git repository
2. Use Kargo to promote through stages
3. Monitor in Argo CD

## 🐛 Troubleshooting

### Pods Not Starting
```bash
# Check resource usage
kubectl top nodes
kubectl describe node

# Check failed pods
kubectl get pods -A | grep -v Running
```

### DNS Issues
- Verify /etc/hosts entries
- Use port-forward for testing:
  ```bash
  kubectl port-forward -n argocd svc/argocd-server 8080:80
  ```

### Resource Constraints
- Ensure k3s has sufficient resources
- Adjust resource limits in custom-values.yaml

## 📚 Documentation

- [Setup Guide](SETUP_GUIDE.md) - Detailed installation steps
- [Architecture](docs/architecture.md) - Technical architecture
- [Team Onboarding](docs/team-onboarding.md) - How to onboard teams
- [Troubleshooting](docs/troubleshooting.md) - Common issues

## 🤝 Support

- GitHub Issues: Report bugs or request features
- Documentation: Check the docs/ directory
- Logs: Use `kubectl logs` for debugging

## 📄 License

This setup is based on the open-source Kubrix project. See their repository for licensing information.