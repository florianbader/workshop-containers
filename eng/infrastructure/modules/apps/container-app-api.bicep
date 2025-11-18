@description('The location for the Container App.')
param location string

@description('The environment name for naming convention.')
param environment string

@description('The application identifier for naming convention.')
param appIdentifier string

@description('The location abbreviation for naming convention.')
param locationAbbr string

@description('The Container App Environment resource ID.')
param containerAppEnvironmentId string

@description('The Container Registry name.')
param containerRegistryName string

module containerApp '../container-app.bicep' = {
  name: '${uniqueString(deployment().name, location)}-container-app-api'
  params: {
    location: location
    environment: environment
    appIdentifier: appIdentifier
    locationAbbr: locationAbbr
    suffix: 'api'
    containerAppEnvironmentId: containerAppEnvironmentId
    containerRegistryName: containerRegistryName
    containerImageName: 'container-workshop/webapi'
    targetPort: 8080
  }
}

output resourceId string = containerApp.outputs.resourceId
output name string = containerApp.outputs.name
output fqdn string = containerApp.outputs.fqdn
