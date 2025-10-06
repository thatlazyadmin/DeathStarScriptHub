/*
  Azure Managed Identity Module
  
  This module creates a user-assigned managed identity for Azure resources.
  
  Created by: Shaun Hardneck
  Website: thatlazyadmin.com
*/

@description('Managed Identity name')
param managedIdentityName string

@description('Azure region for Managed Identity')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: union(tags, {
    CreatedBy: 'Shaun Hardneck'
    Website: 'thatlazyadmin.com'
  })
}

// Outputs
@description('Managed Identity name')
output managedIdentityName string = managedIdentity.name

@description('Managed Identity resource ID')
output managedIdentityId string = managedIdentity.id

@description('Managed Identity principal ID')
output principalId string = managedIdentity.properties.principalId

@description('Managed Identity client ID')
output clientId string = managedIdentity.properties.clientId

@description('Managed Identity tenant ID')
output tenantId string = managedIdentity.properties.tenantId
