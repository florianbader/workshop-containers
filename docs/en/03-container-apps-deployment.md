# Task 3: Deploy to Azure Container Apps

## Overview

In this task, you'll deploy your containerized applications to Azure Container Apps, a serverless container hosting platform that offers:

- Automatic scaling (including scale-to-zero)
- Built-in revision management
- Simplified networking and ingress
- Microservices-friendly architecture

You'll learn to:

- Deploy Container Apps infrastructure with Bicep
- Manually configure container images
- Create and manage revisions
- Make code changes and deploy new revisions
- Split traffic between revisions

**Estimated Time:** 30 minutes

---

## Prerequisites

Before starting, ensure you have:

- ✅ Completed Task 1: Local Docker Setup
- ✅ Container images built and pushed to ACR
- ✅ Azure CLI installed and logged in

---

## Part 1: Understanding Azure Container Apps

### 1.1 Key Concepts

**Container Apps Environment:**

- Shared boundary for your Container Apps
- Provides networking, logging, and monitoring
- Apps in the same environment can communicate privately

**Container App:**

- Individual application running in containers
- Supports multiple revisions
- Automatic HTTPS ingress
- Scale rules based on HTTP traffic, CPU, memory, or custom metrics

**Revisions:**

- Immutable snapshots of your Container App
- Created when you update the container image or configuration
- Support traffic splitting for A/B testing or gradual rollout

### 1.2 Container Apps vs App Service

| Feature | Container Apps | App Service |
|---------|----------------|-------------|
| **Scaling** | Auto-scale to zero | Minimum 1 instance |
| **Revisions** | Built-in revision management | Manual deployment |
| **Pricing** | Pay only for what you use | Pay for allocated plan |
| **Use Case** | Event-driven, microservices | Web apps, APIs |
| **Startup Time** | Cold start possible | Always warm |

---

## Part 2: Deploy Container Apps Infrastructure

### 2.1 Review the Bicep Template

Navigate to the infrastructure folder:

```powershell
cd eng\infrastructure
```

**Review the Container Apps Bicep template:**

```powershell
code main-container-apps.bicep
```

**Key resources created:**

- Resource Group
- Azure Container Registry (ACR)
- Container Apps Environment (managed environment)
- Two Container Apps (Frontend and WebApi)

**Note:** The template creates the apps but doesn't configure container images yet. You'll do that manually.

### 2.2 Deploy the Infrastructure

Run the deployment script:

```powershell
.\deploy.ps1 -DeploymentType ContainerApp
```

**Confirm the deployment:**

```text
Deploying to subscription: <Your Subscription Name>
Deployment Type: ContainerApp
Continue? (yes/no): yes
```

**What happens:**

1. Validates Azure login and tools
2. Deploys the Bicep template
3. Creates Container Apps Environment (~3-4 minutes)
4. Creates Container Apps for WebApi and Frontend

**Expected output:**

```text
Deploying: main-container-apps.bicep
[████████████████████] Deployment in progress...

✓ Deployment completed: workshop-containerapps-20251121-153022
```

**Deployment time:** Approximately 4-6 minutes

### 2.3 Verify Resources in Azure Portal

**Open Azure Portal:**

Navigate to: <https://portal.azure.com>

**Locate your Resource Group:**

1. Search for "Resource groups"
2. Find `rg-cwt01` (or your app identifier)
3. Click to open

**Verify created resources:**

- `crcwt01xxxxxx` - Container Registry
- `cae-cwt01` - Container Apps Environment
- `ca-cwt01-api` - Container App for WebApi
- `ca-cwt01-shop` - Container App for Frontend

---

## Part 3: Configure the WebApi Container App

### 3.1 Navigate to the WebApi Container App

In Azure Portal:

1. Open your resource group (`rg-cwt01`)
2. Click on the Container App named `ca-cwt01-api`

**Initial state:**

- The app is created but not yet running
- No container image is configured
- No ingress is enabled

### 3.2 Configure the Container Image

**Access Containers settings:**

1. In the left menu, go to **Application** → **Containers**
2. You'll see the message about no active revision

**Create a new revision:**

1. Click **Create new revision**
2. Or click **Edit and deploy**

**Configure container details:**

Under **Container image** section:

1. **Image source:** Select `Azure Container Registry`
2. **Registry:** Select your ACR (e.g., `crcwt01xxxxxx`)
3. **Image:** Select `container-workshop/webapi`
4. **Image tag:** Select `1.0`

**Configure container resources (scroll down):**

1. **CPU cores:** 0.25
2. **Memory (Gi):** 0.5

### 3.3 Configure Ingress

**Enable ingress:**

1. Scroll to the top of the page
2. Click on **Ingress** tab
3. **Enabled:** Check the box
4. **Ingress traffic:** Select `Accepting traffic from anywhere`
5. **Ingress type:** `HTTP`
6. **Target port:** `8080` (the port your WebApi listens on)

### 3.4 Create the Revision

**Review and create:**

1. Click **Create** at the bottom
2. Wait for the revision to be created (~1-2 minutes)
3. You'll see "Provisioning" status change to "Running"

**Find the application URL:**

1. Go back to the Container App **Overview** page
2. Find **Application Url** (e.g., `https://ca-cwt01-api.victoriousplant-12345678.westeurope.azurecontainerapps.io`)
3. Copy this URL

### 3.5 Test the WebApi

**Test the pizzas endpoint:**

```powershell
$apiUrl = "<your-container-app-url>"
curl "$apiUrl/pizzas"
```

Expected response:

```json
[
  {"id":1,"name":"Margherita","description":"Classic pizza with tomato sauce, mozzarella, and basil","ingredients":["Tomato Sauce","Mozzarella","Basil","Olive Oil"]},
  {"id":2,"name":"Pepperoni","description":"Spicy pepperoni with mozzarella and tomato sauce","ingredients":["Tomato Sauce","Mozzarella","Pepperoni"]},
  {"id":3,"name":"Quattro Formaggi","description":"Four cheese pizza with mozzarella, gorgonzola, parmesan, and fontina","ingredients":["Mozzarella","Gorgonzola","Parmesan","Fontina"]}
]
```

---

## Part 4: Configure the Frontend Container App

### 4.1 Navigate to the Frontend Container App

In Azure Portal:

1. Go back to your resource group
2. Click on `ca-cwt01-shop`

### 4.2 Configure the Container Image

**Create a new revision:**

1. Go to **Application** → **Containers**
2. Click **Edit and deploy**

**Configure container details:**

1. **Image source:** `Azure Container Registry`
2. **Registry:** Select your ACR
3. **Image:** Select `container-workshop/shop`
4. **Image tag:** `1.0`
5. **CPU cores:** 0.25
6. **Memory (Gi):** 0.5

### 4.3 Configure Environment Variables

The frontend needs the WebApi URL to make API calls.

**Add environment variable:**

1. In the same revision creation screen, click on **Environment variables** tab
2. Click **+ Add**
3. **Name:** `APP_API_BASE_URL`
4. **Source:** Manual entry
5. **Value:** Paste your WebApi Container App URL (e.g., `https://ca-cwt01-api.victoriousplant-12345678.westeurope.azurecontainerapps.io`)

### 4.4 Configure Ingress

**Enable ingress:**

1. Click on the **Ingress** tab
2. **Enabled:** Check the box
3. **Ingress traffic:** `Accepting traffic from anywhere`
4. **Ingress type:** `HTTP`
5. **Target port:** `8080`

### 4.5 Create the Revision and Test

**Create the revision:**

1. Click **Create** at the bottom
2. Wait for provisioning to complete

**Get the Frontend URL:**

1. Go to the Container App **Overview**
2. Copy the **Application Url**

**Test in browser:**

Open the Frontend URL in your web browser. You should see:

- The shopping application UI
- Pizzas loaded from the WebApi
- All functioning correctly

---

## Part 5: Explore Revision Management

### 5.1 View Current Revisions

**Access Revision Management:**

1. In the WebApi Container App (`ca-cwt01-api`)
2. Go to **Application** → **Revision management**

**What you'll see:**

- List of all revisions
- Active revision(s) marked in green
- Revision names (auto-generated with timestamps)
- Traffic percentage for each revision
- Creation time

### 5.2 Understand Revision Modes

Container Apps support two revision modes:

**Single revision mode (default):**

- Only one revision is active at a time
- New deployments replace the previous revision
- Previous revisions are deactivated automatically

**Multiple revision mode:**

- Multiple revisions can be active simultaneously
- Enables traffic splitting between revisions
- Useful for A/B testing, canary deployments, blue-green deployments

---

## Part 6: Make Changes and Create New Revisions

### 6.1 Update the WebApi Code

Let's add a new pizza and deploy a new revision.

**Navigate to WebApi:**

```powershell
cd ..\..\src\WebApi
```

**Edit Program.cs:**

Add a new pizza to the list:

```csharp
new Pizza(
    7,
    "Calzone",
    "Folded pizza with ham, mushrooms, and mozzarella",
    ["Tomato Sauce", "Mozzarella", "Ham", "Mushrooms"]
)
```

### 6.2 Build and Push New Image

**Build version 1.1:**

```powershell
.\build.ps1
```

**Push to ACR:**

```powershell
.\deploy.ps1
```

Wait for the push to complete.

### 6.3 Create a New Revision Manually

**In Azure Portal:**

1. Open the WebApi Container App (`ca-cwt01-api`)
2. Go to **Application** → **Revision management**
3. Click **Create new revision**

**Update container image:**

1. Go to **Container image** section
2. Change **Image tag** from `1.0` to `1.1`
3. Keep other settings the same

**Name the revision (optional):**

1. Scroll to **Revision details** section
2. **Revision suffix:** Enter a meaningful name like `add-calzone`
3. This creates revision name like `ca-cwt01-api--add-calzone`

**Create the revision:**

1. Click **Create** at the bottom
2. Wait for the new revision to be provisioned
3. The old revision is automatically deactivated (single revision mode)

### 6.4 Verify the Update

**Test the API:**

```powershell
$apiUrl = "<your-container-app-url>"
curl "$apiUrl/pizzas"
```

You should now see 7 pizzas including "Calzone".

**Check the Frontend:**

Refresh your frontend browser page. The new pizza should appear in the UI.

---

## Part 7: Traffic Splitting Between Revisions

### 7.1 Enable Multiple Revision Mode

Let's enable multiple revisions to support traffic splitting.

**Switch revision mode:**

1. In the Container App, go to **Application** → **Revision management**
2. Click **Choose revision mode** at the top
3. Select **Multiple: Several revisions active simultaneously**
4. Click **Apply**

### 7.2 Activate Multiple Revisions

**Activate the previous revision:**

1. In the revision list, find your previous revision (version 1.0)
2. Click the **...** (three dots) menu
3. Select **Activate**
4. The revision status changes to "Active"

Now you have two active revisions:

- Original revision (1.0) - 6 pizzas
- New revision (1.1) - 7 pizzas

### 7.3 Configure Traffic Splitting

**Split traffic between revisions:**

1. Still in **Revision management**
2. Look at the **Traffic** column
3. Click **Configure traffic**

**Set traffic percentages:**

1. Assign 50% to revision 1.0
2. Assign 50% to revision 1.1
3. Click **Save**

**What happens:**

- 50% of requests go to the old version (6 pizzas)
- 50% of requests go to the new version (7 pizzas)
- Great for A/B testing or gradual rollout

### 7.4 Test Traffic Splitting

**Make multiple requests:**

```powershell
for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request $i:"
    curl "$apiUrl/pizzas" | ConvertFrom-Json | Select-Object -ExpandProperty id
    Write-Host ""
}
```

You should see some responses with 6 pizzas and some with 7 pizzas.

### 7.5 Complete the Rollout

Once you're confident the new version works:

1. Go to **Revision management**
2. Click **Configure traffic**
3. Assign 100% traffic to revision 1.1
4. Assign 0% to revision 1.0
5. Click **Save**

**Optionally, deactivate old revision:**

1. Find revision 1.0 in the list
2. Click **...** → **Deactivate**
3. This stops the old revision (saves costs)

---

## Part 8: Explore Scaling and Monitoring

### 8.1 View Scaling Configuration

**Access scale settings:**

1. In Container App, go to **Application** → **Scale**
2. View the current scale rule configuration

**Default scale rules:**

- **Min replicas:** Often 0 (scale to zero when idle)
- **Max replicas:** Typically 10
- **Scale rule:** HTTP Concurrent Requests (default threshold: 10)

**What this means:**

- When there are no requests, the app scales to zero
- When requests come in, Container Apps automatically starts instances
- Scales up to 10 instances under heavy load

### 8.2 Test Scale-to-Zero

**Stop making requests:**

1. Wait 5-10 minutes without accessing your Container App
2. Go to **Monitoring** → **Metrics**
3. Select metric: **Replica Count**
4. View the chart - you should see replicas drop to 0

**Wake up from scale-to-zero:**

1. Make a request to your API
2. First request may take 2-5 seconds (cold start)
3. Subsequent requests are fast
4. Check metrics again - replica count increases to 1+

### 8.3 Monitor Application Health

**View application logs:**

1. Go to **Monitoring** → **Log stream**
2. Make requests to your API
3. See logs in real-time

**Query logs with Log Analytics:**

1. Go to **Monitoring** → **Logs**
2. Use Kusto Query Language (KQL) to query logs

**Example query - Recent errors:**

```kql
ContainerAppConsoleLogs_CL
| where ContainerName_s == "ca-cwt01-api"
| where Log_s contains "error"
| order by TimeGenerated desc
| take 50
```

### 8.4 View Application Metrics

**Access metrics:**

1. Go to **Monitoring** → **Metrics**
2. Add charts for:
   - **Replica Count** - Number of running instances
   - **Requests** - HTTP request rate
   - **CPU Usage** - Container CPU utilization
   - **Memory Usage** - Container memory utilization

**Create alerts:**

1. Click **New alert rule**
2. Set condition (e.g., Replica Count = 0 for > 15 minutes)
3. Configure action group (email, webhook)
4. Save the alert

---

## Part 9: Advanced Container Apps Features

### 9.1 Container App Secrets

**Add secrets for sensitive data:**

1. Go to **Settings** → **Secrets**
2. Click **+ Add**
3. **Name:** `database-password`
4. **Value:** Your secret value
5. Click **Add**

**Use secrets in environment variables:**

1. Go to **Application** → **Containers**
2. Click **Edit and deploy**
3. Go to **Environment variables** tab
4. Add variable referencing secret:
   - **Name:** `DB_PASSWORD`
   - **Source:** Reference a secret
   - **Secret:** Select `database-password`

### 9.2 Container Apps Networking

**View network configuration:**

1. Go to **Settings** → **Networking**
2. See ingress configuration
3. View FQDN (Fully Qualified Domain Name)

**Custom domains (optional):**

1. In Networking, click **Custom domains**
2. Add your own domain
3. Configure DNS records
4. Add SSL certificate

### 9.3 Identity and RBAC

**Enable managed identity:**

1. Go to **Settings** → **Identity**
2. **System assigned** tab
3. Toggle **Status** to **On**
4. Click **Save**

**Use identity to access other Azure resources:**

- Azure Container Registry (ACR) without password
- Azure Key Vault for secrets
- Azure Storage, databases, etc.

---

## Part 10: Troubleshooting

### 10.1 Common Issues

#### Issue: Container App not starting

**Symptoms:**

- Revision shows "Provisioning failed"
- Application URL returns 502 error

**Troubleshooting:**

1. Check **Log stream** for container errors
2. Verify the image exists in ACR:

   ```powershell
   az acr repository show-tags --name <your-acr> --repository container-workshop/webapi
   ```

3. Verify ingress target port matches container port
4. Check container resource limits (CPU/memory)

#### Issue: Scale-to-zero not working

**Symptoms:**

- Replica count stays at 1 even when idle

**Solution:**

1. Check scale configuration in **Application** → **Scale**
2. Verify min replicas is set to 0
3. Ensure no active requests are being made
4. Wait sufficient time (5-10 minutes)

#### Issue: Frontend cannot reach API

**Symptoms:**

- Frontend loads but shows no pizzas

**Solution:**

1. Verify `APP_API_BASE_URL` environment variable in frontend
2. Check WebApi ingress is enabled and set to "Anywhere"
3. Test WebApi URL directly in browser
4. Check CORS settings if applicable

### 10.2 View Detailed Logs

**Use Azure CLI to get logs:**

```powershell
# Get console logs
az containerapp logs show --name ca-cwt01-api --resource-group rg-cwt01

# Follow logs in real-time
az containerapp logs show --name ca-cwt01-api --resource-group rg-cwt01 --follow
```

---

## Part 11: Cleanup (Optional)

To remove all Container Apps resources:

```powershell
cd ..\..\eng\infrastructure
.\destroy.ps1
```

Or manually delete the resource group in Azure Portal.

---

## Summary

In this task, you've learned how to:

✅ Deploy Azure Container Apps infrastructure with Bicep  
✅ Manually configure container images from ACR  
✅ Enable ingress and configure networking  
✅ Set environment variables for containers  
✅ Create and manage multiple revisions  
✅ Implement traffic splitting for gradual rollouts  
✅ Understand scale-to-zero and automatic scaling  
✅ Monitor application health and performance  
✅ Use Container Apps secrets and managed identity  

**Key Concepts:**

- **Container Apps:** Serverless container hosting platform
- **Revisions:** Immutable snapshots for version management
- **Traffic Splitting:** Gradual rollout and A/B testing
- **Scale-to-Zero:** Cost optimization by stopping idle containers
- **Managed Identity:** Secure access to Azure resources

**Advantages of Container Apps:**

- Pay only for what you use (scale-to-zero)
- Built-in revision management
- Automatic HTTPS and certificates
- Simple ingress configuration
- Excellent for microservices and event-driven applications

**Next Step:** [Task 4: Deploy to Azure Kubernetes Service (AKS)](04-aks-deployment.md)

In the next task, you'll deploy to Azure Kubernetes Service (AKS) for full control over container orchestration with Kubernetes.
