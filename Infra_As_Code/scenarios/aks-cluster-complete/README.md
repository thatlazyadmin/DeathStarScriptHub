# Complete AKS Cluster Scenario

Production-ready Azure Kubernetes Service (AKS) cluster deployment.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Architecture

- **AKS Cluster**: Managed Kubernetes with Azure CNI networking
- **System Node Pool**: Dedicated for system pods (2-3 nodes)
- **User Node Pool**: Auto-scaling for application workloads
- **Virtual Network**: Dedicated VNet with AKS and Application Gateway subnets
- **Managed Identity**: User-assigned identity for AKS
- **Availability Zones**: Multi-zone deployment for production

## Deployment

```bash
# Create resource group
az group create \
  --name rg-aks-prod \
  --location eastus

# Deploy AKS cluster
az deployment group create \
  --resource-group rg-aks-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json
```

## Post-Deployment

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group rg-aks-prod \
  --name aks-myapp-prod-xxxxx

# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

## Node Pool Configuration

### Production

- **System Pool**: 3x Standard_D4s_v3 (4 vCPU, 16 GB RAM)
- **User Pool**: 2-10x Standard_D8s_v3 (8 vCPU, 32 GB RAM)
- **Zones**: 1, 2, 3

### Development

- **System Pool**: 2x Standard_D2s_v3 (2 vCPU, 8 GB RAM)
- **User Pool**: 1-5x Standard_D4s_v3 (4 vCPU, 16 GB RAM)
- **Zones**: None

## Features

- Azure CNI networking
- Azure Network Policy
- RBAC enabled
- Auto-scaling enabled
- Container Insights monitoring
- Azure Policy add-on
- Key Vault Secrets Provider

## Cost Estimation (Monthly)

### Production

- **Control Plane**: ~$73
- **System Nodes** (3x D4s_v3): ~$350
- **User Nodes** (avg 5x D8s_v3): ~$1,200
- **Total**: ~$1,623/month

### Development

- **Control Plane**: ~$73
- **System Nodes** (2x D2s_v3): ~$120
- **User Nodes** (avg 2x D4s_v3): ~$190
- **Total**: ~$383/month

## Related Resources

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
