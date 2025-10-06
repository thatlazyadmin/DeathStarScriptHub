// =========================================================================================================
// Azure SQL Database Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys Azure SQL Server and Database with best practices
// =========================================================================================================

@description('SQL Server name')
param serverName string

@description('Location for the SQL Server')
param location string = resourceGroup().location

@description('SQL Database name')
param databaseName string

@description('Administrator login username')
param administratorLogin string

@description('Administrator login password')
@secure()
param administratorLoginPassword string

@description('SQL Server version')
param version string = '12.0'

@description('Database SKU')
param skuName string = 'GP_S_Gen5_2'

@description('Database tier')
param tier string = 'GeneralPurpose'

@description('Maximum database size in bytes')
param maxSizeBytes int = 34359738368

@description('Enable Azure AD authentication')
param enableAzureADAuth bool = true

@description('Azure AD admin object ID')
param azureADAdminObjectId string = ''

@description('Azure AD admin login name')
param azureADAdminLogin string = ''

@description('Enable Advanced Threat Protection')
param enableThreatProtection bool = true

@description('Enable diagnostic settings')
param enableDiagnostics bool = true

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string = ''

@description('Tags for the resource')
param tags object = {}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: version
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

// Azure AD Administrator
resource azureADAdmin 'Microsoft.Sql/servers/administrators@2023-05-01-preview' = if (enableAzureADAuth && !empty(azureADAdminObjectId)) {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: azureADAdminLogin
    sid: azureADAdminObjectId
    tenantId: subscription().tenantId
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: tier
  }
  properties: {
    maxSizeBytes: maxSizeBytes
    zoneRedundant: true
  }
}

// Advanced Threat Protection
resource threatProtection 'Microsoft.Sql/servers/securityAlertPolicies@2023-05-01-preview' = if (enableThreatProtection) {
  parent: sqlServer
  name: 'Default'
  properties: {
    state: 'Enabled'
    emailAccountAdmins: true
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-${databaseName}'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
    ]
  }
}

// Outputs
@description('SQL Server resource ID')
output sqlServerId string = sqlServer.id

@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('SQL Database resource ID')
output sqlDatabaseId string = sqlDatabase.id

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
