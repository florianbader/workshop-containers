targetScope = 'subscription'

metadata name = 'AKS Deployment'
metadata description = 'Deploys Resource Group, Azure Container Registry, and Azure Kubernetes Service'

@description('The location for all resources.')
param location string = 'westeurope'

@description('The environment name for naming convention.')
param environment string = 'dev'

@description('The application identifier for naming convention.')
param appIdentifier string = 'cwt01'

var locationAbbr = 'weu'
var resourceGroupName = 'rg-${appIdentifier}-${environment}-${locationAbbr}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module containerRegistry './modules/container-registry.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-acr'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
  }
}

module aksCluster './modules/aks-cluster.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-aks'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
  }
}

// Grant AKS pull access to ACR
module acrRoleAssignment './modules/acr-role-assignment.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-acr-role'
  params: {
    containerRegistryName: containerRegistry.outputs.name
    kubeletIdentityObjectId: aksCluster.outputs.kubeletIdentityObjectId
  }
}

output resourceGroupName string = resourceGroup.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryName string = containerRegistry.outputs.name
output aksClusterName string = aksCluster.outputs.name
