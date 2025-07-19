# Changelog

All notable changes to the Kubrix k3s deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- ✅ Ingress: Working via NodePort
- ✅ Cert-manager: Active
- ✅ Kyverno: Active
- ⚠️ Backstage: Placeholder page only
- ⚠️ Keycloak: Deployed but needs configuration
- ⚠️ Vault: Deployed but needs initialization
- ⚠️ Monitoring: CRDs only, no operator