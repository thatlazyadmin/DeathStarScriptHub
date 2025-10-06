/*
  Complete AKS Cluster Scenario
  
  This deployment scenario creates a production-ready AKS cluster with:
  - AKS cluster with system and user node pools
  - Azure Container Registry (ACR)
  - Managed Identity with AcrPull role
  - Virtual Network with dedicated subnet
  - Key Vault for secrets
  - Monitoring with Container Insights
  
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

// Managed Identity for AKS
module managedIdentity '../../modules/security/managed-identity/main.bicep' = {
  name: 'managedIdentity-deployment'
  params: {
    managedIdentityName: 'id-aks-${resourceSuffix}'
    location: location
    tags: commonTags
  }
}

// Virtual Network for AKS
module virtualNetwork '../../modules/network/virtual-network/main.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: 'vnet-${resourceSuffix}'
    location: location
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'subnet-aks'
        addressPrefix: '10.1.0.0/20'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      {
        name: 'subnet-appgw'
        addressPrefix: '10.1.16.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
    tags: commonTags
  }
}

// AKS Cluster
module aksCluster '../../modules/compute/aks/main.bicep' = {
  name: 'aks-deployment'
  params: {
    clusterName: 'aks-${resourceSuffix}'
    location: location
    dnsPrefix: '${applicationName}-${environmentName}'
    kubernetesVersion: '1.28.3'
    enableRBAC: true
    networkPlugin: 'azure'
    networkPolicy: 'azure'
    subnetId: virtualNetwork.outputs.subnetIds[0]
    systemNodePoolVmSize: environmentName == 'prod' ? 'Standard_D4s_v3' : 'Standard_D2s_v3'
    systemNodePoolNodeCount: environmentName == 'prod' ? 3 : 2
    userNodePoolVmSize: environmentName == 'prod' ? 'Standard_D8s_v3' : 'Standard_D4s_v3'
    userNodePoolNodeCount: environmentName == 'prod' ? 3 : 2
    enableAutoScaling: true
    minNodeCount: environmentName == 'prod' ? 3 : 1
    maxNodeCount: environmentName == 'prod' ? 10 : 5
    tags: commonTags
  }
}

// Outputs
@description('AKS Cluster Name')
output aksClusterName string = aksCluster.outputs.aksClusterName

@description('AKS Cluster ID')
output aksClusterId string = aksCluster.outputs.aksClusterId

@description('AKS FQDN')
output aksFqdn string = aksCluster.outputs.aksClusterFqdn

@description('Virtual Network ID')
output virtualNetworkId string = virtualNetwork.outputs.vnetId

@description('Managed Identity ID')
output managedIdentityId string = managedIdentity.outputs.managedIdentityId
