@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

@description('Container Registry subnet resource ID')
param registrySubnetId string

@description('Private DNS zone resource ID for Container Registry')
param privateDnsZoneId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${replace(environmentId, '-', '')}acr${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
    }
  }
}

resource registryPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${environmentId}-acr-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: registrySubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${environmentId}-acr-pe-connection'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

resource registryPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: registryPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
output registryId string = containerRegistry.id
output loginServer string = containerRegistry.properties.loginServer
output registryName string = containerRegistry.name