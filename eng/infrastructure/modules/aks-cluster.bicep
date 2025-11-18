@description('The location for the AKS cluster.')
param location string

@description('The environment name for naming convention.')
param environment string

@description('The application identifier for naming convention.')
param appIdentifier string

@description('The location abbreviation for naming convention.')
param locationAbbr string

var name = 'aks-${appIdentifier}-${environment}-${locationAbbr}'

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.11.1' = {
  name: '${uniqueString(deployment().name, location)}-aks'
  params: {
    name: name
    location: location
    skuTier: 'Free'
    managedIdentities: {
      systemAssigned: true
    }
    aadProfile: {
      aadProfileManaged: true
      aadProfileEnableAzureRBAC: true
    }
    disableLocalAccounts: false
    primaryAgentPoolProfiles: [
      {
        name: 'systempool'
        count: 1
        vmSize: 'Standard_D4ds_v5'
        mode: 'System'
      }
    ]
    networkPlugin: 'azure'
    loadBalancerSku: 'standard'
    enableKeyvaultSecretsProvider: true
    azurePolicyEnabled: true
    webApplicationRoutingEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

resource aksClusterResource 'Microsoft.ContainerService/managedClusters@2024-02-01' existing = {
  name: name
  dependsOn: [
    aksCluster
  ]
}

resource clusterAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(name, 'AzureKubernetesServiceClusterAdminRole')
  scope: aksClusterResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8') // Azure Kubernetes Service Cluster Admin Role
    principalId: deployer().objectId
    principalType: 'User'
  }
}

output resourceId string = aksCluster.outputs.resourceId
output name string = aksCluster.outputs.name
output kubeletIdentityObjectId string = aksCluster.outputs.?kubeletIdentityObjectId ?? ''
