/*
  Azure Cosmos DB Account Module
  
  This module deploys an Azure Cosmos DB account with security and monitoring best practices.
  
  Created by: Shaun Hardneck
  Website: thatlazyadmin.com
*/

@description('Cosmos DB account name (must be globally unique)')
@minLength(3)
@maxLength(44)
param accountName string

@description('Azure region for Cosmos DB account')
param location string = resourceGroup().location

@description('Cosmos DB API type')
@allowed([
  'Sql'
  'MongoDB'
  'Cassandra'
  'Gremlin'
  'Table'
])
param databaseApiType string = 'Sql'

@description('Consistency level for Cosmos DB')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param consistencyLevel string = 'Session'

@description('Enable automatic failover')
param enableAutomaticFailover bool = true

@description('Enable multi-region writes')
param enableMultipleWriteLocations bool = false

@description('Enable serverless mode (cannot be used with autoscale)')
param enableServerless bool = false

@description('Enable free tier (one per subscription)')
param enableFreeTier bool = false

@description('Array of regions for replication')
param locations array = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]

@description('Enable analytical storage')
param enableAnalyticalStorage bool = false

@description('Enable public network access')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('IP rules for firewall')
param ipRules array = []

@description('Virtual Network rules')
param virtualNetworkRules array = []

@description('Enable backup')
param enableBackup bool = true

@description('Backup storage redundancy')
@allowed([
  'Geo'
  'Local'
  'Zone'
])
param backupStorageRedundancy string = 'Geo'

@description('Backup interval in minutes (for periodic backup)')
param backupIntervalInMinutes int = 240

@description('Backup retention in hours (for periodic backup)')
param backupRetentionIntervalInHours int = 8

@description('Enable diagnostic settings')
param enableDiagnostics bool = true

@description('Log Analytics workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags')
param tags object = {}

// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: accountName
  location: location
  kind: databaseApiType == 'MongoDB' ? 'MongoDB' : 'GlobalDocumentDB'
  tags: union(tags, {
    CreatedBy: 'Shaun Hardneck'
    Website: 'thatlazyadmin.com'
  })
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: enableAutomaticFailover
    enableMultipleWriteLocations: enableMultipleWriteLocations
    enableFreeTier: enableFreeTier
    publicNetworkAccess: publicNetworkAccess
    capabilities: union(
      databaseApiType == 'Sql' ? [] : databaseApiType == 'MongoDB' ? [
        { name: 'EnableMongo' }
      ] : databaseApiType == 'Cassandra' ? [
        { name: 'EnableCassandra' }
      ] : databaseApiType == 'Gremlin' ? [
        { name: 'EnableGremlin' }
      ] : [
        { name: 'EnableTable' }
      ],
      enableServerless ? [
        { name: 'EnableServerless' }
      ] : [],
      enableAnalyticalStorage ? [
        { name: 'EnableAnalyticalStorage' }
      ] : []
    )
    consistencyPolicy: {
      defaultConsistencyLevel: consistencyLevel
      maxIntervalInSeconds: consistencyLevel == 'BoundedStaleness' ? 86400 : null
      maxStalenessPrefix: consistencyLevel == 'BoundedStaleness' ? 1000000 : null
    }
    locations: locations
    backupPolicy: enableBackup ? {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: backupIntervalInMinutes
        backupRetentionIntervalInHours: backupRetentionIntervalInHours
        backupStorageRedundancy: backupStorageRedundancy
      }
    } : null
    ipRules: [for ipRule in ipRules: {
      ipAddressOrRange: ipRule
    }]
    virtualNetworkRules: virtualNetworkRules
    networkAclBypass: 'AzureServices'
    disableKeyBasedMetadataWriteAccess: true
    enableAnalyticalStorage: enableAnalyticalStorage
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: '${accountName}-diagnostics'
  scope: cosmosDbAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
}

// Outputs
@description('Cosmos DB account name')
output accountName string = cosmosDbAccount.name

@description('Cosmos DB account resource ID')
output accountId string = cosmosDbAccount.id

@description('Cosmos DB account endpoint')
output endpoint string = cosmosDbAccount.properties.documentEndpoint

@description('Cosmos DB account primary key (secure) - Use Key Vault or managed identity instead')
@secure()
output primaryKey string = cosmosDbAccount.listKeys().primaryMasterKey

@description('Cosmos DB account secondary key (secure) - Use Key Vault or managed identity instead')
@secure()
output secondaryKey string = cosmosDbAccount.listKeys().secondaryMasterKey

@description('Cosmos DB account connection string (secure) - Use Key Vault or managed identity instead')
@secure()
output connectionString string = 'AccountEndpoint=${cosmosDbAccount.properties.documentEndpoint};AccountKey=${cosmosDbAccount.listKeys().primaryMasterKey}'
