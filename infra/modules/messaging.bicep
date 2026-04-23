@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

@description('Virtual Network resource ID')
param vnetId string

@description('Service Bus subnet resource ID')
param serviceBusSubnetId string

@description('Key Vault resource ID for storing connection string')
param keyVaultId string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: '${environmentId}-sb'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2024-01-01' = {
  parent: serviceBusNamespace
  name: 'mailqueue'
  properties: {
    maxSizeInMegabytes: 1024
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

resource serviceBusPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${environmentId}-sb-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: serviceBusSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${environmentId}-sb-pe-connection'
        properties: {
          privateLinkServiceId: serviceBusNamespace.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

// Store connection string in Key Vault
resource serviceBusConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/servicebus-connection-string'
  properties: {
    value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespace.name, 'RootManageSharedAccessKey'), '2024-01-01').primaryConnectionString
  }
}

// Outputs
output serviceBusId string = serviceBusNamespace.id
output namespaceName string = serviceBusNamespace.name
output queueName string = serviceBusQueue.name