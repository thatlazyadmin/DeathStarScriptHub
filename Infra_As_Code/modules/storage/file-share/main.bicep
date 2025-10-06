// =========================================================================================================
// Azure File Share Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys an Azure File Share with SMB/NFS support
// =========================================================================================================

@description('Name of the parent storage account')
param storageAccountName string

@description('Name of the file share')
@minLength(3)
@maxLength(63)
param fileShareName string

@description('Access tier for the file share')
@allowed([
  'Cool'
  'Hot'
  'Premium'
  'TransactionOptimized'
])
param accessTier string = 'TransactionOptimized'

@description('Share quota in GB (1-102400)')
@minValue(1)
@maxValue(102400)
param shareQuota int = 100

@description('Enable protocol for file share')
@allowed([
  'SMB'
  'NFS'
])
param enabledProtocol string = 'SMB'

@description('Tags for the resource')
param tags object = {}

// Reference to existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// File Services
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// File Share
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileServices
  name: fileShareName
  properties: {
    accessTier: accessTier
    shareQuota: shareQuota
    enabledProtocols: enabledProtocol
    metadata: tags
  }
}

// Outputs
@description('File share resource ID')
output fileShareId string = fileShare.id

@description('File share name')
output fileShareName string = fileShare.name

@description('File share URL')
output fileShareUrl string = '${storageAccount.properties.primaryEndpoints.file}${fileShareName}'
