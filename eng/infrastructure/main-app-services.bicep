targetScope = 'subscription'

metadata name = 'App Services Deployment'
metadata description = 'Deploys Resource Group, Azure Container Registry, App Service Plan, and App Services'

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

module appServicePlan './modules/app-service-plan.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-asp'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
  }
}

module appServiceApi './modules/apps/app-service-api.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-app-api'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
    serverFarmResourceId: appServicePlan.outputs.resourceId
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerRegistryName: containerRegistry.outputs.name
    containerRegistryResourceId: containerRegistry.outputs.resourceId
  }
}

module appServiceShop './modules/apps/app-service-shop.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-app-shop'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
    serverFarmResourceId: appServicePlan.outputs.resourceId
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerRegistryName: containerRegistry.outputs.name
    containerRegistryResourceId: containerRegistry.outputs.resourceId
    apiBaseUrl: 'https://${appServiceApi.outputs.defaultHostname}'
  }
}

output resourceGroupName string = resourceGroup.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryName string = containerRegistry.outputs.name
output appServiceApiUrl string = 'https://${appServiceApi.outputs.defaultHostname}'
output appServiceShopUrl string = 'https://${appServiceShop.outputs.defaultHostname}'
