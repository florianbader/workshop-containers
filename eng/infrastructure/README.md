# Infrastructure as Code

This directory contains Bicep templates and PowerShell scripts for deploying the workshop infrastructure to Azure.

## Structure

```text
infrastructure/
├── main.bicep                      # Main infrastructure template (all resources)
├── main-app-services.bicep         # App Service specific deployment
├── main-container-apps.bicep       # Container Apps specific deployment
├── main-aks.bicep                  # AKS specific deployment
├── main.bicepparam                 # Parameters file
├── deploy.ps1                      # Deployment script
├── destroy.ps1                     # Clean-up script
└── modules/                        # Reusable Bicep modules
    ├── acr-role-assignment.bicep   # ACR role assignments
    ├── aks-cluster.bicep            # AKS cluster configuration
    ├── app-service-plan.bicep       # App Service plan
    ├── app-service.bicep            # App Service web apps
    ├── container-app-environment.bicep # Container Apps environment
    ├── container-app.bicep          # Container App definitions
    ├── container-registry.bicep     # Azure Container Registry
    └── apps/                        # Application-specific modules
        ├── app-service-api.bicep    # API on App Service
        ├── app-service-shop.bicep   # Frontend on App Service
        ├── container-app-api.bicep  # API on Container Apps
        └── container-app-frontend.bicep # Frontend on Container Apps
```

## Deploy Script (`deploy.ps1`)

Deploys infrastructure to Azure using Bicep templates. The application identifier is automatically read from `main.bicepparam`.

**Usage:**

```powershell
.\deploy.ps1 -DeploymentType <Type>
```

**Parameters:**

- `-DeploymentType`: Required. Choose from:
  - `AppService` - Deploy App Service infrastructure only
  - `ContainerApp` - Deploy Container Apps infrastructure only
  - `Kubernetes` - Deploy AKS infrastructure only
  - `All` - Deploy all platforms

**Examples:**

```powershell
# Deploy only App Service infrastructure
.\deploy.ps1 -DeploymentType AppService

# Deploy AKS infrastructure
.\deploy.ps1 -DeploymentType Kubernetes

# Deploy all platforms
.\deploy.ps1 -DeploymentType All
```

**What it does:**

1. Reads the app identifier from `main.bicepparam`
2. Validates Azure CLI and Bicep installation
3. Checks Azure login status
4. Deploys selected Bicep template with the app identifier
5. Outputs resource names and connection information

**Resources Created:**

- Resource Group: `rg-<identifier>-dev-weu`
- Container Registry: `cr<identifier>devweu`
- App Service Plan (if selected): `asp-<identifier>-dev-weu`
- App Services (if selected): API and Shop web apps
- Container Apps Environment (if selected): `cae-<identifier>-dev-weu`
- Container Apps (if selected): API and Frontend apps
- AKS Cluster (if selected): `aks-<identifier>-dev-weu`

**Customizing the App Identifier:**

To change the app identifier (and thus all resource names), edit the `appIdentifier` parameter in `main.bicepparam`:

```bicep
param appIdentifier = 'cwt01'  // Change 'cwt01' to your desired identifier
```

## Destroy Script (`destroy.ps1`)

Removes all Azure resources to avoid ongoing charges. The resource group name is automatically determined from the app identifier in `main.bicepparam`.

**Usage:**

```powershell
.\destroy.ps1
```

**Examples:**

```powershell
# Destroy all resources
.\destroy.ps1
```

**What it does:**

1. Reads the app identifier from `main.bicepparam`
2. Constructs the resource group name
3. Validates Azure CLI installation
4. Checks Azure login status
5. Verifies resource group exists
6. Prompts for confirmation (type 'DELETE' to confirm)
7. Deletes the entire resource group and all contained resources

**⚠️ Warning:** This operation is **irreversible**. All resources in the resource group will be permanently deleted.

## Bicep Templates

### Main Templates

- **`main.bicep`** - Comprehensive template that deploys all infrastructure
- **`main-app-services.bicep`** - App Service infrastructure only
- **`main-container-apps.bicep`** - Container Apps infrastructure only
- **`main-aks.bicep`** - AKS infrastructure only

### Modules

Reusable Bicep modules for individual Azure resources. These are referenced by the main templates to promote code reuse and maintainability.

## Prerequisites

- Azure CLI (`az`)
- Bicep CLI (installed via Azure CLI)
- Active Azure subscription
- Appropriate permissions to create resources

## Region

All resources are deployed to **West Europe** (`westeurope`) by default. Modify the templates to change the region.
