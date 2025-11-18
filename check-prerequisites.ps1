#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Checks prerequisites for the Container Workshop.

.DESCRIPTION
    This script verifies that all required tools and configurations are in place:
    - Docker is installed and running
    - Azure CLI is installed
    - User is logged in to Azure
    - Bicep CLI is installed

.EXAMPLE
    .\check-prerequisites.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

# Import utility functions
. "$PSScriptRoot\scripts\utils.ps1"

$allChecksPassed = $true

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Container Workshop - Prerequisites Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "1. Checking Docker..." -NoNewline
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker command failed"
    }
    Write-Host " OK" -ForegroundColor Green
    Write-Host "   $dockerVersion" -ForegroundColor Gray
    
    # Check if Docker daemon is running
    Write-Host "   Checking Docker daemon..." -NoNewline
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host " NOT RUNNING" -ForegroundColor Red
        Write-Host "   Docker is installed but the daemon is not running." -ForegroundColor Yellow
        Write-Host "   Please start Docker Desktop or Docker service." -ForegroundColor Yellow
        $allChecksPassed = $false
    }
    else {
        Write-Host " OK" -ForegroundColor Green
    }
}
catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "   Docker is not installed or not in PATH." -ForegroundColor Yellow
    Write-Host "   Install from: https://docs.docker.com/get-docker/" -ForegroundColor Yellow
    $allChecksPassed = $false
}

Write-Host ""

# Check Azure CLI
Write-Host "2. Checking Azure CLI..." -NoNewline
try {
    $azVersion = Test-AzureCLI
    Write-Host " OK" -ForegroundColor Green
    Write-Host "   Azure CLI version: $azVersion" -ForegroundColor Gray
}
catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "   Azure CLI is not installed or not in PATH." -ForegroundColor Yellow
    Write-Host "   Install from: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    $allChecksPassed = $false
}

Write-Host ""

# Check Azure login
Write-Host "3. Checking Azure login status..." -NoNewline
try {
    $account = Test-AzureLogin
    Write-Host " OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Current Azure Subscription:" -ForegroundColor Cyan
    Write-Host "   Name:          $($account.name)" -ForegroundColor White
    Write-Host "   ID:            $($account.id)" -ForegroundColor White
    Write-Host "   User:          $($account.user.name)" -ForegroundColor White
    Write-Host "   Tenant:        $($account.tenantId)" -ForegroundColor White
    Write-Host "   Environment:   $($account.environmentName)" -ForegroundColor White
}
catch {
    Write-Host " NOT LOGGED IN" -ForegroundColor Red
    Write-Host "   You are not logged in to Azure." -ForegroundColor Yellow
    Write-Host "   Run: az login" -ForegroundColor Yellow
    $allChecksPassed = $false
}

Write-Host ""

# Check Bicep
Write-Host "4. Checking Bicep CLI..." -NoNewline
try {
    $bicepVersion = Test-BicepCLI
    Write-Host " OK" -ForegroundColor Green
    Write-Host "   Bicep version: $bicepVersion" -ForegroundColor Gray
}
catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "   Failed to check Bicep CLI." -ForegroundColor Yellow
    Write-Host "   Run: az bicep install" -ForegroundColor Yellow
    $allChecksPassed = $false
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($allChecksPassed) {
    Write-Host "All prerequisites are met!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}
else {
    Write-Host "Some prerequisites are missing!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please install the missing prerequisites and run this script again." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
