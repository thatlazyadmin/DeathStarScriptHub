/*
  Virtual Machine Workload Scenario
  
  This deployment scenario creates a complete VM infrastructure with:
  - Virtual Network with subnets
  - Network Security Group with common rules
  - Storage Account for boot diagnostics
  - Virtual Machine (Windows or Linux)
  - Managed Identity for VM authentication
  - Optional: Public IP for remote access
  
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

@description('Application or workload name')
@minLength(3)
@maxLength(10)
param workloadName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Operating system type')
@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Linux'

@description('Virtual machine size')
@allowed([
  'Standard_B2s'      // 2 vCPU, 4 GB RAM - Dev/Test
  'Standard_D2s_v3'   // 2 vCPU, 8 GB RAM - General Purpose
  'Standard_D4s_v3'   // 4 vCPU, 16 GB RAM - General Purpose
  'Standard_D8s_v3'   // 8 vCPU, 32 GB RAM - General Purpose
  'Standard_E2s_v3'   // 2 vCPU, 16 GB RAM - Memory Optimized
  'Standard_E4s_v3'   // 4 vCPU, 32 GB RAM - Memory Optimized
])
param vmSize string = 'Standard_D2s_v3'

@description('Admin username for the VM')
param adminUsername string

@description('Admin password or SSH public key')
@secure()
param adminPasswordOrKey string

@description('Authentication type (password or sshPublicKey)')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = osType == 'Linux' ? 'sshPublicKey' : 'password'

@description('Availability zone for the VM (1, 2, 3, or empty for no zone)')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param availabilityZone string = environmentName == 'prod' ? '1' : ''

@description('Enable public IP address for remote access')
param enablePublicIP bool = environmentName == 'dev'

@description('Resource tags')
param tags object = {}

// Variables
var resourceSuffix = '${workloadName}-${environmentName}-${uniqueString(resourceGroup().id)}'
var commonTags = union(tags, {
  Environment: environmentName
  Workload: workloadName
  ManagedBy: 'IaC'
  CreatedBy: 'Shaun Hardneck'
  Website: 'thatlazyadmin.com'
})

// Managed Identity for VM
module managedIdentity '../../modules/security/managed-identity/main.bicep' = {
  name: 'managedIdentity-deployment'
  params: {
    managedIdentityName: 'id-${resourceSuffix}'
    location: location
    tags: commonTags
  }
}

// Storage Account for Boot Diagnostics
module storageAccount '../../modules/storage/storage-account/main.bicep' = {
  name: 'storage-deployment'
  params: {
    storageAccountName: take('stdiag${replace(resourceSuffix, '-', '')}', 24)
    location: location
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    tags: commonTags
  }
}

// Network Security Group
module nsg '../../modules/network/network-security-group/main.bicep' = {
  name: 'nsg-deployment'
  params: {
    nsgName: 'nsg-${resourceSuffix}'
    location: location
    securityRules: osType == 'Windows' ? [
      {
        name: 'Allow-RDP'
        priority: 100
        direction: 'Inbound'
        access: enablePublicIP ? 'Allow' : 'Deny'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '3389'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
      {
        name: 'Allow-WinRM'
        priority: 110
        direction: 'Inbound'
        access: 'Deny'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '5985-5986'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    ] : [
      {
        name: 'Allow-SSH'
        priority: 100
        direction: 'Inbound'
        access: enablePublicIP ? 'Allow' : 'Deny'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    ]
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
        name: 'subnet-vm'
        addressPrefix: '10.0.1.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        networkSecurityGroup: {
          id: nsg.outputs.nsgId
        }
      }
      {
        name: 'subnet-app'
        addressPrefix: '10.0.2.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
    tags: commonTags
  }
}

// Public IP (optional)
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (enablePublicIP) {
  name: 'pip-${resourceSuffix}'
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'
  }
  zones: !empty(availabilityZone) ? [availabilityZone] : []
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: toLower('${workloadName}-${environmentName}-${uniqueString(resourceGroup().id)}')
    }
  }
}

// Network Interface with optional Public IP
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-${resourceSuffix}'
  location: location
  tags: commonTags
  properties: {
    enableAcceleratedNetworking: contains(['Standard_D2s_v3', 'Standard_D4s_v3', 'Standard_D8s_v3', 'Standard_E2s_v3', 'Standard_E4s_v3'], vmSize)
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: virtualNetwork.outputs.subnetIds[0]
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: enablePublicIP ? {
            id: publicIP.id
          } : null
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.outputs.nsgId
    }
  }
}

// Virtual Machine
module virtualMachine '../../modules/compute/virtual-machine/main.bicep' = {
  name: 'vm-deployment'
  params: {
    vmName: 'vm-${resourceSuffix}'
    location: location
    vmSize: vmSize
    osType: osType
    osDiskSizeGB: osType == 'Windows' ? 127 : 64
    osDiskStorageType: environmentName == 'prod' ? 'Premium_LRS' : 'StandardSSD_LRS'
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    subnetId: virtualNetwork.outputs.subnetIds[0]
    enableAcceleratedNetworking: contains(['Standard_D2s_v3', 'Standard_D4s_v3', 'Standard_D8s_v3', 'Standard_E2s_v3', 'Standard_E4s_v3'], vmSize)
    availabilityZone: availabilityZone
    enableBootDiagnostics: true
    bootDiagnosticsStorageAccountName: storageAccount.outputs.storageAccountName
    tags: commonTags
  }
  dependsOn: [
    nic
  ]
}

// Outputs
@description('Virtual Machine Name')
output vmName string = virtualMachine.outputs.vmName

@description('Virtual Machine ID')
output vmId string = virtualMachine.outputs.vmId

@description('Private IP Address')
output privateIPAddress string = virtualMachine.outputs.privateIPAddress

@description('Public IP Address (if enabled)')
output publicIPAddress string = enablePublicIP ? publicIP!.properties.ipAddress : 'Not Configured'

@description('Public FQDN (if enabled)')
output publicFQDN string = enablePublicIP ? publicIP!.properties.dnsSettings.fqdn : 'Not Configured'

@description('Virtual Network ID')
output virtualNetworkId string = virtualNetwork.outputs.vnetId

@description('Storage Account Name')
output storageAccountName string = storageAccount.outputs.storageAccountName

@description('Managed Identity ID')
output managedIdentityId string = managedIdentity.outputs.managedIdentityId

@description('Managed Identity Principal ID')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('Connection Instructions')
output connectionInstructions string = osType == 'Windows' 
  ? enablePublicIP 
    ? 'RDP: mstsc /v:${publicIP!.properties.dnsSettings.fqdn}'
    : 'RDP via private IP: mstsc /v:${virtualMachine.outputs.privateIPAddress} (requires VPN/ExpressRoute)'
  : enablePublicIP
    ? 'SSH: ssh ${adminUsername}@${publicIP!.properties.dnsSettings.fqdn}'
    : 'SSH via private IP: ssh ${adminUsername}@${virtualMachine.outputs.privateIPAddress} (requires VPN/ExpressRoute)'
