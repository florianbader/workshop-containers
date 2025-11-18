# Task 2: Deploy to Azure App Service

## Overview

In this task, you'll deploy your containerized applications to Azure App Service using:

- Azure Bicep for infrastructure-as-code deployment
- Azure Container Registry (ACR) for storing container images
- Azure App Service for hosting containers
- Manual configuration of container settings in Azure Portal

**Estimated Time:** 30 minutes

---

## Prerequisites

Before starting, ensure you have completed:

- ✅ Task 1: Local Docker Setup and Container Deployment
- ✅ Docker images built locally
- ✅ Azure CLI installed and logged in

---

## Part 1: Deploy Infrastructure with Bicep

### 1.1 Understand the Infrastructure

Navigate to the infrastructure folder:

```powershell
cd eng\infrastructure
```

**Review the deployment script:**

```powershell
code deploy.ps1
```

**Key observations:**

- The script accepts a `DeploymentType` parameter (AppService, ContainerApp, Kubernetes, or All)
- It uses an app identifier which is added to the resource names. This is later added from the main.bicepparam file.
- It validates Azure login and checks for required tools
- It deploys Bicep templates to create Azure resources

**Review the App Service Bicep template:**

```powershell
code main-app-services.bicep
```

This template creates:

- Resource Group
- Azure Container Registry (ACR)
- App Service Plan (Linux-based)
- Two App Service instances (Frontend and WebApi)

### 1.2 Deploy the App Service Infrastructure

Before deployment, ensure that you change the app identifier in the main.bicepparam file.  
Because Azure resources need a unique name, using the same identifier as others may cause deployment failures.

Run the deployment script:

```powershell
.\deploy.ps1 -DeploymentType AppService
```

**What happens:**

1. The script checks your Azure CLI login status
2. Displays your current subscription
3. Asks for confirmation to proceed
4. Deploys the Bicep template to Azure
5. Creates all necessary resources

**Expected output:**

```text
Deploying to subscription: <Your Subscription Name>
Deployment Type: AppService
Continue? (yes/no): yes

Deploying: main-app-services.bicep
[████████████████████] Deployment in progress...

✓ Deployment completed: workshop-appservices-20251121-143052
```

**Deployment time:** Approximately 3-5 minutes

### 1.3 Verify Resources in Azure Portal

Open the Azure Portal:

```powershell
az portal
```

Or navigate to: <https://portal.azure.com>

**Locate your Resource Group:**

1. Search for "Resource groups" in the top search bar
2. Find the resource group named `rg-cwt01-dev-euw` (or your app identifier)
3. Click to open it

**Verify the created resources:**

- `crcwt01xxxxxx` - Container Registry (ACR)
- `plan-cwt01` - App Service Plan
- `app-cwt01-dev-euw-api` - App Service for WebApi
- `app-cwt01-dev-euw-shop` - App Service for Frontend

---

## Part 2: Push Images to Azure Container Registry

Now that the infrastructure is deployed, let's push your locally built container images to Azure Container Registry (ACR) so they can be used by Azure services.

### 2.1 Prerequisites

Ensure you're logged into Azure:

```powershell
az login
```

Verify your subscription:

```powershell
az account show
```

### 2.2 Push WebApi Image to ACR

Navigate to the WebApi directory:

```powershell
cd ..\..\src\WebApi
```

Push the image to ACR:

```powershell
.\deploy.ps1
```

**What happens:**

- The script finds your Azure Container Registry (starting with "crcwt")
- Logs into ACR using Azure CLI
- Tags your local image with the ACR registry name
- Pushes the image to ACR
- Shows progress and confirmation

**Example output:**

```
Finding Azure Container Registry...
  Found ACR: crcwt01234 (crcwt01234.azurecr.io)

Logging into Azure Container Registry...
  Login successful

Tagging local image for ACR...
  Tagged: crcwt01234.azurecr.io/container-workshop/webapi:1.0

Pushing image to ACR...
  [████████████████████] 100%

✓ Image successfully pushed to ACR
```

### 2.3 Push Frontend Image to ACR

Navigate to the Frontend directory:

```powershell
cd ..\Frontend
```

Push the image:

```powershell
.\deploy.ps1
```

The script performs the same steps as WebApi, pushing the frontend image to ACR.

### 2.4 Verify Images in ACR

**List all repositories in your ACR:**

```powershell
az acr repository list --name <your-acr-name> --output table
```

You should see:

- `container-workshop/webapi`
- `container-workshop/shop`

**View tags for a specific image:**

```powershell
az acr repository show-tags --name <your-acr-name> --repository container-workshop/webapi --output table
```

You should see version `1.0` (and any subsequent versions you build).

---

## Part 3: Configure the WebApi App Service

### 3.1 Navigate to the WebApi App Service

In the Azure Portal:

1. Open your resource group (`rg-cwt01-dev-euw`)
2. Click on the App Service named `app-cwt01-dev-euw-api`

### 3.2 Configure Container Settings

**Access Deployment Center:**

1. In the left menu, scroll down to **Deployment**
2. Click on **Deployment Center**

**Configure the container image:**

1. **Registry source:** Select `Azure Container Registry`
2. **Registry:** Select your ACR (e.g., `crcwt01xxxxxx`)
3. **Image:** Select `container-workshop/webapi`
4. **Tag:** Select `1.0` (or the version you pushed)
5. **Continuous deployment:** Leave as `Off` for now

**Save the configuration:**

- Click **Save** at the top of the page
- Wait for the notification: "Successfully updated container settings"

### 3.3 Verify Deployment

**Monitor the deployment:**

1. In the Deployment Center, view the **Logs** tab
2. Wait for the container to be pulled and started (1-2 minutes)
3. Look for status: "Container started successfully"

**Check Application Logs:**

1. In the left menu, go to **Monitoring** → **Log stream**
2. You should see ASP.NET Core startup messages
3. Look for: `Now listening on: http://[::]:8080`

### 3.4 Test the WebApi

**Get the App Service URL:**

1. In the App Service Overview page, find the **Default domain**
2. It will look like: `https://app-cwt01-dev-euw-api.azurewebsites.net`

**Test the pizzas endpoint:**

Open your browser or use curl:

```powershell
$apiUrl = "https://app-cwt01-dev-euw-api.azurewebsites.net"
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

## Part 4: Configure the Frontend App Service

### 4.1 Navigate to the Frontend App Service

In the Azure Portal:

1. Go back to your resource group (`rg-cwt01-dev-euw`)
2. Click on the App Service named `app-cwt01-dev-euw-shop`

### 4.2 Configure Container Settings

**Access Deployment Center:**

1. In the left menu, go to **Deployment** → **Deployment Center**

**Configure the container image:**

1. **Registry source:** Select `Azure Container Registry`
2. **Registry:** Select your ACR (e.g., `crcwt01xxxxxx`)
3. **Image:** Select `container-workshop/shop`
4. **Tag:** Select `1.0`
5. **Continuous deployment:** Leave as `Off`

**Save the configuration:**

- Click **Save** at the top
- Wait for confirmation

### 4.3 Configure Environment Variables

The frontend needs to know the WebApi URL to call the backend.

**Add Application Settings:**

1. In the left menu, go to **Settings** → **Environment variables**
2. Under **App settings**, click **+ Add**
3. Add the following setting:
   - **Name:** `API_BASE_URL`
   - **Value:** `https://app-cwt01-dev-euw-api.azurewebsites.net`
4. Click **Apply** at the bottom
5. Click **Confirm** when prompted about restarting

### 4.4 Restart the Frontend App Service

After changing environment variables, restart the app:

1. Click **Overview** in the left menu
2. Click **Restart** at the top
3. Click **Yes** to confirm
4. Wait for the restart to complete (~30 seconds)

### 4.5 Test the Frontend Application

**Get the Frontend URL:**

1. In the App Service Overview page, find the **Default domain**
2. It will look like: `https://app-cwt01-dev-euw-shop.azurewebsites.net`

**Open in browser:**

Visit the URL in your web browser.

You should see:

- The shopping application UI
- A list of pizzas loaded from the WebApi
- Pizza cards showing names and descriptions

---

## Part 5: Update Application and Redeploy

### 5.1 Make a Code Change

Let's update the WebApi and deploy a new version.

**Navigate to WebApi project:**

```powershell
cd ..\..\src\WebApi
```

**Edit Program.cs:**

Open `Program.cs` and add a new pizza:

```csharp
new Pizza(
    7,
    "Calzone",
    "Folded pizza with ham, mushrooms, and mozzarella",
    ["Tomato Sauce", "Mozzarella", "Ham", "Mushrooms"]
)
```

### 5.2 Build and Push New Image

**Build the updated image:**

```powershell
.\build.ps1
```

This creates version `1.1` (or increments from your current version).

**Push to ACR:**

```powershell
.\deploy.ps1
```

Wait for the image to be pushed to Azure Container Registry.

### 5.3 Update App Service to Use New Image

**Option 1: Using Azure Portal**

1. Open the WebApi App Service (`app-cwt01-dev-euw-api`)
2. Go to **Deployment** → **Deployment Center**
3. Change the **Tag** from `1.0` to `1.1`
4. Click **Save**
5. Wait for the container to restart

**Option 2: Using Azure CLI**

```powershell
az webapp config container set `
  --name app-cwt01-dev-euw-api `
  --resource-group rg-cwt01 `
  --docker-custom-image-name crcwt01xxxxxx.azurecr.io/container-workshop/webapi:1.1
```

### 5.4 Verify the Update

**Test the updated API:**

```powershell
$apiUrl = "https://app-cwt01-dev-euw-api.azurewebsites.net"
curl "$apiUrl/pizzas"
```

You should now see 7 pizzas including your new "Calzone" item.

**Check the Frontend:**

Open the frontend URL in your browser. The new pizza should appear automatically.

---

## Part 6: Monitoring and Troubleshooting

### 6.1 Common Issues

#### Issue: Container fails to start

**Symptoms:**

- App Service shows "Application Error"
- Log stream shows container exit errors

**Troubleshooting steps:**

1. Check **Deployment Center** → **Logs** for pull errors
2. Verify the image exists in ACR:

   ```powershell
   az acr repository show-tags --name <your-acr-name> --repository container-workshop/webapi
   ```

3. Check container logs in **Log stream**
4. Verify environment variables are set correctly

#### Issue: Frontend cannot connect to API

**Symptoms:**

- Frontend loads but shows no pizzas
- Browser console shows CORS or network errors

**Troubleshooting steps:**

1. Verify `APP_API_BASE_URL` environment variable is set correctly
2. Test the API directly in browser
3. Check WebApi logs for incoming requests
4. Verify both apps are running (not stopped)

#### Issue: App Service shows old version

**Symptoms:**

- Changes don't appear after updating container tag

**Solution:**

1. In App Service, click **Restart**
2. Clear browser cache and refresh
3. Check the actual tag in Deployment Center
4. Verify the new image was pushed to ACR

## Part 7: Cleanup (Optional)

If you want to remove all resources to avoid charges:

### Using the destroy script

```powershell
cd ..\..\eng\infrastructure
.\destroy.ps1
```

Follow the prompts to delete the resource group.

### Manual cleanup

In Azure Portal:

1. Navigate to your resource group (`rg-cwt01-dev-euw`)
2. Click **Delete resource group**
3. Type the resource group name to confirm
4. Click **Delete**

---

## Summary

In this task, you've learned how to:

✅ Deploy infrastructure using Azure Bicep and PowerShell  
✅ Configure App Service to use container images from ACR  
✅ Manually configure container settings in Azure Portal  
✅ Set environment variables for containerized applications  
✅ Monitor and troubleshoot App Service deployments  
✅ Update container images and redeploy new versions  
✅ Scale App Service instances  

**Key Concepts:**

- **Infrastructure as Code:** Using Bicep to define and deploy resources
- **Container Registry:** Centralized storage for container images
- **App Service:** Managed platform for hosting containers
- **Configuration Management:** Environment variables and app settings

**Next Step:** [Task 3: Deploy to Azure Container Apps](03-container-apps-deployment.md)

In the next task, you'll deploy to Azure Container Apps, explore revision management, and learn about serverless container hosting.
