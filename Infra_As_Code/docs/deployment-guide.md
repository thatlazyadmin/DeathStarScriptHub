# Azure Infrastructure as Code - Deployment Guide

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Deployment Methods](#deployment-methods)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)

## Overview

This guide provides step-by-step instructions for deploying Azure resources using the Bicep templates in this repository.

## Prerequisites

### Required Tools

1. **Azure CLI** (v2.50.0 or later)
   - Download: <https://aka.ms/installazurecli>
   - Verify: `az --version`

2. **Bicep CLI** (v0.20.0 or later)
   - Install: `az bicep install`
   - Verify: `az bicep version`

3. **PowerShell 7+** (for PowerShell scripts)
   - Download: <https://aka.ms/powershell>
   - Verify: `$PSVersionTable.PSVersion`

### Azure Permissions

Ensure you have the following permissions:

- **Contributor** role on the target subscription or resource group
- **User Access Administrator** for RBAC assignments (if needed)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/thatlazyadmin/DeathStarScriptHub.git
cd DeathStarScriptHub/Infra_As_Code
```

### 2. Login to Azure

```bash
az login
```

### 3. Set Your Subscription

```bash
# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 4. Create Resource Group (if needed)

```bash
az group create \
  --name rg-prod-001 \
  --location eastus
```

## Deployment Methods

### Method 1: Azure CLI

#### Basic Deployment

```bash
az deployment group create \
  --resource-group rg-prod-001 \
  --template-file modules/storage/storage-account/main.bicep \
  --parameters storageAccountName=stmyuniquestorage
```

#### With Parameter File

```bash
az deployment group create \
  --resource-group rg-prod-001 \
  --template-file modules/storage/storage-account/main.bicep \
  --parameters @modules/storage/storage-account/parameters.json
```

#### With What-If

```bash
az deployment group create \
  --resource-group rg-prod-001 \
  --template-file modules/storage/storage-account/main.bicep \
  --parameters @modules/storage/storage-account/parameters.json \
  --what-if
```

### Method 2: PowerShell Script

```powershell
./scripts/deploy.ps1 `
  -ResourceGroup "rg-prod-001" `
  -TemplateFile "modules/storage/storage-account/main.bicep" `
  -ParameterFile "modules/storage/storage-account/parameters.json" `
  -Location "eastus"
```

### Method 3: Bash Script

```bash
./scripts/deploy.sh \
  --resource-group "rg-prod-001" \
  --template-file "modules/storage/storage-account/main.bicep" \
  --parameter-file "modules/storage/storage-account/parameters.json" \
  --location "eastus"
```

## Common Scenarios

### Deploy Storage Account

```bash
# 1. Update parameters
cp modules/storage/storage-account/parameters.json my-storage-params.json
# Edit my-storage-params.json with your values

# 2. Deploy
az deployment group create \
  --resource-group rg-storage \
  --template-file modules/storage/storage-account/main.bicep \
  --parameters @my-storage-params.json
```

### Deploy Virtual Machine

```bash
# 1. Prepare parameters
cp modules/compute/virtual-machine/parameters.json my-vm-params.json
# Update subnet ID, SSH key, etc.

# 2. Deploy
az deployment group create \
  --resource-group rg-vms \
  --template-file modules/compute/virtual-machine/main.bicep \
  --parameters @my-vm-params.json
```

### Deploy AKS Cluster

```bash
# 1. Prepare parameters
cp modules/compute/aks/parameters.json my-aks-params.json
# Update subnet ID, node counts, etc.

# 2. Deploy
az deployment group create \
  --resource-group rg-aks \
  --template-file modules/compute/aks/main.bicep \
  --parameters @my-aks-params.json

# 3. Get credentials
az aks get-credentials \
  --resource-group rg-aks \
  --name aks-prod-001
```

### Deploy Complete Scenario

```bash
# Deploy web app with database
az deployment group create \
  --resource-group rg-webapp \
  --template-file scenarios/web-app-with-database/main.bicep \
  --parameters @scenarios/web-app-with-database/parameters.json
```

## Parameter Files

### Using Key Vault References

Instead of storing secrets in parameter files, reference Azure Key Vault:

```json
{
  "adminPassword": {
    "reference": {
      "keyVault": {
        "id": "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault-name}"
      },
      "secretName": "vmAdminPassword"
    }
  }
}
```

### Environment-Specific Parameters

Create separate parameter files for each environment:

```text
parameters.dev.json
parameters.staging.json
parameters.prod.json
```

Deploy with environment-specific file:

```bash
az deployment group create \
  --resource-group rg-prod \
  --template-file main.bicep \
  --parameters @parameters.prod.json
```

## Validation

### Validate Before Deployment

```bash
# Validate template
az deployment group validate \
  --resource-group rg-prod-001 \
  --template-file main.bicep \
  --parameters @parameters.json

# What-if analysis
az deployment group create \
  --resource-group rg-prod-001 \
  --template-file main.bicep \
  --parameters @parameters.json \
  --what-if
```

### Validate All Templates

```powershell
./scripts/validate.ps1 -Path "modules" -Recursive
```

## Cleanup

### Delete Resource Group

```powershell
./scripts/cleanup.ps1 -ResourceGroup "rg-demo" -Force
```

Or using Azure CLI:

```bash
az group delete --name rg-demo --yes --no-wait
```

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.

## Best Practices

1. **Always use What-If** before production deployments
2. **Store secrets in Key Vault**, not in parameter files
3. **Use parameter files** for different environments
4. **Tag all resources** for cost management and organization
5. **Enable diagnostic settings** for monitoring
6. **Use managed identities** instead of service principals
7. **Implement RBAC** with least privilege principle

## Next Steps

- Review [Best Practices Guide](best-practices.md)
- Explore [Complete Scenarios](../scenarios/)
- Check [Module Documentation](../modules/)

## Support

For issues or questions:

- Open an issue on GitHub
- Visit [thatlazyadmin.com](https://thatlazyadmin.com)

---

**Author:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)
