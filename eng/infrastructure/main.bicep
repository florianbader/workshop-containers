targetScope = 'subscription'

metadata name = 'Container Workshop Infrastructure - All Platforms'
metadata description = 'Deploys all Azure Container infrastructure (App Services, Container Apps, and AKS) for workshop.containers'
metadata owner = 'workshop-team'

@description('The location for all resources.')
param location string = 'westeurope'

@description('The environment name for naming convention.')
param environment string = 'dev'

@description('The application identifier for naming convention.')
param appIdentifier string = 'cwt01'

// Deploy all three platforms in sequence
module appServices './main-app-services.bicep' = {
  name: '${uniqueString(deployment().name, location)}-app-services'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
  }
}

module containerApps './main-container-apps.bicep' = {
  name: '${uniqueString(deployment().name, location)}-container-apps'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
  }
}

module aks './main-aks.bicep' = {
  name: '${uniqueString(deployment().name, location)}-aks'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
  }
}

output appServicesDeployed bool = true
output containerAppsDeployed bool = true
output aksDeployed bool = true
output resourceGroupName string = appServices.outputs.resourceGroupName
output containerRegistryLoginServer string = appServices.outputs.containerRegistryLoginServer
output containerRegistryName string = appServices.outputs.containerRegistryName

