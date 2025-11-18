<#
.SYNOPSIS
    Starts the WebApi Docker container using the most recently built version.

.DESCRIPTION
    This script simplifies running Docker containers for developers who are new to Docker.
    It reads the current version from the .version file and starts a container with that image.
    
    What this script does:
    1. Reads the current version from .version file
    2. Checks if a container named "webapi" already exists
    3. If it exists, stops and removes the old container
    4. Starts a new container with the latest built image
    5. Shows all Docker commands being executed

.NOTES
    Container Name: webapi
    Image Name: webapi:<version>
    
    Make sure you've run build.ps1 at least once before running this script.

.EXAMPLE
    .\start.ps1
    Starts the WebApi container using the most recently built version.
#>

# Import utility functions from separate file
. "$PSScriptRoot\..\..\scripts\utils.ps1"

Write-Host "=== Docker Container Start Script ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$containerName = "container-workshop_webapi"
$hostPort = 5200
$containerPort = 8080
$versionFilePath = Join-Path $PSScriptRoot ".version"

# Get current version
Write-Host "Reading version..." -ForegroundColor Yellow
$version = Get-CurrentVersion -VersionFilePath $versionFilePath

$imageName = "container-workshop/webapi"
$imageTag = "$($imageName):$version"

Write-Host "  Version:               $version"
Write-Host "  Image Tag:             $imageTag"
Write-Host "  Container Name:        $containerName"
Write-Host "  Port Mapping:          $hostPort -> $containerPort"
Write-Host ""

# Check if container already exists (running or stopped)
Write-Host "Checking for existing container..." -ForegroundColor Yellow
$existingContainer = docker ps -a -q -f name=^${containerName}$

if ($existingContainer) {
    Write-Host "  Found existing container: $containerName"
    Write-Host ""
    
    # Stop the container if it's running
    Write-Host "Stopping container..." -ForegroundColor Yellow
    Write-Host "Running: docker stop $containerName" -ForegroundColor Gray
    docker stop $containerName
    Write-Host ""
    
    # Remove the container
    Write-Host "Removing container..." -ForegroundColor Yellow
    Write-Host "Running: docker rm $containerName" -ForegroundColor Gray
    docker rm $containerName
    Write-Host ""
}
else {
    Write-Host "  No existing container found."
    Write-Host ""
}

# Start new container
Write-Host "Starting new container..." -ForegroundColor Yellow
Write-Host "Running: docker run -d --name $containerName -p ${hostPort}:${containerPort} $imageTag" -ForegroundColor Gray
Write-Host ""

docker run -d --name $containerName -p ${hostPort}:${containerPort} $imageTag

# Check if container started successfully
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Container Started Successfully! ===" -ForegroundColor Green
    Write-Host "Container '$containerName' is now running" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access the application at:" -ForegroundColor Cyan
    Write-Host "  http://localhost:$hostPort" -ForegroundColor White
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "  View logs:      docker logs $containerName" -ForegroundColor White
    Write-Host "  Stop container: docker stop $containerName" -ForegroundColor White
    Write-Host "  View status:    docker ps" -ForegroundColor White
}
else {
    Write-Host ""
    Write-Error "Failed to start container. Please check the output above for errors."
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  1. Make sure the image exists: docker images | Select-String 'webapi'" -ForegroundColor White
    Write-Host "  2. Check if port $hostPort is already in use" -ForegroundColor White
    Write-Host "  3. Run build.ps1 first if you haven't built the image yet" -ForegroundColor White
    exit 1
}
