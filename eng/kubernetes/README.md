# Kubernetes Manifests

This directory contains Kubernetes YAML manifests and deployment scripts for deploying the workshop applications to Azure Kubernetes Service (AKS).

## Structure

```text
kubernetes/
├── api-deployment.yaml       # API deployment, service, and config
├── frontend-deployment.yaml  # Frontend deployment, service, and config
├── ingress.yaml              # Ingress controller for external access
└── deploy.ps1                # Automated deployment script
```

## Manifests

### `api-deployment.yaml`

Defines Kubernetes resources for the WebApi backend:

- **Deployment**: Manages API pods with 2 replicas
- **Service**: ClusterIP service exposing port 8080
- **ConfigMap**: Configuration for API settings

### `frontend-deployment.yaml`

Defines Kubernetes resources for the Frontend application:

- **Deployment**: Manages Frontend pods with 2 replicas
- **Service**: ClusterIP service exposing port 8080
- **ConfigMap**: Configuration including API URL

### `ingress.yaml`

Defines the Ingress resource for external HTTP access:

- Routes traffic to Frontend and API services
- Configures path-based routing:
  - `/` → Frontend
  - `/api/*` → API
- Uses nginx ingress controller

## Deploy Script (`deploy.ps1`)

Automates the deployment of applications to AKS. Resource names are automatically constructed from the app identifier in `main.bicepparam`.

**Usage:**

```powershell
.\deploy.ps1
```

**Examples:**

```powershell
# Deploy with automatic resource name detection
.\deploy.ps1
```

**What it does:**

1. Reads the app identifier from `main.bicepparam`
2. Constructs resource names (Resource Group, AKS Cluster, ACR)
3. Installs kubectl and kubelogin if not present
4. Gets AKS cluster credentials
5. Retrieves ACR login server
6. Applies ingress configuration
7. Waits for ingress IP assignment
8. Deploys API with dynamic ACR image reference
9. Deploys Frontend with dynamic API URL
10. Displays deployment status and access URLs

## Prerequisites

- Azure CLI
- kubectl (auto-installed by script if missing)
- kubelogin (auto-installed by script if missing)
- AKS cluster deployed
- Container images pushed to ACR
- Azure login with access to the AKS cluster

## Deployment Flow

1. **Ingress Setup**: Creates ingress controller and waits for external IP
2. **API Deployment**: Deploys backend API with ACR image
3. **Frontend Deployment**: Deploys frontend with API URL configured
4. **Verification**: Checks pod status and displays access information

## Accessing the Application

After deployment, access the application at:

```text
http://<INGRESS-IP>
```

The ingress IP is displayed at the end of the deployment script.

## Updating Deployments

To update applications after code changes:

1. Build new container images
2. Push to ACR with new tags
3. Update image tags in YAML files or use the deploy script
4. Apply changes: `kubectl apply -f <manifest>.yaml`

## Troubleshooting

```powershell
# Check pod status
kubectl get pods

# View pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>

# Check services
kubectl get services

# Check ingress
kubectl get ingress
```
