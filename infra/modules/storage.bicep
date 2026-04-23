@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

@description('Virtual Network resource ID')
param vnetId string

@description('Storage subnet resource ID')
param storageSubnetId string

@description('Private DNS zone resource ID for Storage')
param privateDnsZoneId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${environmentId}st${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: storageSubnetId
          action: 'Allow'
        }
      ]
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource uploadsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'uploads'
  properties: {
    publicAccess: 'None'
  }
}

resource staticContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'static'
  properties: {
    publicAccess: 'None'
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${environmentId}-storage-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: storageSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${environmentId}-storage-pe-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storagePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
output storageAccountId string = storageAccount.id
output accountName string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints