targetScope = 'subscription'

metadata name = 'Container Apps Deployment'
metadata description = 'Deploys Resource Group, Azure Container Registry, Container App Environment, and Container Apps'

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

module containerAppEnvironment './modules/container-app-environment.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-cae'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
  }
}

module containerAppApi './modules/apps/container-app-api.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-ca-api'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
    containerAppEnvironmentId: containerAppEnvironment.outputs.resourceId
    containerRegistryName: containerRegistry.outputs.name
  }
}

module containerAppFrontend './modules/apps/container-app-frontend.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-ca-frontend'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
    containerAppEnvironmentId: containerAppEnvironment.outputs.resourceId
    containerRegistryName: containerRegistry.outputs.name
    apiBaseUrl: 'https://${containerAppApi.outputs.fqdn}'
  }
}

output resourceGroupName string = resourceGroup.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryName string = containerRegistry.outputs.name
output containerAppApiUrl string = 'https://${containerAppApi.outputs.fqdn}'
output containerAppFrontendUrl string = 'https://${containerAppFrontend.outputs.fqdn}'
