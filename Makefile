# Kubrix Platform Makefile
# Automated deployment and management for Kubrix on k3s

.PHONY: help install uninstall status restart logs port-forward stop-forward update backup restore clean

# Default target
.DEFAULT_GOAL := help

# Variables
KUBRIX_DOMAIN := kubrix.local
K3S_VM_IP := 192.168.64.4
GITHUB_ORG := petmar2017
ARGOCD_PASSWORD := aFsfe93a-OgZSpby
KUBECONFIG := $(HOME)/.kube/config

# Color codes for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Help target
help: ## Show this help message
	@echo "$(GREEN)Kubrix Platform Management$(NC)"
	@echo "=========================="
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  1. make install       # Install Kubrix platform"
	@echo "  2. make port-forward  # Set up port forwarding"
	@echo "  3. make status        # Check deployment status"
	@echo ""

# Installation targets
install: check-prerequisites create-repos bootstrap ## Complete Kubrix installation
	@echo "$(GREEN)✅ Kubrix installation complete!$(NC)"
	@echo "Run 'make port-forward' to access services"

check-prerequisites: ## Check and install prerequisites
	@echo "$(YELLOW)Checking prerequisites...$(NC)"
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found. Please install kubectl."; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "Installing helm..."; brew install helm; }
	@command -v yq >/dev/null 2>&1 || { echo "Installing yq..."; brew install yq; }
	@command -v gomplate >/dev/null 2>&1 || { echo "Installing gomplate..."; brew install gomplate; }
	@echo "Testing k3s connectivity..."
	@kubectl get nodes >/dev/null 2>&1 || { echo "$(RED)Cannot connect to k3s cluster at $(K3S_VM_IP)$(NC)"; exit 1; }
	@echo "$(GREEN)✅ All prerequisites satisfied$(NC)"

create-repos: ## Create GitHub repositories
	@echo "$(YELLOW)Creating GitHub repositories...$(NC)"
	@if ! git ls-remote https://github.com/$(GITHUB_ORG)/kubrix >/dev/null 2>&1; then \
		echo "Creating kubrix repository..."; \
		gh repo create $(GITHUB_ORG)/kubrix --public --description "Kubrix platform deployment" 2>/dev/null || true; \
	fi
	@if ! git ls-remote https://github.com/$(GITHUB_ORG)/kubrix-platform >/dev/null 2>&1; then \
		echo "Creating kubrix-platform repository..."; \
		gh repo create $(GITHUB_ORG)/kubrix-platform --public --description "Kubrix platform configuration" 2>/dev/null || true; \
	fi
	@if ! git ls-remote https://github.com/$(GITHUB_ORG)/kubrix-demo-apps >/dev/null 2>&1; then \
		echo "Creating kubrix-demo-apps repository..."; \
		gh repo create $(GITHUB_ORG)/kubrix-demo-apps --public --description "Kubrix demo applications" 2>/dev/null || true; \
	fi
	@echo "$(GREEN)✅ Repositories ready$(NC)"

bootstrap: ## Bootstrap Kubrix platform
	@echo "$(YELLOW)Bootstrapping Kubrix platform...$(NC)"
	@if [ ! -f .env ]; then \
		echo "Creating .env file..."; \
		./scripts/create-env.sh; \
	fi
	@echo "Running bootstrap script..."
	@./scripts/bootstrap-kubrix.sh
	@echo "$(GREEN)✅ Bootstrap complete$(NC)"

# Management targets
status: ## Show deployment status
	@echo "$(GREEN)=== Kubrix Deployment Status ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Applications:$(NC)"
	@kubectl get applications -n argocd 2>/dev/null | grep -E "(NAME|Synced.*Healthy)" || echo "ArgoCD not ready"
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@kubectl get svc -A | grep -E "(argocd|grafana|keycloak|vault|kargo|backstage)" | awk '{printf "  %-20s %-20s %s\n", $$1, $$2, $$5}'
	@echo ""
	@echo "$(YELLOW)Ingresses:$(NC)"
	@kubectl get ingress -A 2>/dev/null || echo "No ingresses found"
	@echo ""
	@echo "$(YELLOW)Access URLs:$(NC)"
	@ps aux | grep -q "[k]ubectl port-forward.*8080" && echo "  ArgoCD:  http://localhost:8080" || echo "  ArgoCD:  Not forwarded (run 'make port-forward')"
	@ps aux | grep -q "[k]ubectl port-forward.*3000" && echo "  Grafana: http://localhost:3000" || echo "  Grafana: Not forwarded"

port-forward: ## Start port forwarding for all services
	@echo "$(YELLOW)Starting port forwarding...$(NC)"
	@pkill -f "kubectl port-forward" 2>/dev/null || true
	@sleep 2
	@kubectl port-forward svc/sx-argocd-server -n argocd 8080:80 > /dev/null 2>&1 &
	@kubectl port-forward svc/sx-grafana -n grafana 3000:80 > /dev/null 2>&1 &
	@kubectl port-forward svc/sx-ingress-nginx-controller -n ingress-nginx 8880:80 > /dev/null 2>&1 &
	@sleep 3
	@echo "$(GREEN)✅ Port forwarding started$(NC)"
	@echo ""
	@echo "Access services at:"
	@echo "  • ArgoCD:  http://localhost:8080 (admin/$(ARGOCD_PASSWORD))"
	@echo "  • Grafana: http://localhost:3000"
	@echo "  • Ingress: http://localhost:8880 (use Host header)"

stop-forward: ## Stop all port forwarding
	@echo "$(YELLOW)Stopping port forwarding...$(NC)"
	@pkill -f "kubectl port-forward" 2>/dev/null || echo "No port-forward processes found"
	@echo "$(GREEN)✅ Port forwarding stopped$(NC)"

restart: ## Restart all Kubrix applications
	@echo "$(YELLOW)Restarting Kubrix applications...$(NC)"
	@kubectl rollout restart deployment -n argocd
	@kubectl rollout restart deployment -n grafana 2>/dev/null || true
	@kubectl rollout restart deployment -n backstage 2>/dev/null || true
	@echo "$(GREEN)✅ Applications restarted$(NC)"

logs: ## Show logs for key services
	@echo "$(YELLOW)=== ArgoCD Logs ===$(NC)"
	@kubectl logs -n argocd deployment/sx-argocd-server --tail=20
	@echo ""
	@echo "$(YELLOW)=== Bootstrap App Status ===$(NC)"
	@kubectl describe application sx-bootstrap-app -n argocd | grep -A 10 "Status:"

# Maintenance targets
update: ## Update Kubrix platform
	@echo "$(YELLOW)Updating Kubrix platform...$(NC)"
	@kubectl annotate applications -n argocd --all argocd.argoproj.io/refresh=true --overwrite
	@echo "$(GREEN)✅ Refresh triggered for all applications$(NC)"

backup: ## Backup Kubrix configuration
	@echo "$(YELLOW)Creating backup...$(NC)"
	@mkdir -p backups
	@kubectl get applications -n argocd -o yaml > backups/applications-$$(date +%Y%m%d-%H%M%S).yaml
	@kubectl get cm -n argocd -o yaml > backups/configmaps-$$(date +%Y%m%d-%H%M%S).yaml
	@kubectl get secrets -n argocd -o yaml > backups/secrets-$$(date +%Y%m%d-%H%M%S).yaml
	@echo "$(GREEN)✅ Backup created in backups/ directory$(NC)"

restore: ## Restore from backup (specify BACKUP_DATE)
	@if [ -z "$(BACKUP_DATE)" ]; then \
		echo "$(RED)Please specify BACKUP_DATE, e.g., make restore BACKUP_DATE=20240119-140523$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring from backup $(BACKUP_DATE)...$(NC)"
	@kubectl apply -f backups/applications-$(BACKUP_DATE).yaml
	@kubectl apply -f backups/configmaps-$(BACKUP_DATE).yaml
	@kubectl apply -f backups/secrets-$(BACKUP_DATE).yaml
	@echo "$(GREEN)✅ Restore complete$(NC)"

# Cleanup targets
clean: ## Remove all Kubrix resources
	@echo "$(RED)⚠️  WARNING: This will remove all Kubrix resources!$(NC)"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Removing Kubrix resources...$(NC)"
	@kubectl delete applications -n argocd --all 2>/dev/null || true
	@kubectl delete ns argocd backstage keycloak grafana vault 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

uninstall: clean ## Complete uninstall of Kubrix
	@echo "$(YELLOW)Removing additional resources...$(NC)"
	@kubectl delete crd applications.argoproj.io 2>/dev/null || true
	@kubectl delete crd applicationsets.argoproj.io 2>/dev/null || true
	@echo "$(GREEN)✅ Kubrix uninstalled$(NC)"

# Utility targets
open-argocd: ## Open ArgoCD in browser
	@open http://localhost:8080 2>/dev/null || echo "Please run 'make port-forward' first"

open-grafana: ## Open Grafana in browser
	@open http://localhost:3000 2>/dev/null || echo "Please run 'make port-forward' first"

test-ingress: ## Test ingress connectivity
	@echo "$(YELLOW)Testing ingress endpoints...$(NC)"
	@for domain in argocd grafana backstage keycloak vault kargo; do \
		printf "%-20s " "$$domain.$(KUBRIX_DOMAIN):"; \
		curl -s -o /dev/null -w "%{http_code}\n" -H "Host: $$domain.$(KUBRIX_DOMAIN)" http://localhost:8880 2>/dev/null || echo "Failed"; \
	done

health-check: ## Check health of all services
	@echo "$(GREEN)=== Kubrix Service Health Check ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Core Services:$(NC)"
	@kubectl get pods -n argocd | grep -E "(NAME|Running)" || echo "  ArgoCD: Not running"
	@kubectl get pods -n grafana | grep -E "(NAME|Running)" || echo "  Grafana: Not running"
	@kubectl get pods -n backstage | grep -E "(NAME|Running)" || echo "  Backstage: Not running"
	@echo ""
	@echo "$(YELLOW)Application Status:$(NC)"
	@kubectl get applications -n argocd | grep -E "(NAME|Synced.*Healthy)" | head -10
	@echo ""
	@echo "$(YELLOW)Ingress Status:$(NC)"
	@kubectl get ingress -A --no-headers | wc -l | xargs printf "  Total ingresses: %s\n"
	@echo ""
	@echo "Run 'make test-ingress' to test connectivity"

fix-hosts: ## Update /etc/hosts file
	@echo "$(YELLOW)Updating /etc/hosts...$(NC)"
	@echo "$(RED)This requires sudo access$(NC)"
	@sudo ./update-hosts.sh

sync-apps: ## Force sync all applications
	@echo "$(YELLOW)Syncing all applications...$(NC)"
	@for app in $$(kubectl get applications -n argocd -o name); do \
		echo "Syncing $$app..."; \
		kubectl patch $$app -n argocd --type merge -p '{"operation":{"sync":{"revision":"main"}}}' || true; \
	done
	@echo "$(GREEN)✅ Sync triggered for all applications$(NC)"

# Debug targets
debug-app: ## Debug specific application (specify APP=app-name)
	@if [ -z "$(APP)" ]; then \
		echo "$(RED)Please specify APP, e.g., make debug-app APP=sx-backstage$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)=== Debugging $(APP) ===$(NC)"
	@kubectl describe application $(APP) -n argocd
	@echo ""

# Backstage specific targets
backstage-status: ## Check Backstage deployment status
	@echo "$(YELLOW)=== Backstage Status ===$(NC)"
	@kubectl get pods -n backstage
	@echo ""
	@echo "$(YELLOW)Backstage Services:$(NC)"
	@kubectl get svc -n backstage
	@echo ""
	@echo "$(YELLOW)Backstage Ingress:$(NC)"
	@kubectl get ingress -n backstage
	@echo ""

backstage-logs: ## Show Backstage logs
	@kubectl logs -n backstage -l app=backstage --tail=50

backstage-db-logs: ## Show Backstage PostgreSQL logs
	@kubectl logs -n backstage -l app.kubernetes.io/name=postgresql --tail=50

backstage-test: ## Test Backstage API endpoints
	@echo "$(YELLOW)Testing Backstage endpoints...$(NC)"
	@echo -n "Homepage: "
	@curl -s -o /dev/null -w "%{http_code}\n" -H "Host: backstage.kubrix.local" http://localhost:8880 || echo "Failed"
	@echo -n "API Health: "
	@curl -s -o /dev/null -w "%{http_code}\n" -H "Host: backstage.kubrix.local" http://localhost:8880/api/catalog/entities || echo "Failed"
	@echo ""

backstage-open: ## Open Backstage in browser (requires Host header)
	@echo "$(YELLOW)Opening Backstage...$(NC)"
	@echo "Note: You need a browser extension to set Host header"
	@echo "Or access the service dashboard at: http://localhost:8880"
	@open http://localhost:8880

backstage-fix-url: ## Fix Backstage URL access issues
	@./scripts/fix-backstage-url.sh

update-default-backend: ## Update ingress default backend dashboard
	@cd scripts && ./update-default-backend.sh

apply-backstage-helm: ## Deploy Backstage using Helm with custom values
	@echo "$(YELLOW)Deploying Backstage with Helm...$(NC)"
	@helm upgrade --install backstage backstage/backstage \
		-n backstage --create-namespace \
		-f k8s-manifests/backstage/backstage-values.yaml \
		--wait --timeout=5m
	@echo "$(GREEN)✅ Backstage deployed successfully$(NC)"
	@echo "$(YELLOW)=== Recent Events ===$(NC)"
	@kubectl get events -n argocd --field-selector involvedObject.name=$(APP) --sort-by='.lastTimestamp' | tail -10

# K8s Manifests Management
apply-manifests: ## Apply all custom K8s manifests
	@echo "$(YELLOW)Applying custom manifests...$(NC)"
	@kubectl apply -f k8s-manifests/ingress/default-backend.yaml || true
	@echo "$(GREEN)✅ Manifests applied$(NC)"

list-manifests: ## List all custom K8s manifests
	@echo "$(YELLOW)Custom K8s Manifests:$(NC)"
	@find k8s-manifests -name "*.yaml" -type f | sort

check-crds: ## Check installed CRDs
	@echo "$(YELLOW)Installed CRDs:$(NC)"
	@kubectl get crd | grep -E "(monitoring|argoproj|cnpg|external-secrets)" | awk '{print "  " $$1}'

# Development targets
dev-postgres: ## Deploy standalone PostgreSQL for development
	@echo "$(YELLOW)Deploying PostgreSQL...$(NC)"
	@kubectl apply -f dev/postgres.yaml
	@echo "$(GREEN)✅ PostgreSQL deployed$(NC)"

dev-monitoring-crds: ## Install monitoring CRDs manually
	@echo "$(YELLOW)Installing monitoring CRDs...$(NC)"
	@kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
	@kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
	@kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
	@echo "$(GREEN)✅ Monitoring CRDs installed$(NC)"

# Git targets
git-status: ## Show git status for all repos
	@echo "$(YELLOW)=== kubrix repo ===$(NC)"
	@git status -s
	@echo ""
	@if [ -d ../kubrix-platform ]; then \
		echo "$(YELLOW)=== kubrix-platform repo ===$(NC)"; \
		cd ../kubrix-platform && git status -s; \
	fi

git-commit: ## Commit all changes
	@git add -A
	@git commit -m "Update Kubrix configuration" || echo "No changes to commit"
	@git push origin main