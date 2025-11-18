@description('The location for the Container App Environment.')
param location string

@description('The environment name for naming convention.')
param environment string

@description('The application identifier for naming convention.')
param appIdentifier string

@description('The location abbreviation for naming convention.')
param locationAbbr string

var name = 'cae-${appIdentifier}-${environment}-${locationAbbr}'

module containerAppEnvironment 'br/public:avm/res/app/managed-environment:0.11.3' = {
  name: '${uniqueString(deployment().name, location)}-managed-env'
  params: {
    name: name
    location: location
    publicNetworkAccess: 'Enabled'
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
  }
}

output resourceId string = containerAppEnvironment.outputs.resourceId
output name string = containerAppEnvironment.outputs.name
output defaultDomain string = containerAppEnvironment.outputs.defaultDomain
