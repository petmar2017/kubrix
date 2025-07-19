# Backstage Setup Guide

## 🎉 Installation Complete!

The full Backstage developer portal is now running on your Kubrix platform with:
- ✅ PostgreSQL database backend
- ✅ Kubernetes integration ready
- ✅ Catalog system operational
- ✅ TechDocs ready

## 🌐 Access Methods

### 1. Via Browser (with Host Header)
You'll need a browser extension to set the Host header:

**Chrome**: Install [ModHeader](https://chrome.google.com/webstore/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj)
- Add rule: When URL contains `localhost:8880`
- Set header: `Host: backstage.kubrix.local`

**Firefox**: Install [Modify Header Value](https://addons.mozilla.org/en-US/firefox/addon/modify-header-value/)
- Configure similar rule

Then access: http://localhost:8880

### 2. Via Command Line
```bash
# View homepage
curl -H "Host: backstage.kubrix.local" http://localhost:8880

# Check API
curl -H "Host: backstage.kubrix.local" http://localhost:8880/api/catalog/entities
```

### 3. Direct NodePort Access
```bash
# Find the NodePort
kubectl get svc sx-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Access via VM IP (set Host header in browser)
http://192.168.64.4:30404
```

## 🚀 Quick Start

### 1. Verify Installation
```bash
# Check pods
kubectl get pods -n backstage

# Should see:
# backstage-<hash>           1/1     Running
# backstage-postgresql-0     1/1     Running
```

### 2. First Steps in Backstage

1. **Access the portal**: http://localhost:8880 (with Host header)
2. **Explore the Software Catalog**: Currently empty, ready for your components
3. **Create your first component**: Use the "Create Component" button
4. **Add existing services**: Import from your Git repositories

### 3. Add Your First Component

Create a `catalog-info.yaml` in your service repository:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  description: My awesome service
spec:
  type: service
  lifecycle: production
  owner: team-a
```

Then register it in Backstage via the UI.

## 🔧 Configuration

The Backstage configuration is stored in a ConfigMap:

```bash
# View current config
kubectl get configmap -n backstage

# Edit configuration
kubectl edit configmap backstage -n backstage
```

### Key Configuration Areas

1. **GitHub Integration**
   ```yaml
   integrations:
     github:
       - host: github.com
         token: ${GITHUB_TOKEN}
   ```

2. **Kubernetes Plugin**
   Already configured to connect to your local cluster!

3. **TechDocs**
   Configured for local generation and storage.

## 🔌 Next Steps

### 1. Enable GitHub Integration
```bash
# Create a GitHub token secret
kubectl create secret generic github-token \
  --from-literal=token=YOUR_GITHUB_TOKEN \
  -n backstage
```

### 2. Import Your Services
- Use the "Register Existing Component" feature
- Point to your `catalog-info.yaml` files
- Or use the discovery feature for automatic imports

### 3. Configure Authentication
Currently using guest access. To add authentication:
- Configure OAuth providers
- Set up LDAP/AD integration
- Or use the built-in database auth

### 4. Customize Your Portal
- Add custom plugins
- Modify the theme
- Create templates for your teams

## 🐛 Troubleshooting

### Can't Access Backstage?
```bash
# Check port forwarding
ps aux | grep "port-forward.*8880"

# Restart if needed
kubectl port-forward svc/sx-ingress-nginx-controller -n ingress-nginx 8880:80 &
```

### Database Issues?
```bash
# Check PostgreSQL
kubectl logs backstage-postgresql-0 -n backstage

# Check connection
kubectl exec -it backstage-postgresql-0 -n backstage -- psql -U backstage -d backstage -c "\dt"
```

### View Logs
```bash
# Backstage logs
kubectl logs deployment/backstage -n backstage

# Follow logs
kubectl logs -f deployment/backstage -n backstage
```

## 📚 Resources

- [Backstage Documentation](https://backstage.io/docs)
- [Software Catalog](https://backstage.io/docs/features/software-catalog/software-catalog-overview)
- [TechDocs](https://backstage.io/docs/features/techdocs/techdocs-overview)
- [Kubernetes Plugin](https://backstage.io/docs/features/kubernetes/overview)

## 🎊 Congratulations!

You now have a fully functional Backstage developer portal running on your Kubrix platform. Start adding your services and teams to unlock the full potential of your Internal Developer Platform!