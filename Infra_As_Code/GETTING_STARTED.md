# 🚀 Getting Started with Azure IaC

Welcome! This guide will help you deploy your first Azure resource using this repository.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Prerequisites

Before you begin, ensure you have:

- ✅ **Azure Subscription** - Active Azure subscription
- ✅ **Azure CLI** - Version 2.50 or later ([Install Guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- ✅ **Bicep** - Installed with Azure CLI or standalone ([Install Guide](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install))
- ✅ **PowerShell 7+** - For PowerShell scripts ([Install Guide](https://docs.microsoft.com/powershell/scripting/install/installing-powershell))
- ✅ **Git** - To clone the repository

### Verify Prerequisites

```bash
# Check Azure CLI version
az version

# Check Bicep version
az bicep version

# Check PowerShell version
pwsh --version

# Login to Azure
az login

# Set default subscription (optional)
az account set --subscription "<subscription-name-or-id>"
```

## 5-Minute Quick Start

Let's deploy your first resource - a Storage Account!

### Step 1: Navigate to the Module

```bash
cd Infra_As_Code/modules/storage/storage-account
```

### Step 2: Review the Parameters

Open `parameters.json` and customize:

```json
{
  "storageAccountName": {
    "value": "mystorageacct123"  // Must be globally unique, 3-24 chars, lowercase
  },
  "location": {
    "value": "eastus"  // Change to your preferred region
  },
  "skuName": {
    "value": "Standard_LRS"  // Standard locally-redundant storage
  }
}
```

### Step 3: Create Resource Group

```bash
az group create \
  --name rg-quickstart-demo \
  --location eastus
```

### Step 4: Deploy the Storage Account

```bash
az deployment group create \
  --resource-group rg-quickstart-demo \
  --template-file main.bicep \
  --parameters parameters.json
```

### Step 5: Verify Deployment

```bash
# List resources in the resource group
az resource list \
  --resource-group rg-quickstart-demo \
  --output table

# Get storage account details
az storage account show \
  --name mystorageacct123 \
  --resource-group rg-quickstart-demo
```

🎉 **Congratulations!** You've deployed your first Azure resource using Bicep!

## What to Try Next

### Option 1: Deploy a Virtual Machine

Perfect for learning compute resources.

```bash
cd ../../compute/virtual-machine

# Edit parameters.json with your values
# Deploy
az group create --name rg-vm-demo --location eastus
az deployment group create \
  --resource-group rg-vm-demo \
  --template-file main.bicep \
  --parameters parameters.json
```

**Time**: ~10 minutes  
**Cost**: ~$30-50/month (B-series VM)  
**Learn**: Compute, networking, managed disks

### Option 2: Deploy SQL Database

Great for understanding database deployments.

```bash
cd ../../database/sql-database

# Edit parameters.json
# IMPORTANT: Use Key Vault for password in production!
az group create --name rg-sql-demo --location eastus
az deployment group create \
  --resource-group rg-sql-demo \
  --template-file main.bicep \
  --parameters parameters.json \
  --parameters administratorLoginPassword="YourP@ssw0rd!"
```

**Time**: ~5 minutes  
**Cost**: ~$365/month (GP_Gen5_2)  
**Learn**: Databases, security, auditing

### Option 3: Deploy Complete Scenario

Deploy a multi-resource solution.

```bash
cd ../../../scenarios/web-app-with-database

# Edit parameters.prod.json
az group create --name rg-webapp-demo --location eastus
az deployment group create \
  --resource-group rg-webapp-demo \
  --template-file main.bicep \
  --parameters parameters.prod.json \
  --parameters sqlAdminPassword="YourP@ssw0rd!"
```

**Time**: ~15 minutes  
**Cost**: ~$400-1000/month depending on configuration  
**Learn**: Complete architecture, managed identity, Key Vault integration

## Understanding the Structure

### Every Module Has 3 Files

```text
module-name/
├── main.bicep          # The Bicep template
├── parameters.json     # Default parameters
└── README.md          # Documentation
```

### How to Use a Module

1. **Read the README.md** - Understand what it does
2. **Copy parameters.json** - Create your own parameter file
3. **Customize parameters** - Set your specific values
4. **Deploy** - Use `az deployment group create`

## Common Customizations

### Change Resource Location

```json
{
  "location": {
    "value": "westus"  // or "northeurope", "southeastasia", etc.
  }
}
```

### Add Custom Tags

```json
{
  "tags": {
    "value": {
      "Environment": "Development",
      "CostCenter": "IT",
      "Owner": "YourName",
      "CreatedBy": "Shaun Hardneck",
      "Website": "thatlazyadmin.com"
    }
  }
}
```

### Change SKU/Size

```json
{
  "skuName": {
    "value": "Standard_GRS"  // Geographic redundancy instead of LRS
  }
}
```

## Using the Deployment Scripts

### PowerShell Script

```powershell
# Navigate to scripts directory
cd Infra_As_Code/scripts

# Deploy a module
.\deploy.ps1 `
  -ResourceGroupName "rg-demo" `
  -Location "eastus" `
  -TemplateFile "../modules/storage/storage-account/main.bicep" `
  -ParameterFile "../modules/storage/storage-account/parameters.json"

# Run in what-if mode first (preview changes)
.\deploy.ps1 `
  -ResourceGroupName "rg-demo" `
  -Location "eastus" `
  -TemplateFile "../modules/storage/storage-account/main.bicep" `
  -ParameterFile "../modules/storage/storage-account/parameters.json" `
  -WhatIf
```

### Validation Script

```powershell
# Validate ALL templates before deployment
.\validate.ps1

# This checks:
# - Bicep syntax errors
# - Linting warnings
# - Parameter issues
```

## Understanding Costs

### Free/Low-Cost Options for Learning

- **Storage Account**: $0.02-0.05/month (Standard_LRS with minimal data)
- **Virtual Network**: Free
- **Network Security Group**: Free
- **Managed Identity**: Free
- **Key Vault**: $0.03/month (secrets only)

### Moderate Cost for Testing

- **Virtual Machine** (B2s): ~$30/month
- **SQL Database** (Basic): ~$5/month
- **AKS** (1 node, B2s): ~$30/month

### Production Cost Examples

- **Web App Scenario**: $400-1,000/month
- **AKS Scenario**: $1,600-2,500/month
- **Enterprise SQL**: $730-5,000/month

### Cost Management Tips

```bash
# Set up budget alerts
az consumption budget create \
  --amount 100 \
  --budget-name "monthly-budget" \
  --category Cost \
  --time-grain Monthly \
  --time-period-start 2024-01-01 \
  --time-period-end 2025-12-31

# Review costs
az consumption usage list --output table
```

## Cleanup Resources

### Delete a Resource Group

```bash
# WARNING: This deletes ALL resources in the group!
az group delete \
  --name rg-quickstart-demo \
  --yes \
  --no-wait
```

### Using the Cleanup Script

```powershell
# Clean up ALL resource groups matching a pattern
.\scripts\cleanup.ps1 -ResourceGroupPrefix "rg-demo-"
```

## Troubleshooting Common Issues

### ❌ "Storage account name already exists"

**Problem**: Storage account names must be globally unique.

**Solution**: Add random characters or use `uniqueString()` function.

```json
"storageAccountName": {
  "value": "mystorageacct${uniqueString(resourceGroup().id)}"
}
```

### ❌ "Location not available"

**Problem**: Not all services are available in all regions.

**Solution**: Check service availability.

```bash
# Check where storage accounts are available
az provider show --namespace Microsoft.Storage --query "resourceTypes[?resourceType=='storageAccounts'].locations"
```

### ❌ "Quota exceeded"

**Problem**: Subscription limits reached.

**Solution**: Request quota increase or use different region.

```bash
# Check current usage
az vm list-usage --location eastus --output table
```

### ❌ "Access denied"

**Problem**: Insufficient permissions.

**Solution**: Ensure you have Contributor role on the subscription/resource group.

```bash
# Check your role assignments
az role assignment list --assignee <your-email> --output table
```

## Next Steps

### 📚 Learn More

1. **[Module Index](docs/module-index.md)** - Browse all available modules
2. **[Best Practices](docs/best-practices.md)** - Learn Azure IaC patterns
3. **[Deployment Guide](docs/deployment-guide.md)** - Advanced deployment scenarios

### 🏗️ Build Solutions

1. **Combine modules** - Create custom scenarios
2. **Customize parameters** - Fit your requirements
3. **Add monitoring** - Integrate Application Insights
4. **Set up CI/CD** - Use Azure DevOps pipeline

### 🎓 Advanced Topics

1. **Private Endpoints** - Secure network connectivity
2. **Managed Identities** - Passwordless authentication
3. **Multi-Region** - High availability deployments
4. **Disaster Recovery** - Backup and failover strategies

## Getting Help

### Documentation Resources

- **Module READMEs**: Each module has detailed documentation
- **[Troubleshooting Guide](docs/troubleshooting.md)**: Common issues and solutions
- **[SUMMARY.md](SUMMARY.md)**: Complete repository overview

### Azure Resources

- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)

## Quick Reference Commands

### Deployment

```bash
# Create resource group
az group create --name <rg-name> --location <location>

# Deploy template
az deployment group create \
  --resource-group <rg-name> \
  --template-file main.bicep \
  --parameters parameters.json

# Deploy with inline parameters
az deployment group create \
  --resource-group <rg-name> \
  --template-file main.bicep \
  --parameters storageAccountName=myaccount123 location=eastus
```

### Validation

```bash
# Validate template
az deployment group validate \
  --resource-group <rg-name> \
  --template-file main.bicep \
  --parameters parameters.json

# Preview changes (what-if)
az deployment group what-if \
  --resource-group <rg-name> \
  --template-file main.bicep \
  --parameters parameters.json
```

### Monitoring

```bash
# Watch deployment progress
az deployment group show \
  --resource-group <rg-name> \
  --name <deployment-name>

# Get deployment outputs
az deployment group show \
  --resource-group <rg-name> \
  --name <deployment-name> \
  --query properties.outputs
```

---

## 🎯 Your First 30 Minutes

**Minutes 0-5**: Deploy storage account (above)  
**Minutes 5-10**: Review the deployed resources in Azure Portal  
**Minutes 10-15**: Explore the storage account README  
**Minutes 15-20**: Try deploying a Virtual Network  
**Minutes 20-25**: Combine VNet and Storage in one deployment  
**Minutes 25-30**: Review cost estimates and clean up resources

**Congratulations! You're now ready to use this repository effectively!** 🚀

---

**Created by**: Shaun Hardneck  
**Website**: [thatlazyadmin.com](https://thatlazyadmin.com)
