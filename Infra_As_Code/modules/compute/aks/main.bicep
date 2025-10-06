// =========================================================================================================
// Azure Kubernetes Service (AKS) Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys a production-ready AKS cluster with best practices
// =========================================================================================================

@description('AKS cluster name')
@minLength(1)
@maxLength(63)
param clusterName string

@description('Location for the AKS cluster')
param location string = resourceGroup().location

@description('Kubernetes version')
param kubernetesVersion string = '1.28.3'

@description('DNS prefix for the cluster')
param dnsPrefix string = clusterName

@description('Enable private cluster')
param enablePrivateCluster bool = false

@description('System node pool VM size')
param systemNodePoolVmSize string = 'Standard_D2s_v3'

@description('System node pool node count')
@minValue(1)
@maxValue(100)
param systemNodePoolNodeCount int = 3

@description('User node pool VM size')
param userNodePoolVmSize string = 'Standard_D4s_v3'

@description('User node pool node count')
@minValue(0)
@maxValue(100)
param userNodePoolNodeCount int = 3

@description('Enable auto-scaling for user node pool')
param enableAutoScaling bool = true

@description('Minimum node count for auto-scaling')
@minValue(1)
param minNodeCount int = 2

@description('Maximum node count for auto-scaling')
@minValue(1)
param maxNodeCount int = 10

@description('Subnet ID for AKS nodes')
param subnetId string

@description('Enable Azure Policy add-on')
param enableAzurePolicy bool = true

@description('Enable Azure Monitor (Container Insights)')
param enableAzureMonitor bool = true

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string = ''

@description('Network plugin')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string = 'azure'

@description('Network policy')
@allowed([
  'azure'
  'calico'
  ''
])
param networkPolicy string = 'azure'

@description('Load balancer SKU')
@allowed([
  'basic'
  'standard'
])
param loadBalancerSku string = 'standard'

@description('Enable RBAC')
param enableRBAC bool = true

@description('Enable Azure AD integration')
param enableAzureAD bool = true

@description('Azure AD admin group object IDs')
param aadAdminGroupObjectIds array = []

@description('Tags for the resource')
param tags object = {}

// AKS Cluster
resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
    enableRBAC: enableRBAC
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    aadProfile: enableAzureAD ? {
      managed: true
      enableAzureRBAC: true
      adminGroupObjectIDs: aadAdminGroupObjectIds
    } : null
    agentPoolProfiles: [
      {
        name: 'system'
        count: systemNodePoolNodeCount
        vmSize: systemNodePoolVmSize
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
        enableAutoScaling: false
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        maxPods: 110
        osDiskSizeGB: 128
        osDiskType: 'Managed'
      }
      {
        name: 'user'
        count: userNodePoolNodeCount
        vmSize: userNodePoolVmSize
        osType: 'Linux'
        mode: 'User'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
        enableAutoScaling: enableAutoScaling
        minCount: enableAutoScaling ? minNodeCount : null
        maxCount: enableAutoScaling ? maxNodeCount : null
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        maxPods: 110
        osDiskSizeGB: 128
        osDiskType: 'Managed'
      }
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      networkPolicy: networkPolicy
      loadBalancerSku: loadBalancerSku
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    addonProfiles: {
      azurepolicy: {
        enabled: enableAzurePolicy
      }
      omsagent: {
        enabled: enableAzureMonitor && !empty(logAnalyticsWorkspaceId)
        config: enableAzureMonitor && !empty(logAnalyticsWorkspaceId) ? {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        } : null
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: enableAzureMonitor && !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : null
        securityMonitoring: {
          enabled: enableAzureMonitor && !empty(logAnalyticsWorkspaceId)
        }
      }
    }
  }
}

// Outputs
@description('AKS cluster resource ID')
output aksClusterId string = aks.id

@description('AKS cluster name')
output aksClusterName string = aks.name

@description('AKS cluster FQDN')
output aksClusterFqdn string = aks.properties.fqdn

@description('AKS cluster identity principal ID')
output aksIdentityPrincipalId string = aks.identity.principalId

@description('AKS cluster kubelet identity object ID')
output aksKubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
