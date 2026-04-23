@description('Project name used for resource naming')
param projectName string

@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

@description('Key Vault subnet resource ID')
param keyVaultSubnetId string

@description('Key Vault private DNS zone resource ID')
param keyVaultDnsZoneId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: toLower('${take(projectName, 11)}-kv-${take(uniqueString(resourceGroup().id), 8)}')
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 30
    enableRbacAuthorization: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${environmentId}-kv-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: keyVaultSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${environmentId}-kv-pe-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: keyVaultPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: keyVaultDnsZoneId
        }
      }
    ]
  }
}

// Outputs
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri