# Task 4: Deploy to Azure Kubernetes Service (AKS)

## Overview

In this final task, you'll deploy your containerized applications to Azure Kubernetes Service (AKS), Microsoft's managed Kubernetes offering. This provides:

- Full control over container orchestration
- Advanced deployment strategies
- Kubernetes-native tools and ecosystem
- Production-grade container management

You'll learn to:

- Deploy AKS infrastructure with Bicep
- Connect to your AKS cluster
- Understand Kubernetes manifests (YAML files)
- Deploy applications using kubectl
- Explore Kubernetes resources (Pods, Services, Deployments)
- Configure ingress for external access
- Update and scale applications

**Estimated Time:** 30 minutes

---

## Prerequisites

Before starting, ensure you have:

- ✅ Completed Task 1: Local Docker Setup
- ✅ Container images built and pushed to ACR
- ✅ Azure CLI installed and logged in
- ✅ kubectl (Kubernetes CLI) installed

### Verify kubectl Installation

```powershell
kubectl version --client
```

If kubectl is not installed:

```powershell
az aks install-cli
```

---

## Part 1: Understanding Kubernetes Concepts

### 1.1 Key Kubernetes Components

**Pod:**

- Smallest deployable unit in Kubernetes
- Wraps one or more containers
- Shares network and storage
- Ephemeral - can be replaced at any time

**Deployment:**

- Manages a set of replica Pods
- Ensures desired number of Pods are running
- Handles rolling updates and rollbacks
- Declaratively manages application state

**Service:**

- Stable network endpoint for Pods
- Load balances traffic across Pod replicas
- Types: ClusterIP (internal), LoadBalancer (external), NodePort

**Ingress:**

- HTTP/HTTPS routing to services
- Single entry point for multiple services
- URL-based routing, SSL termination
- Requires an Ingress Controller

### 1.2 Kubernetes vs Container Apps vs App Service

| Feature | AKS (Kubernetes) | Container Apps | App Service |
|---------|------------------|----------------|-------------|
| **Control** | Full control | Managed | Fully managed |
| **Complexity** | High | Medium | Low |
| **Flexibility** | Maximum | Good | Limited |
| **Learning Curve** | Steep | Moderate | Easy |
| **Use Case** | Complex microservices | Event-driven apps | Simple web apps |
| **Cost** | Pay for nodes | Pay per use | Pay for plan |

---

## Part 2: Deploy AKS Infrastructure

### 2.1 Review the AKS Bicep Template

Navigate to the infrastructure folder:

```powershell
cd eng\infrastructure
```

**Review the AKS Bicep template:**

```powershell
code main-aks.bicep
```

**Key resources created:**

- Resource Group
- Azure Container Registry (ACR)
- AKS Cluster with:
  - System node pool (for Kubernetes system components)
  - Managed identity for authentication
  - Web Application Routing add-on enabled
  - Azure Policy and Key Vault integration
  - Integration with ACR (pull images without credentials)

### 2.2 Deploy the AKS Infrastructure

Run the deployment script:

```powershell
.\deploy.ps1 -DeploymentType Kubernetes
```

**Confirm deployment:**

```text
Deploying to subscription: <Your Subscription Name>
Deployment Type: Kubernetes
Continue? (yes/no): yes
```

**What happens:**

1. Validates prerequisites and Azure login
2. Deploys the Bicep template
3. Creates AKS cluster with node pools
4. Configures networking and add-ons
5. Sets up ACR integration

**Expected output:**

```text
Deploying: main-aks.bicep
[████████████████████] Deployment in progress...

✓ Deployment completed: workshop-aks-20251121-163045
```

**Deployment time:** Approximately 5-8 minutes (AKS clusters take longer to provision)

### 2.3 Verify Resources in Azure Portal

**Open Azure Portal:**

Navigate to: <https://portal.azure.com>

**Locate your Resource Group:**

1. Search for "Resource groups"
2. Find `rg-cwt01-dev-weu` (or your app identifier with environment and location)

**Verify created resources:**

- `crcwt01devweu` - Container Registry
- `aks-cwt01-dev-weu` - AKS Cluster
- Additional node resource group (auto-created): `MC_rg-cwt01-dev-weu_aks-cwt01-dev-weu_westeurope`

**Explore the AKS cluster:**

1. Click on the AKS cluster
2. View **Overview** for cluster status
3. Check **Node pools** - you should see system node pool with 2-3 nodes
4. View **Insights** for monitoring (may take a few minutes to populate)

---

## Part 3: Understand Kubernetes Manifests

Before deploying, let's understand the Kubernetes YAML files.

### 3.1 Review WebApi Deployment Manifest

Navigate to the Kubernetes folder:

```powershell
cd eng\kubernetes
```

**Open the WebApi manifest:**

```powershell
code api-deployment.yaml
```

**Key sections explained:**

```yaml
# Deployment - Manages the application pods
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapi        # Deployment name
spec:
  replicas: 1         # Number of pod replicas
  selector:
    matchLabels:
      app: webapi     # Selector to match pods
  template:
    metadata:
      labels:
        app: webapi   # Labels applied to pods
    spec:
      containers:
      - name: webapi
        image: ${ACR_LOGIN_SERVER}/container-workshop/webapi:latest
        ports:
        - containerPort: 8080  # Port the container listens on
        resources:
          requests:             # Minimum resources guaranteed
            cpu: 100m
            memory: 128Mi
          limits:               # Maximum resources allowed
            cpu: 250m
            memory: 256Mi
---
# Service - Provides stable networking
apiVersion: v1
kind: Service
metadata:
  name: webapi
spec:
  type: ClusterIP     # Internal service (only accessible within cluster)
  ports:
  - port: 8080        # Service port
    targetPort: 8080  # Container port
  selector:
    app: webapi       # Routes to pods with this label
---
# LoadBalancer Service - Provides external access
apiVersion: v1
kind: Service
metadata:
  name: webapi-lb
spec:
  type: LoadBalancer  # External service with public IP
  ports:
  - port: 80          # External port
    targetPort: 8080  # Container port
  selector:
    app: webapi
```

**Note:** Both a ClusterIP service (for internal communication) and a LoadBalancer service (for external access) are created.

### 3.2 Review Frontend Deployment Manifest

**Open the Frontend manifest:**

```powershell
code frontend-deployment.yaml
```

**Notable differences:**

```yaml
env:
- name: APP_API_BASE_URL
  value: "http://${INGRESS_IP}/api"
```

The frontend is configured with the ingress IP address to call the API at `/api`, which routes through the ingress to the internal webapi service.

### 3.3 Review Ingress Manifest

**Open the Ingress manifest:**

```powershell
code ingress.yaml
```

**Ingress configuration:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: workshop-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: frontend
              port:
                number: 8080
        - path: /api(/|$)(.*)
          pathType: Prefix
          backend:
            service:
              name: webapi
              port:
                number: 8080
```

**How it works:**

- Creates a single IP address entry point for the application
- Uses path-based routing: `/api` requests go to the API service, all other paths to the frontend
- The `/api` path uses regex and rewrite rules to properly route requests
- The frontend calls the API through the same IP address at `/api`
- Uses the Web Application Routing add-on with the `webapprouting.kubernetes.azure.com` ingress class

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: workshop-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: frontend
              port:
                number: 8080

        - path: /api(/|$)(.*)
          pathType: Prefix
          backend:
            service:
              name: webapi
              port:
                number: 8080
```

**How it works:**

- Creates a single DNS entry for the application
- Uses path-based routing: `/api` goes to the API service, all other paths to the frontend
- The frontend calls the API through the same domain at `/api`
- Uses HTTP Application Routing add-on for simplicity

---

## Part 4: Deploy Applications to AKS

### 4.1 Deploy Using the PowerShell Script

**Navigate to the Kubernetes folder:**

```powershell
cd eng\kubernetes
```

**Run the deployment script:**

```powershell
.\deploy.ps1
```

**What the script does:**

The deployment script automates the entire deployment process:

1. **Installs kubectl and kubelogin** - Ensures the required CLI tools are available (skips if already installed)
2. **Gets AKS credentials** - Downloads cluster connection information using admin credentials and configures kubectl
3. **Retrieves ACR login server** - Gets your Azure Container Registry URL to reference the correct images
4. **Applies the Ingress** - Creates the ingress controller first and waits for an external IP to be assigned
5. **Replaces placeholders in YAML files** - Substitutes `${ACR_LOGIN_SERVER}` and `${INGRESS_IP}` with actual values
6. **Deploys applications** - Applies the API and frontend deployments with the correct configuration
7. **Shows deployment status and URLs** - Displays the application URLs (IP-based) and pod status

**Expected output:**

```text
kubectl and kubelogin are already installed.
Getting AKS credentials...
Merged "aks-cwt01-dev-weu" as current context in C:\Users\<username>\.kube\config

Getting ACR login server...

Applying Kubernetes manifests...
ACR Login Server: crcwt01devweu.azurecr.io

ingress.networking.k8s.io/workshop-ingress created

Waiting for ingress to get an external IP...
..........
Ingress IP: 20.123.45.67

deployment.apps/webapi created
service/webapi created
service/webapi-lb created
deployment.apps/frontend created
service/frontend created
service/frontend-lb created

Deployment complete!

Application URLs:
Frontend: http://20.123.45.67
API: http://20.123.45.67/api

Checking pod status...
NAME                        READY   STATUS    RESTARTS   AGE
webapi-7c5b9d4f8-xw2kl      1/1     Running   0          30s
frontend-8f6d5c7b9-kp4mn    1/1     Running   0          30s
```

---

## Part 5: Explore Your AKS Cluster (Optional)

The deployment script automatically configured kubectl for you. If you want to explore your cluster directly, here are some useful commands:

### 5.1 Verify Connection

**Check cluster connection:**

```powershell
kubectl cluster-info
```

**List cluster nodes:**

```powershell
kubectl get nodes
```

You should see 2-3 nodes in "Ready" status.

### 5.2 Explore Existing Resources

**View all namespaces:**

```powershell
kubectl get namespaces
```

**View system pods:**

```powershell
kubectl get pods -n kube-system
```

---

## Part 6: Verify and Test the Deployment

### 6.1 Check Pod Status

**List all pods:**

```powershell
kubectl get pods
```

Expected output:

```text
NAME                        READY   STATUS    RESTARTS   AGE
webapi-7c5b9d4f8-xw2kl      1/1     Running   0          2m
frontend-8f6d5c7b9-kp4mn    1/1     Running   0          2m
```

**Watch pods in real-time:**

```powershell
kubectl get pods -w
```

Press `Ctrl+C` to stop watching.

**Describe a pod for detailed info:**

```powershell
kubectl describe pod <pod-name>
```

### 6.2 Check Services

**List services:**

```powershell
kubectl get services
```

Expected output:

```text
NAME          TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
kubernetes    ClusterIP      10.0.0.1       <none>         443/TCP        15m
webapi        ClusterIP      10.0.123.45    <none>         8080/TCP       5m
webapi-lb     LoadBalancer   10.0.123.46    20.123.45.68   80:32001/TCP   5m
frontend      ClusterIP      10.0.234.56    <none>         8080/TCP       5m
frontend-lb   LoadBalancer   10.0.234.57    20.123.45.69   80:32002/TCP   5m
```

### 6.3 Check Ingress

**List ingress resources:**

```powershell
kubectl get ingress
```

Expected output:

```text
NAME                CLASS                                    ADDRESS        PORTS   AGE
workshop-ingress    webapprouting.kubernetes.azure.com       20.123.45.67   80      3m
```

**Wait for ADDRESS** to be assigned (may take 1-2 minutes).

**Get detailed ingress info:**

```powershell
kubectl describe ingress workshop-ingress
```

### 6.4 Test the Applications

**Get the application URLs from the deployment output, or retrieve them:**

```powershell
$ingressIp = kubectl get ingress workshop-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$appUrl = "http://$ingressIp"

Write-Host "Application: $appUrl"
Write-Host "API: $appUrl/api"
```

**Test the API:**

```powershell
curl "$appUrl/api/pizzas"
```

Expected: JSON array of pizzas.

**Test the Frontend:**

Open the application URL in your browser (the IP address shown in the deployment output). You should see the shopping application with pizzas loaded from the API at `/api`.

---

## Part 7: Explore Kubernetes Resources

### 7.1 View Pod Logs

**Get WebApi logs:**

```powershell
kubectl logs deployment/webapi
```

**Get Frontend logs:**

```powershell
kubectl logs deployment/frontend
```

**Follow logs in real-time:**

```powershell
kubectl logs -f deployment/webapi
```

### 7.2 Execute Commands in Pods

**Get an interactive shell in WebApi pod:**

```powershell
kubectl exec -it deployment/webapi -- /bin/sh
```

Inside the pod:

```sh
# Check environment
env | grep -i api

# Check running process
ps aux

# Test local connectivity
wget -O- localhost:8080/pizzas

# Exit
exit
```

### 7.3 View Deployment Details

**Get deployments:**

```powershell
kubectl get deployments
```

**Describe WebApi deployment:**

```powershell
kubectl describe deployment webapi
```

This shows:

- Replica configuration
- Pod template
- Events (scaling, updates, errors)
- Current status

### 7.4 View Resource Usage

**Get resource usage of pods:**

```powershell
kubectl top pods
```

This shows CPU and memory usage (requires metrics-server, which is enabled by default in AKS).

**Get node resource usage:**

```powershell
kubectl top nodes
```

---

## Part 8: Scale Applications

### 8.1 Manual Scaling

**Scale WebApi to 3 replicas:**

```powershell
kubectl scale deployment webapi --replicas=3
```

**Verify scaling:**

```powershell
kubectl get pods -l app=webapi
```

You should see 3 WebApi pods running.

**Scale back to 1:**

```powershell
kubectl scale deployment webapi --replicas=1
```

### 8.2 Update the Deployment Manifest

For permanent changes, update the YAML file:

**Edit api-deployment.yaml:**

```yaml
spec:
  replicas: 3  # Change from 1 to 3
```

**Apply the change:**

```powershell
kubectl apply -f api-deployment.yaml
```

### 8.3 Auto-scaling with HPA

**Create a Horizontal Pod Autoscaler:**

```powershell
kubectl autoscale deployment webapi --cpu-percent=50 --min=1 --max=10
```

**View the HPA:**

```powershell
kubectl get hpa
```

**What it does:**

- Monitors CPU usage of WebApi pods
- Scales up when average CPU > 50%
- Scales down when CPU is lower
- Maintains 1-10 replicas

---

## Part 9: Update Applications

### 9.1 Make a Code Change

Let's update the WebApi with a new pizza.

**Navigate to WebApi:**

```powershell
cd ..\..\src\WebApi
```

**Edit Program.cs:**

Add a new pizza:

```csharp
new Pizza(
    7,
    "Calzone",
    "Folded pizza with ham, mushrooms, and mozzarella",
    ["Tomato Sauce", "Mozzarella", "Ham", "Mushrooms"]
)
```

### 9.2 Build and Push New Image

**Build version 1.2 (or your next version):**

```powershell
.\build.ps1
```

**Tag as latest:**

```powershell
$version = Get-Content .version
docker tag "container-workshop/webapi:$version" "$acrLoginServer/container-workshop/webapi:latest"
```

**Push to ACR:**

```powershell
docker push "$acrLoginServer/container-workshop/webapi:latest"
```

### 9.3 Rolling Update

**Restart the deployment to pull the new image:**

```powershell
kubectl rollout restart deployment/webapi
```

**Watch the rolling update:**

```powershell
kubectl rollout status deployment/webapi
```

**What happens:**

1. Kubernetes creates a new pod with the updated image
2. Waits for it to be Ready
3. Terminates the old pod
4. Zero-downtime update!

**Verify the update:**

```powershell
$ingressIp = kubectl get ingress workshop-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
curl "http://$ingressIp/api/pizzas"
```

You should see 7 pizzas including "Calzone".

### 9.4 Rollback (if needed)

**View rollout history:**

```powershell
kubectl rollout history deployment/webapi
```

**Rollback to previous version:**

```powershell
kubectl rollout undo deployment/webapi
```

**Rollback to specific revision:**

```powershell
kubectl rollout undo deployment/webapi --to-revision=2
```

---

## Part 10: Advanced Kubernetes Features

### 10.1 ConfigMaps for Configuration

**Create a ConfigMap:**

```powershell
kubectl create configmap api-config --from-literal=MAX_PRODUCTS=100
```

**Use in deployment:**

```yaml
env:
- name: MAX_PRODUCTS
  valueFrom:
    configMapKeyRef:
      name: api-config
      key: MAX_PRODUCTS
```

### 10.2 Secrets for Sensitive Data

**Create a secret:**

```powershell
kubectl create secret generic db-password --from-literal=password='mySecretPassword'
```

**Use in deployment:**

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-password
      key: password
```

### 10.3 Health Checks

**Add liveness and readiness probes to deployment:**

```yaml
containers:
- name: webapi
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 10
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 5
```

Kubernetes uses these to:

- **Liveness:** Restart unhealthy pods
- **Readiness:** Remove unready pods from service load balancing

### 10.4 Resource Quotas

**Create a resource quota for namespace:**

```powershell
kubectl create quota dev-quota --hard=cpu=2,memory=4Gi,pods=10
```

This limits total resource usage in the namespace.

---

## Part 11: Monitoring and Troubleshooting

### 11.1 View Events

**Get recent events:**

```powershell
kubectl get events --sort-by='.lastTimestamp'
```

This shows scheduling, pulling images, creating pods, errors, etc.

### 11.2 Debug Pod Issues

**Common scenarios:**

#### Pod stuck in "Pending"

```powershell
kubectl describe pod <pod-name>
```

Look for events like:

- "Insufficient CPU/memory" → Increase node capacity
- "Image pull backoff" → Check image name and registry access

#### Pod in "CrashLoopBackOff"

```powershell
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Get logs from crashed container
```

Common causes:

- Application startup errors
- Missing environment variables
- Port conflicts

### 11.3 Network Troubleshooting

**Test connectivity between pods:**

```powershell
kubectl run test-pod --image=curlimages/curl --rm -it -- sh
```

Inside the test pod:

```sh
curl http://webapi/pizzas
curl http://frontend
```

### 11.4 Azure Monitor Integration

**View container insights:**

1. In Azure Portal, open your AKS cluster
2. Go to **Monitoring** → **Insights**
3. View:
   - Node performance
   - Pod metrics
   - Container logs
   - Deployment health

---

## Part 12: Cleanup

### 12.1 Delete Kubernetes Resources

**Delete all workshop resources:**

```powershell
kubectl delete deployment webapi frontend
kubectl delete service webapi frontend
kubectl delete ingress workshop-ingress
```

**Or delete all resources at once:**

```powershell
cd ..\..\eng\kubernetes
kubectl delete -f api-deployment.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f ingress.yaml
```

### 12.2 Delete Azure Resources

**Using the destroy script:**

```powershell
cd ..\infrastructure
.\destroy.ps1
```

**Or manually in Azure Portal:**

1. Navigate to resource group `rg-cwt01-dev-weu`
2. Click **Delete resource group**
3. Confirm deletion

---

## Summary

In this task, you've learned how to:

✅ Deploy AKS infrastructure with Bicep  
✅ Connect to AKS cluster with kubectl  
✅ Understand Kubernetes manifests (Deployments, Services, Ingress)  
✅ Deploy containerized applications to Kubernetes  
✅ Configure ingress for external access  
✅ View and troubleshoot pods, services, and logs  
✅ Scale applications manually and automatically  
✅ Perform rolling updates with zero downtime  
✅ Rollback deployments  
✅ Use ConfigMaps and Secrets  
✅ Monitor application health and performance  

**Key Kubernetes Concepts:**

- **Pods:** Smallest unit, wraps containers
- **Deployments:** Manage replica sets and updates
- **Services:** Stable networking for pods
- **Ingress:** HTTP routing to services
- **ConfigMaps/Secrets:** Configuration and sensitive data
- **HPA:** Automatic scaling based on metrics

**When to Use AKS:**

- Complex microservices architectures
- Need for fine-grained control
- Advanced networking requirements
- Multi-tenancy and namespace isolation
- Integration with Kubernetes ecosystem tools
- Enterprise-grade container orchestration

---

## Workshop Complete! 🎉

Congratulations! You've completed the Container Workshop and learned:

1. **Local Development:** Build and run containers with Docker
2. **App Service:** Deploy to fully managed platform
3. **Container Apps:** Serverless container hosting with revisions
4. **AKS/Kubernetes:** Full control with orchestration platform

### Next Steps

- Explore advanced Kubernetes features (StatefulSets, DaemonSets, Jobs)
- Implement CI/CD pipelines with GitHub Actions or Azure DevOps
- Set up monitoring with Prometheus and Grafana
- Learn about service meshes (Istio, Linkerd)
- Explore Azure Arc for hybrid Kubernetes management
- Study Helm for package management

### Resources

- [Azure Kubernetes Service Documentation](https://learn.microsoft.com/azure/aks/)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Docker Documentation](https://docs.docker.com/)

Thank you for participating in this workshop!
