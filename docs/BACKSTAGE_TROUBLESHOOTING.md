# Backstage Blank Page Troubleshooting

## Issue
When accessing Backstage at `http://backstage.kubrix.local:30404`, you see a blank page.

## Root Cause
Backstage is a React single-page application (SPA) that loads JavaScript to render the UI. The blank page occurs when:
1. JavaScript files fail to load
2. Browser security blocks the scripts
3. CORS issues prevent resource loading

## Verified Working State
- ✅ Backstage pod is running
- ✅ Application responds with HTML (4307 bytes)
- ✅ Static assets are accessible (JS files return 200 OK)
- ✅ Health endpoints are responding

## Solutions

### 1. Hard Refresh the Page
- **Chrome/Edge**: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- **Firefox**: Ctrl+F5 (Windows/Linux) or Cmd+Shift+R (Mac)
- **Safari**: Cmd+Option+R

### 2. Clear Browser Cache
1. Open Developer Tools (F12)
2. Right-click the refresh button
3. Select "Empty Cache and Hard Reload"

### 3. Check Browser Console
1. Open Developer Tools (F12)
2. Go to Console tab
3. Look for red error messages
4. Common errors:
   - CORS errors: Try a different browser
   - Mixed content: Ensure using HTTP not HTTPS
   - Script errors: Clear cache and retry

### 4. Try Different Access Methods

#### Direct NodePort (Currently Working)
```bash
http://backstage.kubrix.local:30404
```

#### Via Port Forwarding
```bash
# Terminal 1: Port forward directly to Backstage service
kubectl port-forward -n backstage svc/backstage 7007:7007

# Terminal 2: Access in browser
http://localhost:7007
```

#### Using curl to Verify
```bash
# Should return HTML with <title>Scaffolded Backstage App</title>
curl -s http://backstage.kubrix.local:30404 | grep title
```

### 5. Alternative Browsers
If one browser shows a blank page, try:
- Chrome/Chromium
- Firefox
- Safari
- Edge

### 6. Disable Browser Extensions
Some extensions (ad blockers, script blockers) can interfere:
1. Try incognito/private mode
2. Temporarily disable extensions
3. Add backstage.kubrix.local to whitelist

## Verification Commands

```bash
# Check if Backstage is running
kubectl get pods -n backstage

# Check Backstage logs
kubectl logs -n backstage -l app=backstage --tail=50

# Test the endpoint
curl -I http://backstage.kubrix.local:30404

# Get full HTML response
curl http://backstage.kubrix.local:30404
```

## Working Configuration Confirmed
- Backstage Version: Latest
- Port: 7007 (container) → 7007 (service) → 30404 (NodePort)
- Ingress: backstage.kubrix.local → backstage service
- Static Assets: /static/* paths are accessible

## If Still Not Working
1. Check network connectivity to 192.168.64.4
2. Ensure no firewall blocking port 30404
3. Try wget or curl from the same machine
4. Check if other services (ArgoCD, Grafana) work normally