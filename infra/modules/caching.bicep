@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

@description('Redis subnet resource ID')
param redisSubnetId string

@description('Private DNS zone resource ID for Redis')
param privateDnsZoneId string

@description('Key Vault resource ID for storing connection string')
param keyVaultId string

resource redisCache 'Microsoft.Cache/Redis@2024-03-01' = {
  name: '${environmentId}-redis'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

resource redisPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${environmentId}-redis-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: redisSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${environmentId}-redis-pe-connection'
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
  }
}

resource redisPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: redisPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-redis-cache-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Store Redis connection details in Key Vault
resource redisHostSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/redis-hostname'
  properties: {
    value: redisCache.properties.hostName
  }
}

resource redisPortSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/redis-port'
  properties: {
    value: '6380'
  }
}

resource redisKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/redis-key'
  properties: {
    value: redisCache.listKeys().primaryKey
  }
}

// Outputs
output cacheId string = redisCache.id
output cacheName string = redisCache.name
output hostName string = redisCache.properties.hostName