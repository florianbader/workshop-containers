@description('The location for the Container Registry.')
param location string

@description('The environment name for naming convention.')
@minLength(3)
param environment string

@description('The application identifier for naming convention.')
@minLength(3)
param appIdentifier string

@description('The location abbreviation for naming convention.')
@minLength(3)
param locationAbbr string

@description('The SKU of the Container Registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Enable admin user for the Container Registry.')
param adminUserEnabled bool = true

// Generate name: ACR names cannot contain hyphens
var name = 'cr${appIdentifier}${environment}${locationAbbr}'

module containerRegistry 'br/public:avm/res/container-registry/registry:0.9.3' = {
  name: '${uniqueString(deployment().name, location)}-acr'
  params: {
    name: name
    location: location
    acrSku: sku
    acrAdminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
  }
}

output resourceId string = containerRegistry.outputs.resourceId
output loginServer string = containerRegistry.outputs.loginServer
output name string = containerRegistry.outputs.name
