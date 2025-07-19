# Kubrix Deployment Options

Since your k3s cluster at `192.168.64.4` is not currently accessible, you have several options:

## Option 1: Start Your Existing k3s VM

If you have a VM (Multipass, Lima, VirtualBox, etc.) that hosts your k3s cluster:

```bash
# For Multipass
multipass start backstage-node

# For Lima
limactl start backstage-node

# For other VMs, use their respective commands
```

## Option 2: Use Docker Desktop Kubernetes

If you have Docker Desktop installed with Kubernetes enabled:

```bash
# Switch context to docker-desktop
kubectl config use-context docker-desktop

# Verify it's working
kubectl get nodes
```

## Option 3: Create a New k3s Instance

### Using k3d (k3s in Docker)
```bash
# Install k3d
brew install k3d

# Create a new cluster
k3d cluster create kubrix --api-port 6550 -p "80:80@loadbalancer" -p "443:443@loadbalancer"

# Set kubeconfig
kubectl config use-context k3d-kubrix
```

### Using kind (Kubernetes in Docker)
```bash
# Install kind
brew install kind

# Create cluster with ingress support
cat <<EOF | kind create cluster --name kubrix --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

## Option 4: Use Your Existing Setup

If your existing Backstage/Coder platform is working and you want to keep it:

1. Skip the Kubrix installation
2. Continue using your current platform
3. Consider adding Kubrix components gradually

## Next Steps

Once you have a working Kubernetes cluster:

1. Verify access:
   ```bash
   kubectl get nodes
   kubectl cluster-info
   ```

2. Continue with Kubrix installation:
   ```bash
   cd /Users/petermager/Downloads/code/kubrix
   ./scripts/bootstrap-kubrix.sh
   ```

## Recommendation

For local development, **k3d** is recommended because it:
- Runs entirely in Docker (no VM needed)
- Starts/stops quickly
- Uses less resources than a full VM
- Supports ingress out of the box