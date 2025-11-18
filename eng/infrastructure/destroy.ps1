#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Destroys the Container Workshop infrastructure in Azure.

.DESCRIPTION
    This script deletes the resource group and all contained resources.
    The application identifier is automatically read from main.bicepparam.

.EXAMPLE
    .\destroy.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Import utility functions
. "$PSScriptRoot\..\..\scripts\utils.ps1"

# Get app identifier from Bicep parameters file
$appIdentifier = Get-AppIdentifierFromBicepParam -BicepParamPath "$PSScriptRoot\main.bicepparam"
$resourceGroupName = "rg-$appIdentifier-dev-weu"

# Check prerequisites
$azVersion = Test-AzureCLI
$account = Test-AzureLogin

# Check if resource group exists
try {
    $rg = az group show --name $resourceGroupName --output json 2>$null | ConvertFrom-Json
    if ($null -eq $rg) {
        Write-Warning "Resource group '$resourceGroupName' does not exist."
        exit 0
    }
}
catch {
    Write-Warning "Resource group '$resourceGroupName' does not exist."
    exit 0
}

# Confirm deletion
Write-Host "Resource group: $resourceGroupName" -ForegroundColor Cyan
Write-Host "Subscription:   $($account.name)" -ForegroundColor Cyan
Write-Host ""
Write-Warning "This will permanently delete all resources in the resource group!"
$confirmation = Read-Host "Type 'DELETE' to confirm"
if ($confirmation -ne "DELETE") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Delete resource group
Write-Host "Deleting resource group..." -ForegroundColor Yellow

Write-Host "az group delete --name $resourceGroupName --yes --no-wait" -ForegroundColor DarkGray

az group delete `
    --name $resourceGroupName `
    --yes `
    --no-wait

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to delete resource group"
    exit 1
}

Write-Host "Deletion initiated. Resources will be removed in the background." -ForegroundColor Green
