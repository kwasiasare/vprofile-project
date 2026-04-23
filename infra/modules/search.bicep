@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: '${environmentId}-search'
  location: location
  tags: tags
  sku: {
    name: 'free'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    networkRuleSet: {
      ipRules: [
        {
          value: '0.0.0.0/0'
        }
      ]
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      apiKeyOnly: {}
    }
  }
}

// Outputs
output searchServiceId string = searchService.id
output serviceName string = searchService.name
output searchServiceUrl string = 'https://${searchService.name}.search.windows.net'