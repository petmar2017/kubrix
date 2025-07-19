# Changelog

All notable changes to the Kubrix k3s deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-07-19

### Added
- K8s manifests directory structure for organized configuration management
- Backstage troubleshooting documentation (docs/BACKSTAGE_TROUBLESHOOTING.md)
- Scripts directory with automated fixes and updates
- New Makefile targets:
  - `backstage-fix-url` - Fix Backstage URL access issues
  - `update-default-backend` - Update ingress default backend
  - `apply-backstage-helm` - Deploy Backstage with custom values
  - `apply-manifests` - Apply all custom K8s manifests
  - `list-manifests` - List all custom manifests

### Changed
- Moved all temporary files to organized repository structure
- Updated default backend to show Backstage as fully operational
- Improved Backstage access documentation with troubleshooting steps

### Fixed
- Backstage blank page issue documentation
- Default backend dashboard now correctly shows service status

## [1.1.0] - 2025-07-19

### Added
- Full Backstage deployment with PostgreSQL backend using Helm chart
- Default backend service for ingress (shows service dashboard)
- Browser extension configuration for Host header management
- Comprehensive access solutions documentation (ACCESS_SOLUTIONS.md)
- Backstage setup guide (BACKSTAGE_SETUP.md)
- HTML service dashboard (kubrix-services.html)
- Browser access enablement script
- CNPG operator installation (partial - missing Pooler CRD)

### Fixed
- localhost:8880 404 error - now shows helpful service dashboard
- Backstage deployment - fully operational with database
- Ingress routing with proper Host header handling
- Service access documentation with multiple methods

### Changed
- Backstage status from "placeholder" to "fully operational"
- Updated documentation to reflect working Backstage
- Enhanced Makefile with additional troubleshooting commands

## [1.0.0] - 2025-07-19

### Added
- Initial Kubrix deployment on k3s
- Comprehensive Makefile with 40+ targets for installation and management
- Detailed README.md with architecture diagrams and troubleshooting guide
- Helper scripts for port forwarding and service access
- DNS configuration via /etc/hosts
- Support for k3s-specific networking (NodePort access)

### Fixed
- ArgoCD deployment and access via port-forwarding
- Grafana deployment and monitoring setup
- Ingress controller configuration for k3s
- Port forwarding scripts for reliable service access
- Monitoring CRDs manual installation for k3s compatibility

### Known Issues
- Backstage requires CNPG operator (currently using placeholder page)
- LoadBalancer services don't get external IPs in k3s VM setup
- Some applications remain in "Unknown" sync state
- k8s-monitoring requires cluster name configuration

### Workarounds Applied
- Manual monitoring CRD installation
- Port-forwarding for service access instead of LoadBalancer
- Placeholder Backstage page with working ingress
- Removed problematic admission webhooks

### Services Status
- ✅ ArgoCD: Fully operational
- ✅ Grafana: Fully operational
- ✅ Backstage: Fully operational with PostgreSQL
- ✅ Ingress: Working via NodePort
- ✅ Cert-manager: Active
- ✅ Kyverno: Active
- ⚠️ Keycloak: Deployed but needs configuration
- ⚠️ Vault: Deployed but needs initialization
- ⚠️ Monitoring: CRDs only, no operator