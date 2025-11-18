@description('The location for the App Service Plan.')
param location string

@description('The environment name for naming convention.')
param environment string

@description('The application identifier for naming convention.')
param appIdentifier string

@description('The location abbreviation for naming convention.')
param locationAbbr string

@description('The SKU name for the App Service Plan.')
@allowed([
  'F1'
  'D1'
  'B1'
])
param skuName string = 'F1'

// Generate name following schema: asp-{app}-{env}-{location}
var name = 'asp-${appIdentifier}-${environment}-${locationAbbr}'

module appServicePlan 'br/public:avm/res/web/serverfarm:0.5.0' = {
  name: '${uniqueString(deployment().name, location)}-asp'
  params: {
    name: name
    location: location
    skuName: skuName
    kind: 'linux'
    reserved: true
    zoneRedundant: false
    skuCapacity: 1
  }
}

output resourceId string = appServicePlan.outputs.resourceId
output name string = appServicePlan.outputs.name
