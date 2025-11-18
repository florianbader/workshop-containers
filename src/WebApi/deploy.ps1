<#
.SYNOPSIS
    Deploys the WebApi Docker image to Azure Container Registry.

.DESCRIPTION
    This script deploys the locally built WebApi Docker image to Azure Container Registry (ACR).
    It automatically:
    1. Gets the app identifier from main.bicepparam and constructs the ACR name
    2. Logs into the ACR using Azure CLI
    3. Tags the local image with the ACR registry name
    4. Pushes the image to ACR
    
    The script uses the current version from the .version file to identify which local image to push.

.NOTES
    Prerequisites:
    - Azure CLI must be installed
    - You must be logged into Azure (az login)
    - The Docker image must be built locally first (run .\build.ps1)

.EXAMPLE
    .\deploy.ps1
    Deploys the current version of the WebApi image to ACR.
#>

# Import utility functions
. "$PSScriptRoot\..\..\scripts\utils.ps1"

Write-Host "=== Azure Container Registry Deployment Script (WebApi) ===" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$azVersion = Test-AzureCLI
Write-Host "  Azure CLI version: $azVersion" -ForegroundColor Green

Write-Host "  Checking Azure login status..." -ForegroundColor Yellow
$account = Test-AzureLogin
$subscriptionName = $account.name
$subscriptionId = $account.id
Write-Host "  Logged into Azure" -ForegroundColor Green
Write-Host "  Subscription: $subscriptionName ($subscriptionId)" -ForegroundColor Cyan
Write-Host ""

# Get app identifier and construct ACR name
Write-Host "Getting Azure Container Registry..." -ForegroundColor Yellow
$appIdentifier = Get-AppIdentifierFromBicepParam
$acrNamePrefix = "cr$appIdentifier"
$acr = Get-AzureContainerRegistry -NamePrefix $acrNamePrefix
$acrName = $acr.name
$acrLoginServer = $acr.loginServer

Write-Host "  Found ACR: $acrName" -ForegroundColor Green
Write-Host "  Login Server: $acrLoginServer" -ForegroundColor Cyan
Write-Host ""

# Get current version
$versionFilePath = Join-Path $PSScriptRoot ".version"
$version = Get-CurrentVersion -VersionFilePath $versionFilePath

if (-not $version) {
    Write-Error "Could not determine version. Please run .\build.ps1 first to build the image."
    exit 1
}

$localImageName = "container-workshop/webapi"
$localImageTag = "${localImageName}:${version}"
$acrImageTag = "${acrLoginServer}/${localImageName}:${version}"
$acrLatestTag = "${acrLoginServer}/${localImageName}:latest"

Write-Host "Image Information:" -ForegroundColor Yellow
Write-Host "  Local Image:  $localImageTag"
Write-Host "  ACR Image:    $acrImageTag"
Write-Host "  ACR Latest:   $acrLatestTag"
Write-Host "  Version:      $version"
Write-Host ""

# Check if local image exists
Write-Host "Verifying local image exists..." -ForegroundColor Yellow
$imageExists = docker images -q $localImageTag
if (-not $imageExists) {
    Write-Error "Local image '$localImageTag' not found. Please run .\build.ps1 first to build the image."
    exit 1
}
Write-Host "  Local image found" -ForegroundColor Green
Write-Host ""

# Login to ACR
Write-Host "Logging into Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $acrName 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to login to Azure Container Registry '$acrName'"
    exit 1
}
Write-Host "  Successfully logged into ACR" -ForegroundColor Green
Write-Host ""

# Tag the image for ACR
Write-Host "Tagging image for ACR..." -ForegroundColor Yellow
Write-Host "  Running: docker tag $localImageTag $acrImageTag"
docker tag $localImageTag $acrImageTag
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to tag image with version"
    exit 1
}

Write-Host "  Running: docker tag $localImageTag $acrLatestTag"
docker tag $localImageTag $acrLatestTag
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to tag image with latest"
    exit 1
}
Write-Host "  Images tagged successfully" -ForegroundColor Green
Write-Host ""

# Push the version-tagged image to ACR
Write-Host "Pushing version-tagged image to Azure Container Registry..." -ForegroundColor Yellow
Write-Host "  Pushing: $acrImageTag"
docker push $acrImageTag
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push version-tagged image to ACR"
    exit 1
}
Write-Host "  Version-tagged image pushed successfully" -ForegroundColor Green
Write-Host ""

# Push the latest-tagged image to ACR
Write-Host "Pushing latest-tagged image to Azure Container Registry..." -ForegroundColor Yellow
Write-Host "  Pushing: $acrLatestTag"
docker push $acrLatestTag
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push latest-tagged image to ACR"
    exit 1
}
Write-Host "  Latest-tagged image pushed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "=== Deployment Successful! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Subscription:     $subscriptionName" -ForegroundColor White
Write-Host "  ACR Name:         $acrName" -ForegroundColor White
Write-Host "  ACR Login Server: $acrLoginServer" -ForegroundColor White
Write-Host "  Images Pushed:" -ForegroundColor White
Write-Host "    - $acrImageTag" -ForegroundColor White
Write-Host "    - $acrLatestTag" -ForegroundColor White
Write-Host "  Version:          $version" -ForegroundColor White
Write-Host ""
