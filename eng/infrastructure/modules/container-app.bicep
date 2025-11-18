@description('The location for the Container App.')
param location string

@description('The environment name for naming convention.')
param environment string

@description('The application identifier for naming convention.')
param appIdentifier string

@description('The location abbreviation for naming convention.')
param locationAbbr string

@description('The suffix for the container app name (e.g., api, shop).')
param suffix string

@description('The Container App Environment resource ID.')
param containerAppEnvironmentId string

@description('The Container Registry name.')
param containerRegistryName string

@description('The container image name (e.g., webapi, shop).')
param containerImageName string

@description('The container image version tag.')
param containerImageVersion string = 'latest'

@description('The target port for ingress.')
param targetPort int

@description('Environment variables for the container.')
param environmentVariables array = []

@description('CPU resources for the container.')
param cpu string = '0.25'

@description('Memory resources for the container.')
param memory string = '0.5Gi'

// Generate name following schema: ca-{app}-{env}-{location}-{suffix}
var name = 'ca-${appIdentifier}-${environment}-${locationAbbr}-${suffix}'
var containerRegistryLoginServer = '${containerRegistryName}.azurecr.io'
var image = '${containerRegistryLoginServer}/${containerImageName}:${containerImageVersion}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

var containerRegistryUsername = containerRegistry.listCredentials().username
var containerRegistryPassword = containerRegistry.listCredentials().passwords[0].value

module containerApp 'br/public:avm/res/app/container-app:0.19.0' = {
  name: '${uniqueString(deployment().name, location)}-container-app-${suffix}'
  params: {
    name: name
    location: location
    environmentResourceId: containerAppEnvironmentId
    workloadProfileName: 'Consumption'
    managedIdentities: {
      systemAssigned: true
    }
    containers: [
      {
        name: suffix
        image: image
        resources: {
          cpu: json(cpu)
          memory: memory
        }
        env: environmentVariables
      }
    ]
    ingressTargetPort: targetPort
    ingressExternal: true
    ingressTransport: 'auto'
    ingressAllowInsecure: false
    scaleSettings: {
      minReplicas: 0
      maxReplicas: 1
    }
    corsPolicy: {
      allowedOrigins: ['*']
      allowedMethods: ['*']
      allowedHeaders: ['*']
    }
    registries: [
      {
        server: containerRegistryLoginServer
        username: containerRegistryUsername
        passwordSecretRef: 'acrpassword'
      }
    ]
    secrets: [
      {
        name: 'acrpassword'
        value: containerRegistryPassword
      }
    ]
  }
}

output resourceId string = containerApp.outputs.resourceId
output name string = containerApp.outputs.name
output fqdn string = containerApp.outputs.fqdn
