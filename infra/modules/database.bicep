@description('Environment identifier for resource naming')
param environmentId string

@description('Azure region for resource deployment')
param location string

@description('Resource tags')
param tags object

@description('MySQL administrator username')
param adminUsername string

@description('MySQL administrator password')
@secure()
param adminPassword string

@description('Database subnet resource ID')
param databaseSubnetId string

@description('Private DNS zone resource ID for MySQL')
param privateDnsZoneId string

@description('Key Vault resource ID for storing connection string')
param keyVaultId string

resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: '${environmentId}-mysql'
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    version: '8.0.21'
    storage: {
      storageSizeGB: 20
      iops: 360
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: databaseSubnetId
      privateDnsZoneResourceId: privateDnsZoneId
    }
  }
}

resource vprofileDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = {
  parent: mysqlServer
  name: 'accounts'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

// Store connection string in Key Vault
resource connectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/mysql-connection-string'
  properties: {
    value: 'jdbc:mysql://${mysqlServer.properties.fullyQualifiedDomainName}:3306/accounts?useSSL=true&requireSSL=true&serverTimezone=UTC'
  }
}

resource mysqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/mysql-password'
  properties: {
    value: adminPassword
  }
}

resource mysqlUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/mysql-username'
  properties: {
    value: adminUsername
  }
}

// Outputs
output serverName string = mysqlServer.name
output serverFqdn string = mysqlServer.properties.fullyQualifiedDomainName
output databaseName string = vprofileDatabase.name