@description('Container App principal ID for role assignments')
param containerAppPrincipalId string

@description('Container Registry resource ID')
param containerRegistryId string

@description('Key Vault resource ID')
param keyVaultId string

@description('Storage Account resource ID')
param storageAccountId string

@description('Service Bus resource ID')
param serviceBusId string

@description('Search Service resource ID')
param searchServiceId string

// ACR Pull role assignment - scoped to specific container registry
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistryId, containerAppPrincipalId, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Key Vault Secrets User role assignment - scoped to specific key vault
resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, containerAppPrincipalId, 'KeyVaultSecretsUser')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor role assignment - scoped to specific storage account
resource storageBlobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, containerAppPrincipalId, 'StorageBlobDataContributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Service Bus Data Sender role assignment - scoped to specific service bus
resource serviceBusDataSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusId, containerAppPrincipalId, 'ServiceBusDataSender')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Search Service Contributor role assignment - scoped to specific search service
resource searchServiceContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchServiceId, containerAppPrincipalId, 'SearchServiceContributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}