targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Project name used for resource naming')
param projectName string = 'vprofile'

@description('Primary Azure region for resource deployment')
param location string = resourceGroup().location

@description('Administrator username for MySQL server')
param mysqlAdminUsername string

@description('MySQL server administrator password')
@secure()
param mysqlAdminPassword string = newGuid()

// Variables
var environmentId = '${projectName}-${environment}'
var commonTags = {
  environment: environment
  project: projectName
  managedBy: 'bicep'
}

// Networking module - creates VNet, subnets, private DNS zones
module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
  }
}

// Monitoring module - creates Log Analytics and Application Insights
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
  }
}

// Security module - creates Key Vault
module security 'modules/security.bicep' = {
  name: 'security'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    keyVaultSubnetId: networking.outputs.keyVaultSubnetId
    keyVaultDnsZoneId: networking.outputs.keyVaultDnsZoneId
  }
}

// Container Registry module
module registry 'modules/registry.bicep' = {
  name: 'registry'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    registrySubnetId: networking.outputs.registrySubnetId
    privateDnsZoneId: networking.outputs.registryDnsZoneId
  }
}

// Database module - creates MySQL Flexible Server
module database 'modules/database.bicep' = {
  name: 'database'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    adminUsername: mysqlAdminUsername
    adminPassword: mysqlAdminPassword
    databaseSubnetId: networking.outputs.databaseSubnetId
    privateDnsZoneId: networking.outputs.mysqlDnsZoneId
    keyVaultId: security.outputs.keyVaultId
  }
}

// Storage module - creates Storage Account with private endpoint
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    storageSubnetId: networking.outputs.storageSubnetId
    privateDnsZoneId: networking.outputs.storageBlobDnsZoneId
  }
}

// Caching module - creates Redis Cache
module caching 'modules/caching.bicep' = {
  name: 'caching'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    redisSubnetId: networking.outputs.redisSubnetId
    privateDnsZoneId: networking.outputs.redisDnsZoneId
    keyVaultId: security.outputs.keyVaultId
  }
}

// Messaging module - creates Service Bus
module messaging 'modules/messaging.bicep' = {
  name: 'messaging'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    serviceBusSubnetId: networking.outputs.serviceBusSubnetId
    serviceBusDnsZoneId: networking.outputs.serviceBusDnsZoneId
    keyVaultId: security.outputs.keyVaultId
  }
}

// Search module - creates Cognitive Search
module search 'modules/search.bicep' = {
  name: 'search'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
  }
}

// Compute module - creates Container Apps Environment and App
module compute 'modules/compute.bicep' = {
  name: 'compute'
  params: {
    environmentId: environmentId
    location: location
    tags: commonTags
    containerAppsSubnetId: networking.outputs.containerAppsSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    keyVaultUri: security.outputs.keyVaultUri
    registryLoginServer: registry.outputs.loginServer
  }
}

// RBAC module - creates role assignments for managed identity
module rbac 'modules/rbac.bicep' = {
  name: 'rbac'
  params: {
    containerAppPrincipalId: compute.outputs.containerAppPrincipalId
    containerRegistryId: registry.outputs.registryId
    keyVaultId: security.outputs.keyVaultId
    storageAccountId: storage.outputs.storageAccountId
    serviceBusId: messaging.outputs.serviceBusId
    searchServiceId: search.outputs.searchServiceId
  }
}

// Outputs
@description('URL of the deployed container application')
output containerAppUrl string = compute.outputs.containerAppUrl
@description('Key Vault URI for accessing secrets')
output keyVaultUri string = security.outputs.keyVaultUri
@description('Container Registry login server for image operations')
output containerRegistryLoginServer string = registry.outputs.loginServer
@description('MySQL server name for database connections')
output mysqlServerName string = database.outputs.serverName
@description('Redis cache name for caching operations')
output redisCacheName string = caching.outputs.cacheName
@description('Service Bus namespace for messaging')
output serviceBusNamespace string = messaging.outputs.namespaceName
@description('Search service name for search operations')
output searchServiceName string = search.outputs.serviceName
@description('Storage account name for blob operations')
output storageAccountName string = storage.outputs.accountName