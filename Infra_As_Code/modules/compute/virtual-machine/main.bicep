// =========================================================================================================
// Azure Virtual Machine Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys an Azure Virtual Machine with managed disks and best practices
// =========================================================================================================

@description('Virtual machine name')
@minLength(1)
@maxLength(64)
param vmName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Virtual machine size')
param vmSize string = 'Standard_D2s_v3'

@description('Operating system type')
@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Linux'

@description('OS disk size in GB')
@minValue(30)
@maxValue(2048)
param osDiskSizeGB int = 128

@description('OS disk storage type')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param osDiskStorageType string = 'Premium_LRS'

@description('Admin username')
param adminUsername string

@description('Admin password or SSH public key')
@secure()
param adminPasswordOrKey string

@description('Authentication type')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'sshPublicKey'

@description('Subnet resource ID')
param subnetId string

@description('Enable accelerated networking')
param enableAcceleratedNetworking bool = true

@description('Availability zone')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param availabilityZone string = '1'

@description('Enable boot diagnostics')
param enableBootDiagnostics bool = true

@description('Boot diagnostics storage account name (optional)')
param bootDiagnosticsStorageAccountName string = ''

@description('Tags for the resource')
param tags object = {}

// Image reference based on OS type
var imageReference = osType == 'Windows' ? {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
} : {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

// Linux configuration
var linuxConfiguration = {
  disablePasswordAuthentication: authenticationType == 'sshPublicKey'
  ssh: authenticationType == 'sshPublicKey' ? {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  } : null
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: enableAcceleratedNetworking
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  zones: !empty(availabilityZone) ? [availabilityZone] : []
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGB
        managedDisk: {
          storageAccountType: osDiskStorageType
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: authenticationType == 'password' ? adminPasswordOrKey : null
      linuxConfiguration: osType == 'Linux' ? linuxConfiguration : null
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: enableBootDiagnostics
        storageUri: !empty(bootDiagnosticsStorageAccountName) ? reference(resourceId('Microsoft.Storage/storageAccounts', bootDiagnosticsStorageAccountName), '2023-01-01').primaryEndpoints.blob : null
      }
    }
    securityProfile: {
      encryptionAtHost: true
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}

// Outputs
@description('Virtual machine resource ID')
output vmId string = vm.id

@description('Virtual machine name')
output vmName string = vm.name

@description('Private IP address')
output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress

@description('Network interface ID')
output nicId string = nic.id
