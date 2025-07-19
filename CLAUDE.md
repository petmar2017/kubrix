# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kubrix is an out-of-the-box Internal Developer Platform (IDP) for Kubernetes that integrates:
- Argo CD (GitOps)
- Kargo (Multi-stage deployments)
- Backstage (Developer portal)
- Keycloak (Identity management)
- External Secrets Operator
- And more...

This repository contains the configuration and scripts to deploy Kubrix on a local k3s cluster, running alongside an existing Backstage installation.

## Key Commands

### Setup and Bootstrap
```bash
# Set up environment variables
source .env

# Run the bootstrap process
./scripts/bootstrap-kubrix.sh

# Integrate with existing Backstage
./scripts/integrate-backstage.sh
```

### Monitoring and Debugging
```bash
# Check Argo CD applications
kubectl get applications -n argocd

# Monitor all Kubrix pods
kubectl get pods -A | grep -E 'argocd|backstage|keycloak|kargo|kubrix'

# Check logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n kubrix-backstage deployment/backstage

# Port forwarding for local access
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

## Project Structure

```
kubrix/
├── .env                    # Environment configuration (create from .env.example)
├── scripts/               # Setup and utility scripts
│   ├── bootstrap-kubrix.sh    # Main bootstrap script
│   └── integrate-backstage.sh # Integration with existing Backstage
├── platform-apps/         # Platform components (created by bootstrap)
├── team-apps/            # Team applications (created by bootstrap)
├── configs/              # Configuration files
└── docs/                 # Additional documentation
```

## Technical Architecture

1. **Deployment Pattern**: App of Apps using Argo CD
2. **Multi-tenancy**: Argo CD AppProjects for team isolation
3. **Namespace Strategy**:
   - `argocd` - Argo CD components
   - `kubrix-platform` - Platform services
   - `kubrix-backstage` - Backstage instance
   - `kubrix-keycloak` - Identity provider
   - `backstage` - Existing Backstage (separate)

4. **Integration Points**:
   - Shared Keycloak for SSO
   - Cross-namespace service discovery
   - Unified service catalog

## Development Workflow

1. **Platform Changes**: Modify files in `platform-apps/` and sync via Argo CD
2. **Team Onboarding**: Use Backstage scaffolder templates
3. **App Deployment**: Use Kargo for stage-based promotions
4. **Configuration**: Update via ConfigMaps and Argo CD applications

## Important Notes

- Kubrix Backstage runs separately from the existing Backstage installation
- Both can share authentication via Keycloak
- Services are accessible via Kubernetes DNS across namespaces
- The bootstrap process takes 20-30 minutes to complete
- Ensure k3s has sufficient resources (8+ CPU, 16GB+ RAM)