<#
.SYNOPSIS
    Builds a Docker image for the Frontend application with automatic version tagging.

.DESCRIPTION
    This script simplifies Docker image building for developers who are new to Docker.
    It automatically manages version numbers and builds the Docker image with proper tags.
    
    What this script does:
    1. Manages version numbers automatically (starts at 1.0, increments minor version each build)
    2. Builds a Docker image using the Dockerfile in the current directory
    3. Tags the image as "shop:<version>" (e.g., shop:1.0, shop:1.1)
    4. Shows all relevant information about what was built

.NOTES
    Docker Context: The workspace root directory
    Dockerfile: Uses the Dockerfile in the src/Frontend directory
    Version File: .version (automatically created and managed)

.EXAMPLE
    .\build.ps1
    Builds the Docker image with an automatically incremented version tag.
#>

# Import utility functions from separate file
. "$PSScriptRoot\..\..\scripts\utils.ps1"

Write-Host "=== Docker Image Build Script (Frontend) ===" -ForegroundColor Cyan
Write-Host ""

# Get script directory (this is the Docker context)
$projectDirectory = $PSScriptRoot
$dockerContext = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$dockerfilePath = Join-Path $projectDirectory "Dockerfile"
$versionFilePath = Join-Path $projectDirectory ".version"

# Display Docker build configuration
Write-Host "Docker Build Configuration:" -ForegroundColor Yellow
Write-Host "  Docker Context Folder: $dockerContext"
Write-Host "  Dockerfile Used:       $dockerfilePath"
Write-Host ""

# Get and increment version
Write-Host "Managing version..." -ForegroundColor Yellow
$version = Get-AndIncrementVersion -VersionFilePath $versionFilePath

$imageName = "container-workshop/shop"
$imageTag = "$($imageName):$version"

Write-Host "  Version:               $version"
Write-Host "  Image Tag:             $imageTag"
Write-Host ""

# Verify Dockerfile exists
if (-not (Test-Path $dockerfilePath)) {
    Write-Error "Dockerfile not found at: $dockerfilePath"
    exit 1
}

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
Write-Host "Running: docker build -f $dockerfilePath -t $imageTag $dockerContext"
Write-Host ""

docker build -f $dockerfilePath -t $imageTag --progress=plain $dockerContext

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build Successful! ===" -ForegroundColor Green
    Write-Host "Image created: $imageTag" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the container, use:" -ForegroundColor Cyan
    Write-Host "  ./start.ps1" -ForegroundColor White
}
else {
    Write-Host ""
    Write-Error "Docker build failed. Please check the output above for errors."
    exit 1
}
