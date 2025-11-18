# Deploy to AKS
# This script deploys the application to Azure Kubernetes Service
# Resource names are automatically constructed from the app identifier in main.bicepparam

param()

$ErrorActionPreference = "Stop"

# Import utility functions
. "$PSScriptRoot\..\..\scripts\utils.ps1"

# Get app identifier from Bicep parameters file and construct resource names
$appIdentifier = Get-AppIdentifierFromBicepParam
$ResourceGroup = "rg-$appIdentifier-dev-weu"
$AksClusterName = "aks-$appIdentifier-dev-weu"
$AcrName = "cr$appIdentifier" + "devweu"

Write-Host "Using resources:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "  AKS Cluster: $AksClusterName" -ForegroundColor Gray
Write-Host "  ACR Name: $AcrName" -ForegroundColor Gray
Write-Host ""

# Check if kubectl and kubelogin are available
$kubectlExists = Get-Command kubectl -ErrorAction SilentlyContinue
$kubeloginExists = Get-Command kubelogin -ErrorAction SilentlyContinue

if (-not $kubectlExists -or -not $kubeloginExists) {
    Write-Host "Installing kubectl and kubelogin..." -ForegroundColor Cyan
    az aks install-cli
} else {
    Write-Host "kubectl and kubelogin are already installed." -ForegroundColor Green
}

Write-Host "Getting AKS credentials..." -ForegroundColor Cyan
az aks get-credentials --resource-group $ResourceGroup --name $AksClusterName --overwrite-existing --admin

Write-Host "`nGetting ACR login server..." -ForegroundColor Cyan
$acrLoginServer = az acr show --name $AcrName --query loginServer -o tsv

Write-Host "`nApplying Kubernetes manifests..." -ForegroundColor Cyan
Write-Host "ACR Login Server: $acrLoginServer" -ForegroundColor Gray
Write-Host ""

# Apply Ingress first
kubectl apply -f "$PSScriptRoot\ingress.yaml"

Write-Host "`nWaiting for ingress to get an external IP..." -ForegroundColor Cyan
$ingressIp = ""
$maxAttempts = 30
$attempt = 0
while ([string]::IsNullOrEmpty($ingressIp) -and $attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 2
    $ingressIp = kubectl get ingress workshop-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    $attempt++
    Write-Host "." -NoNewline -ForegroundColor Gray
}
Write-Host ""

if ([string]::IsNullOrEmpty($ingressIp)) {
    Write-Host "Warning: Could not get ingress IP. Using placeholder." -ForegroundColor Yellow
    $ingressIp = "PENDING"
} else {
    Write-Host "Ingress IP: $ingressIp" -ForegroundColor Green
}

# Apply API deployment
$apiManifest = Get-Content "$PSScriptRoot\api-deployment.yaml" -Raw
$apiManifest = $apiManifest -replace '\$\{ACR_LOGIN_SERVER\}', $acrLoginServer
$apiManifest | kubectl apply -f -

# Apply Frontend deployment with ingress IP
$frontendManifest = Get-Content "$PSScriptRoot\frontend-deployment.yaml" -Raw
$frontendManifest = $frontendManifest -replace '\$\{ACR_LOGIN_SERVER\}', $acrLoginServer
$frontendManifest = $frontendManifest -replace '\$\{INGRESS_IP\}', $ingressIp
$frontendManifest | kubectl apply -f -

Write-Host "`nDeployment complete!" -ForegroundColor Green
Write-Host "`nApplication URLs:" -ForegroundColor Cyan
Write-Host "Frontend: http://$ingressIp" -ForegroundColor Yellow
Write-Host "API: http://$ingressIp/api" -ForegroundColor Yellow

Write-Host "`nChecking pod status..." -ForegroundColor Cyan
kubectl get pods
