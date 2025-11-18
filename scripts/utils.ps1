<#
.SYNOPSIS
    Utility functions for version management, Azure CLI operations, and other shared tasks.

.DESCRIPTION
    This script contains helper functions used by various scripts to keep them
    simple and focused on their main operations.
#>

<#
.SYNOPSIS
    Gets the current version and increments the minor version.

.DESCRIPTION
    Reads the .version file from the script's directory. If the file doesn't exist,
    creates it with version 1.0. If it exists, increments the minor version.

.PARAMETER VersionFilePath
    The full path to the .version file.

.OUTPUTS
    Returns the new version string (e.g., "1.0", "1.1", "1.2").

.EXAMPLE
    $version = Get-AndIncrementVersion -VersionFilePath "C:\path\to\.version"
#>
function Get-AndIncrementVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VersionFilePath
    )

    # Default version if file doesn't exist
    $defaultMajor = 1
    $defaultMinor = 0

    if (Test-Path $VersionFilePath) {
        # Read existing version
        $currentVersion = Get-Content $VersionFilePath -Raw
        $currentVersion = $currentVersion.Trim()

        # Parse version (expected format: major.minor)
        if ($currentVersion -match '^(\d+)\.(\d+)$') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            
            # Increment minor version
            $minor++
            $newVersion = "$major.$minor"
        }
        else {
            Write-Warning "Invalid version format in .version file. Using default version."
            $newVersion = "$defaultMajor.$defaultMinor"
        }
    }
    else {
        # File doesn't exist, use default
        $newVersion = "$defaultMajor.$defaultMinor"
    }

    # Write new version to file
    Set-Content -Path $VersionFilePath -Value $newVersion -NoNewline

    return $newVersion
}

<#
.SYNOPSIS
    Gets the current version without incrementing it.

.DESCRIPTION
    Reads the .version file from the specified path. If the file doesn't exist,
    returns the default version "1.0".

.PARAMETER VersionFilePath
    The full path to the .version file.

.OUTPUTS
    Returns the current version string (e.g., "1.0", "1.1", "1.2").

.EXAMPLE
    $version = Get-CurrentVersion -VersionFilePath "C:\path\to\.version"
#>
function Get-CurrentVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VersionFilePath
    )

    # Default version if file doesn't exist
    $defaultVersion = "1.0"

    if (Test-Path $VersionFilePath) {
        # Read existing version
        $currentVersion = Get-Content $VersionFilePath -Raw
        $currentVersion = $currentVersion.Trim()

        # Validate version format (expected format: major.minor)
        if ($currentVersion -match '^\d+\.\d+$') {
            return $currentVersion
        }
        else {
            Write-Warning "Invalid version format in .version file. Using default version."
            return $defaultVersion
        }
    }
    else {
        Write-Warning ".version file not found. Have you run build.ps1 yet? Using default version."
        return $defaultVersion
    }
}

<#
.SYNOPSIS
    Checks if Azure CLI is installed.

.DESCRIPTION
    Verifies that Azure CLI is installed and available in the PATH.
    Returns the Azure CLI version if successful, otherwise exits with error.

.OUTPUTS
    Returns the Azure CLI version string.

.EXAMPLE
    $azVersion = Test-AzureCLI
#>
function Test-AzureCLI {
    try {
        $azVersionInfo = az version 2>$null | ConvertFrom-Json
        $azVersion = $azVersionInfo.'azure-cli'
        if (-not $azVersion) {
            Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli"
            exit 1
        }
        return $azVersion
    }
    catch {
        Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    }
}

<#
.SYNOPSIS
    Checks if user is logged into Azure and returns account information.

.DESCRIPTION
    Verifies that the user is logged into Azure CLI and returns the account details.
    If not logged in, exits with an error message.

.OUTPUTS
    Returns the Azure account object with subscription details.

.EXAMPLE
    $account = Test-AzureLogin
    Write-Host "Logged into: $($account.name)"
#>
function Test-AzureLogin {
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Error "Not logged into Azure. Please run 'az login' first."
        exit 1
    }
    return $account
}

<#
.SYNOPSIS
    Checks if Bicep CLI is installed.

.DESCRIPTION
    Verifies that Bicep CLI is installed. If not, attempts to install it automatically.
    Returns the Bicep version if successful, otherwise exits with error.

.OUTPUTS
    Returns the Bicep version string.

.EXAMPLE
    $bicepVersion = Test-BicepCLI
#>
function Test-BicepCLI {
    try {
        $bicepVersion = az bicep version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Bicep CLI not found. Installing..." -ForegroundColor Yellow
            az bicep install
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install Bicep CLI"
            }
            $bicepVersion = az bicep version 2>$null
        }
        return $bicepVersion
    }
    catch {
        Write-Error "Failed to install Bicep CLI. Run manually: az bicep install"
        exit 1
    }
}

<#
.SYNOPSIS
    Gets the application identifier from the Bicep parameters file.

.DESCRIPTION
    Reads the main.bicepparam file and extracts the appIdentifier parameter value using regex.
    If the file doesn't exist or the parameter is not found, returns the default value "cwt01".

.PARAMETER BicepParamPath
    The full path to the main.bicepparam file. If not provided, uses the default location
    relative to the scripts directory.

.OUTPUTS
    Returns the application identifier string (e.g., "cwt01", "myapp").

.EXAMPLE
    $appId = Get-AppIdentifierFromBicepParam
    Write-Host "App Identifier: $appId"

.EXAMPLE
    $appId = Get-AppIdentifierFromBicepParam -BicepParamPath "C:\path\to\main.bicepparam"
#>
function Get-AppIdentifierFromBicepParam {
    param(
        [Parameter(Mandatory = $false)]
        [string]$BicepParamPath
    )

    # Default to the standard location if not provided
    if ([string]::IsNullOrEmpty($BicepParamPath)) {
        $BicepParamPath = Join-Path $PSScriptRoot "..\eng\infrastructure\main.bicepparam"
    }

    # Default app identifier
    $defaultAppIdentifier = "cwt01"

    if (-not (Test-Path $BicepParamPath)) {
        Write-Warning "Bicep parameters file not found at: $BicepParamPath. Using default app identifier: $defaultAppIdentifier"
        return $defaultAppIdentifier
    }

    try {
        # Read the file content
        $content = Get-Content $BicepParamPath -Raw
        
        # Use regex to extract the appIdentifier parameter value
        # Matches patterns like: param appIdentifier = 'cwt01' or param appIdentifier = "cwt01"
        if ($content -match "param\s+appIdentifier\s*=\s*['""]([^'""]+)['""]") {
            $appIdentifier = $Matches[1]
            return $appIdentifier
        }
        else {
            Write-Warning "Could not find 'appIdentifier' parameter in $BicepParamPath. Using default: $defaultAppIdentifier"
            return $defaultAppIdentifier
        }
    }
    catch {
        Write-Warning "Error reading Bicep parameters file: $_. Using default app identifier: $defaultAppIdentifier"
        return $defaultAppIdentifier
    }
}

<#
.SYNOPSIS
    Finds an Azure Container Registry by name prefix.

.DESCRIPTION
    Searches for Azure Container Registries in the current subscription that start
    with the specified prefix. Returns the first matching registry.

.PARAMETER NamePrefix
    The prefix to search for (e.g., "crcwt").

.OUTPUTS
    Returns an object with 'name' and 'loginServer' properties.

.EXAMPLE
    $acr = Get-AzureContainerRegistry -NamePrefix "crcwt"
    Write-Host "Found ACR: $($acr.name)"
#>
function Get-AzureContainerRegistry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NamePrefix
    )

    $registries = az acr list --query "[?starts_with(name, '$NamePrefix')].{name:name, loginServer:loginServer}" | ConvertFrom-Json

    if (-not $registries -or $registries.Count -eq 0) {
        Write-Error "No Azure Container Registry found starting with '$NamePrefix' in current subscription. Make sure the infrastructure is deployed."
        exit 1
    }

    # Return the first registry
    $acr = $registries[0]
    
    if ($registries.Count -gt 1) {
        Write-Host "  Note: Multiple ACRs found, using the first one: $($acr.name)" -ForegroundColor Yellow
    }

    return $acr
}
