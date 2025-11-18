#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the Container Workshop infrastructure to Azure using Bicep.

.DESCRIPTION
    This script deploys the infrastructure defined in main.bicep to the current Azure subscription.
    You can selectively deploy App Services, Container Apps, AKS, or all platforms.
    The application identifier is automatically read from main.bicepparam.

.PARAMETER DeploymentType
    What to deploy: AppService, ContainerApp, Kubernetes, or All. Default: All

.EXAMPLE
    .\deploy.ps1

.EXAMPLE
    .\deploy.ps1 -DeploymentType AppService

.EXAMPLE
    .\deploy.ps1 -DeploymentType Kubernetes
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AppService", "ContainerApp", "Kubernetes", "All")]
    [string]$DeploymentType
)

$ErrorActionPreference = "Stop"

# Import utility functions
. "$PSScriptRoot\..\..\scripts\utils.ps1"

# Check prerequisites
Test-AzureCLI | Out-Null
Test-BicepCLI | Out-Null
$account = Test-AzureLogin

# Get app identifier from Bicep parameters file
$appIdentifier = Get-AppIdentifierFromBicepParam -BicepParamPath "$PSScriptRoot\main.bicepparam"

# Confirm deployment
Write-Host "Deploying to subscription: $($account.name)" -ForegroundColor Cyan
Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Cyan
Write-Host "App Identifier: $appIdentifier" -ForegroundColor Cyan
$confirmation = Read-Host "Continue? (yes/no)"
if ($confirmation -ne "yes" -and $confirmation -ne "y") {
    exit 0
}

# Define deployment function
function Invoke-BicepDeployment {
    param(
        [string]$BicepFile,
        [string]$DeploymentName,
        [string]$AppIdentifier
    )
    
    Write-Host "`nDeploying: $BicepFile" -ForegroundColor Green
    Write-Host "az deployment sub create --name $DeploymentName --location westeurope --template-file $BicepFile --parameters appIdentifier=$AppIdentifier --output none" -ForegroundColor DarkGray
    
    az deployment sub create `
        --name $DeploymentName `
        --location westeurope `
        --template-file $BicepFile `
        --parameters appIdentifier=$AppIdentifier `
        --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Deployment failed for $BicepFile"
        exit 1
    }
    
    Write-Host "✓ Deployment completed: $DeploymentName" -ForegroundColor Green
}

# Deploy based on deployment type
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

switch ($DeploymentType) {
    "AppService" {
        Write-Host "`nDeploying: Resource Group, ACR, App Service Plan, and App Services" -ForegroundColor Cyan
        $bicepFile = Join-Path $PSScriptRoot "main-app-services.bicep"
        $deploymentName = "workshop-appservices-$timestamp"
        Invoke-BicepDeployment -BicepFile $bicepFile -DeploymentName $deploymentName -AppIdentifier $appIdentifier
    }
    "ContainerApp" {
        Write-Host "`nDeploying: Resource Group, ACR, Container App Environment, and Container Apps" -ForegroundColor Cyan
        $bicepFile = Join-Path $PSScriptRoot "main-container-apps.bicep"
        $deploymentName = "workshop-containerapps-$timestamp"
        Invoke-BicepDeployment -BicepFile $bicepFile -DeploymentName $deploymentName -AppIdentifier $appIdentifier
    }
    "Kubernetes" {
        Write-Host "`nDeploying: Resource Group, ACR, and AKS Cluster" -ForegroundColor Cyan
        $bicepFile = Join-Path $PSScriptRoot "main-aks.bicep"
        $deploymentName = "workshop-aks-$timestamp"
        Invoke-BicepDeployment -BicepFile $bicepFile -DeploymentName $deploymentName -AppIdentifier $appIdentifier
    }
    "All" {
        Write-Host "`nDeploying: All platforms (App Services, Container Apps, and AKS) in sequence" -ForegroundColor Cyan
        
        # Deploy App Services first
        Write-Host "`n=== 1/3 App Services ===" -ForegroundColor Yellow
        $bicepFile = Join-Path $PSScriptRoot "main-app-services.bicep"
        $deploymentName = "workshop-appservices-$timestamp"
        Invoke-BicepDeployment -BicepFile $bicepFile -DeploymentName $deploymentName -AppIdentifier $appIdentifier
        
        # Wait for container images to be deployed before continuing
        Write-Host "`nBefore continuing, please build and push the container images:" -ForegroundColor Yellow
        Write-Host "  1. Run: .\src\Frontend\deploy.ps1" -ForegroundColor White
        Write-Host "  2. Run: .\src\WebApi\deploy.ps1" -ForegroundColor White
        $confirmation = Read-Host "`nHave the container images been deployed? (yes/no)"
        if ($confirmation -ne "yes" -and $confirmation -ne "y") {
            Write-Host "Deployment cancelled. Please deploy container images first." -ForegroundColor Red
            exit 0
        }

        # Deploy Container Apps second
        Write-Host "`n=== 2/3 Container Apps ===" -ForegroundColor Yellow
        $bicepFile = Join-Path $PSScriptRoot "main-container-apps.bicep"
        $deploymentName = "workshop-containerapps-$timestamp"
        Invoke-BicepDeployment -BicepFile $bicepFile -DeploymentName $deploymentName -AppIdentifier $appIdentifier
        
        # Deploy AKS third
        Write-Host "`n=== 3/3 AKS ===" -ForegroundColor Yellow
        $bicepFile = Join-Path $PSScriptRoot "main-aks.bicep"
        $deploymentName = "workshop-aks-$timestamp"
        Invoke-BicepDeployment -BicepFile $bicepFile -DeploymentName $deploymentName -AppIdentifier $appIdentifier
        
        Write-Host "`n✓ All deployments completed successfully!" -ForegroundColor Green
    }
}

Write-Host "`nDeployment finished." -ForegroundColor Cyan
