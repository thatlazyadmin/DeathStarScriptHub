/*
  Web Application with Database Scenario
  
  This deployment scenario creates a complete web application infrastructure with:
  - App Service with managed identity
  - Azure SQL Database
  - Key Vault for secrets
  - Storage Account for static content
  - Virtual Network with private endpoints
  - Application Insights for monitoring
  
  Created by: Shaun Hardneck
  Website: thatlazyadmin.com
*/

targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string

@description('Application name')
@minLength(3)
@maxLength(10)
param applicationName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('SQL Server admin username')
param sqlAdminUsername string

@description('SQL Server admin password')
@secure()
param sqlAdminPassword string

@description('Resource tags')
param tags object = {}

// Variables
var resourceSuffix = '${applicationName}-${environmentName}-${uniqueString(resourceGroup().id)}'
var commonTags = union(tags, {
  Environment: environmentName
  Application: applicationName
  ManagedBy: 'IaC'
  CreatedBy: 'Shaun Hardneck'
  Website: 'thatlazyadmin.com'
})

// Managed Identity
module managedIdentity '../../modules/security/managed-identity/main.bicep' = {
  name: 'managedIdentity-deployment'
  params: {
    managedIdentityName: 'id-${resourceSuffix}'
    location: location
    tags: commonTags
  }
}

// Key Vault
module keyVault '../../modules/security/key-vault/main.bicep' = {
  name: 'keyVault-deployment'
  params: {
    keyVaultName: take('kv-${replace(resourceSuffix, '-', '')}', 24)
    location: location
    skuName: environmentName == 'prod' ? 'premium' : 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: environmentName == 'prod'
    publicNetworkAccess: environmentName == 'prod' ? 'Disabled' : 'Enabled'
    networkAclsDefaultAction: 'Allow'
    tags: commonTags
  }
}

// Virtual Network
module virtualNetwork '../../modules/network/virtual-network/main.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: 'vnet-${resourceSuffix}'
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'subnet-app'
        addressPrefix: '10.0.1.0/24'
        serviceEndpoints: [
          'Microsoft.Web'
          'Microsoft.Sql'
          'Microsoft.Storage'
          'Microsoft.KeyVault'
        ]
        delegations: [
          {
            name: 'delegation'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
      }
      {
        name: 'subnet-data'
        addressPrefix: '10.0.2.0/24'
        serviceEndpoints: [
          'Microsoft.Sql'
          'Microsoft.Storage'
        ]
      }
    ]
    tags: commonTags
  }
}

// Storage Account
module storageAccount '../../modules/storage/storage-account/main.bicep' = {
  name: 'storage-deployment'
  params: {
    storageAccountName: take('st${replace(resourceSuffix, '-', '')}web', 24)
    location: location
    skuName: environmentName == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
    kind: 'StorageV2'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    tags: commonTags
  }
}

// SQL Database
module sqlDatabase '../../modules/database/sql-database/main.bicep' = {
  name: 'sql-deployment'
  params: {
    serverName: 'sql-${resourceSuffix}'
    databaseName: 'sqldb-${applicationName}-${environmentName}'
    location: location
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    skuName: environmentName == 'prod' ? 'GP_Gen5_4' : 'GP_Gen5_2'
    tier: 'GeneralPurpose'
    enableAzureADAuth: false
    enableThreatProtection: true
    tags: commonTags
  }
}

// Note: Role assignments for Managed Identity access to Key Vault and Storage Account
// should be configured post-deployment or using a separate deployment with proper scope handling.
// Role assignments require compile-time values and cannot use module outputs in guid() functions.

// Outputs
@description('Managed Identity ID')
output managedIdentityId string = managedIdentity.outputs.managedIdentityId

@description('Key Vault URI')
output keyVaultUri string = keyVault.outputs.keyVaultUri

@description('Storage Account Name')
output storageAccountName string = storageAccount.outputs.storageAccountName

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlDatabase.outputs.sqlServerFqdn

@description('SQL Database Name')
output sqlDatabaseName string = sqlDatabase.outputs.sqlDatabaseName

@description('Virtual Network ID')
output virtualNetworkId string = virtualNetwork.outputs.vnetId

@description('App Subnet ID')
output appSubnetId string = virtualNetwork.outputs.subnetIds[0]
