# Azure Kubernetes Service (AKS) Module

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This module deploys a production-ready Azure Kubernetes Service (AKS) cluster with best practices, including Azure CNI networking, Azure Policy, Container Insights, and auto-scaling.

## Features

- ✅ System and user node pools with availability zones
- ✅ Azure CNI or Kubenet networking
- ✅ Azure Policy add-on for compliance
- ✅ Container Insights (Azure Monitor)
- ✅ Azure AD integration with RBAC
- ✅ Key Vault Secrets Provider add-on
- ✅ Auto-scaling support
- ✅ Private cluster option
- ✅ Microsoft Defender for Containers

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `clusterName` | string | Yes | - | AKS cluster name |
| `location` | string | No | resourceGroup().location | Azure region |
| `kubernetesVersion` | string | No | 1.28.3 | Kubernetes version |
| `dnsPrefix` | string | No | clusterName | DNS prefix |
| `enablePrivateCluster` | bool | No | false | Enable private cluster |
| `systemNodePoolVmSize` | string | No | Standard_D2s_v3 | System node pool VM size |
| `systemNodePoolNodeCount` | int | No | 3 | System node pool count |
| `userNodePoolVmSize` | string | No | Standard_D4s_v3 | User node pool VM size |
| `userNodePoolNodeCount` | int | No | 3 | User node pool count |
| `enableAutoScaling` | bool | No | true | Enable auto-scaling |
| `minNodeCount` | int | No | 2 | Min nodes for auto-scaling |
| `maxNodeCount` | int | No | 10 | Max nodes for auto-scaling |
| `subnetId` | string | Yes | - | Subnet resource ID |
| `enableAzurePolicy` | bool | No | true | Enable Azure Policy |
| `enableAzureMonitor` | bool | No | true | Enable Container Insights |
| `logAnalyticsWorkspaceId` | string | No | '' | Log Analytics workspace ID |
| `networkPlugin` | string | No | azure | Network plugin (azure/kubenet) |
| `networkPolicy` | string | No | azure | Network policy (azure/calico) |
| `loadBalancerSku` | string | No | standard | Load balancer SKU |
| `enableRBAC` | bool | No | true | Enable RBAC |
| `enableAzureAD` | bool | No | true | Enable Azure AD integration |
| `aadAdminGroupObjectIds` | array | No | [] | Azure AD admin group IDs |
| `tags` | object | No | {} | Resource tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `aksClusterId` | string | AKS cluster resource ID |
| `aksClusterName` | string | AKS cluster name |
| `aksClusterFqdn` | string | AKS cluster FQDN |
| `aksIdentityPrincipalId` | string | AKS managed identity principal ID |
| `aksKubeletIdentityObjectId` | string | Kubelet identity object ID |

## Usage

### Deploy AKS Cluster

```bash
az deployment group create \
  --resource-group rg-aks \
  --template-file main.bicep \
  --parameters @parameters.json
```

### Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group rg-aks \
  --name aks-prod-001
```

## Examples

### Basic AKS Cluster

```bicep
module aks 'main.bicep' = {
  name: 'aksDeployment'
  params: {
    clusterName: 'aks-dev-001'
    systemNodePoolNodeCount: 2
    userNodePoolNodeCount: 2
    enableAutoScaling: false
    subnetId: subnet.id
    enableAzureAD: false
  }
}
```

### Production AKS Cluster

```bicep
module aks 'main.bicep' = {
  name: 'aksProdDeployment'
  params: {
    clusterName: 'aks-prod-001'
    kubernetesVersion: '1.28.3'
    enablePrivateCluster: true
    systemNodePoolVmSize: 'Standard_D4s_v3'
    systemNodePoolNodeCount: 3
    userNodePoolVmSize: 'Standard_D8s_v3'
    userNodePoolNodeCount: 5
    enableAutoScaling: true
    minNodeCount: 3
    maxNodeCount: 20
    subnetId: subnet.id
    enableAzurePolicy: true
    enableAzureMonitor: true
    logAnalyticsWorkspaceId: workspace.id
    networkPlugin: 'azure'
    networkPolicy: 'azure'
    enableAzureAD: true
    aadAdminGroupObjectIds: [
      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    ]
  }
}
```

## Post-Deployment Configuration

### Connect to AKS Cluster

```bash
# Get credentials
az aks get-credentials --resource-group rg-aks --name aks-prod-001

# Verify connection
kubectl get nodes
```

### Install Ingress Controller

```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace ingress-nginx
```

### Configure Workload Identity

```bash
# Enable workload identity
az aks update \
  --resource-group rg-aks \
  --name aks-prod-001 \
  --enable-workload-identity \
  --enable-oidc-issuer
```

## Security Best Practices

1. **Enable Private Cluster** for production workloads
2. **Use Azure AD Integration** with RBAC
3. **Enable Azure Policy** for compliance
4. **Configure Network Policies** to restrict pod-to-pod traffic
5. **Use Managed Identities** (Workload Identity) for apps
6. **Enable Microsoft Defender** for threat detection
7. **Implement Pod Security Standards** (restricted profile)

## Monitoring & Logging

- **Container Insights**: Enabled by default with Log Analytics
- **Azure Monitor**: Metrics and alerts configured
- **Application Insights**: Integrate for application monitoring
- **Log Analytics**: Centralized logging for cluster and apps

## Cost Optimization

1. Use **auto-scaling** to match demand
2. Implement **cluster autoscaler** for node pools
3. Use **spot instances** for dev/test workloads
4. Enable **start/stop** for non-production clusters
5. Right-size **VM SKUs** based on workload requirements

## Author

**Shaun Hardneck**  
[thatlazyadmin.com](https://thatlazyadmin.com)
