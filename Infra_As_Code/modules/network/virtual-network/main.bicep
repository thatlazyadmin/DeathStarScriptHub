// =========================================================================================================
// Azure Virtual Network Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys an Azure Virtual Network with subnets and NSG
// =========================================================================================================

@description('Virtual network name')
param vnetName string

@description('Location for the virtual network')
param location string = resourceGroup().location

@description('Address space for the virtual network')
param addressPrefixes array = [
  '10.0.0.0/16'
]

@description('Subnets configuration')
param subnets array = [
  {
    name: 'subnet-web'
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: 'subnet-app'
    addressPrefix: '10.0.2.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: 'subnet-data'
    addressPrefix: '10.0.3.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
]

@description('Enable DDoS protection')
param enableDdosProtection bool = false

@description('Enable VM protection')
param enableVmProtection bool = false

@description('DNS servers')
param dnsServers array = []

@description('Tags for the resource')
param tags object = {}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
        privateLinkServiceNetworkPolicies: subnet.privateLinkServiceNetworkPolicies
      }
    }]
    enableDdosProtection: enableDdosProtection
    enableVmProtection: enableVmProtection
  }
}

// Outputs
@description('Virtual network resource ID')
output vnetId string = vnet.id

@description('Virtual network name')
output vnetName string = vnet.name

@description('Subnet IDs')
output subnetIds array = [for (subnet, i) in subnets: vnet.properties.subnets[i].id]

@description('Subnet details')
output subnets array = [for (subnet, i) in subnets: {
  name: vnet.properties.subnets[i].name
  id: vnet.properties.subnets[i].id
  addressPrefix: vnet.properties.subnets[i].properties.addressPrefix
}]
