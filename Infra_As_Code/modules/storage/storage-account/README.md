# Storage Account Module

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This module deploys an Azure Storage Account with security best practices and optional diagnostic settings.

## Features

- ✅ Secure by default (HTTPS only, TLS 1.2+)
- ✅ Network ACLs configured (deny by default)
- ✅ Encryption at rest enabled
- ✅ Diagnostic settings support
- ✅ Flexible SKU and kind options
- ✅ Data Lake Gen2 support

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `storageAccountName` | string | Yes | - | Globally unique storage account name |
| `location` | string | No | resourceGroup().location | Azure region |
| `skuName` | string | No | Standard_LRS | Storage account SKU |
| `kind` | string | No | StorageV2 | Storage account kind |
| `enableHierarchicalNamespace` | bool | No | false | Enable Data Lake Gen2 |
| `supportsHttpsTrafficOnly` | bool | No | true | Enforce HTTPS only |
| `minimumTlsVersion` | string | No | TLS1_2 | Minimum TLS version |
| `allowBlobPublicAccess` | bool | No | false | Allow public blob access |
| `tags` | object | No | {} | Resource tags |
| `enableDiagnostics` | bool | No | true | Enable diagnostic logs |
| `logAnalyticsWorkspaceId` | string | No | '' | Log Analytics workspace ID |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `storageAccountId` | string | Storage account resource ID |
| `storageAccountName` | string | Storage account name |
| `primaryEndpoints` | object | All primary endpoints |
| `primaryBlobEndpoint` | string | Primary blob endpoint |

## Usage

### Basic Deployment

```bash
az deployment group create \
  --resource-group rg-storage \
  --template-file main.bicep \
  --parameters storageAccountName=stmyuniquestorage
```

### With Parameters File

```bash
az deployment group create \
  --resource-group rg-storage \
  --template-file main.bicep \
  --parameters @parameters.json
```

### PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-storage" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.json"
```

## Examples

### Standard Storage Account

```bicep
module storage 'main.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: 'stprod001'
    skuName: 'Standard_GRS'
    tags: {
      Environment: 'Production'
    }
  }
}
```

### Premium Storage with Data Lake Gen2

```bicep
module storage 'main.bicep' = {
  name: 'dataLakeDeployment'
  params: {
    storageAccountName: 'stdatalake001'
    skuName: 'Premium_LRS'
    kind: 'BlockBlobStorage'
    enableHierarchicalNamespace: true
  }
}
```

## Security Considerations

- Network ACLs default to **Deny** with Azure Services bypass
- Public blob access disabled by default
- Minimum TLS version set to 1.2
- HTTPS traffic enforced
- Encryption at rest enabled automatically

## Best Practices

1. Use **Standard_ZRS** or **Standard_GRS** for production workloads
2. Enable diagnostic settings for monitoring
3. Use private endpoints for enhanced security
4. Implement Azure Policy for compliance
5. Enable soft delete for blobs and containers

## Related Modules

- [File Share](../file-share/README.md)
- [Key Vault](../../security/key-vault/README.md)

## Author

**Shaun Hardneck**  
[thatlazyadmin.com](https://thatlazyadmin.com)
