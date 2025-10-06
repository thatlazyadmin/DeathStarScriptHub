// =========================================================================================================
// Network Security Group Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys a Network Security Group with custom rules
// =========================================================================================================

@description('Network Security Group name')
param nsgName string

@description('Location for the NSG')
param location string = resourceGroup().location

@description('Security rules')
param securityRules array = []

@description('Tags for the resource')
param tags object = {}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

// Outputs
@description('NSG resource ID')
output nsgId string = nsg.id

@description('NSG name')
output nsgName string = nsg.name
