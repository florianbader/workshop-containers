@description('The location for the App Service.')
param location string

@description('The environment name for naming convention.')
param environment string

@description('The application identifier for naming convention.')
param appIdentifier string

@description('The location abbreviation for naming convention.')
param locationAbbr string

@description('The resource ID of the App Service Plan.')
param serverFarmResourceId string

@description('The container registry login server.')
param containerRegistryLoginServer string

@description('The container registry name.')
param containerRegistryName string

@description('The container registry resource ID.')
param containerRegistryResourceId string

@description('The API base URL for the shop frontend.')
param apiBaseUrl string

// Generate name following schema: app-{app}-{env}-{location}-shop
var name = 'app-${appIdentifier}-${environment}-${locationAbbr}-shop'

module appService 'br/public:avm/res/web/site:0.19.4' = {
  name: '${uniqueString(deployment().name, location)}-app-shop'
  params: {
    name: name
    location: location
    kind: 'app,linux,container'
    serverFarmResourceId: serverFarmResourceId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/container-workshop/shop:latest'
      appCommandLine: ''
      alwaysOn: false
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          DOCKER_REGISTRY_SERVER_URL: 'https://${containerRegistryLoginServer}'
          DOCKER_REGISTRY_SERVER_USERNAME: containerRegistryName
          DOCKER_REGISTRY_SERVER_PASSWORD: listCredentials(containerRegistryResourceId, '2023-07-01').passwords[0].value
          WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
          WEBSITES_PORT: '8080'
          APP_API_BASE_URL: apiBaseUrl
        }
      }
    ]
  }
}

output resourceId string = appService.outputs.resourceId
output defaultHostname string = appService.outputs.defaultHostname
output name string = appService.outputs.name
