# Azure File Share Module

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This module deploys an Azure File Share with SMB or NFS protocol support on an existing storage account.

## Features

- ✅ SMB and NFS protocol support
- ✅ Configurable access tiers
- ✅ Soft delete enabled (7-day retention)
- ✅ Flexible quota management
- ✅ Metadata tagging support

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `storageAccountName` | string | Yes | - | Parent storage account name |
| `fileShareName` | string | Yes | - | File share name |
| `accessTier` | string | No | TransactionOptimized | Access tier |
| `shareQuota` | int | No | 100 | Share quota in GB (1-102400) |
| `enabledProtocol` | string | No | SMB | Protocol (SMB or NFS) |
| `tags` | object | No | {} | Resource tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `fileShareId` | string | File share resource ID |
| `fileShareName` | string | File share name |
| `fileShareUrl` | string | File share URL |

## Usage

```bash
az deployment group create \
  --resource-group rg-storage \
  --template-file main.bicep \
  --parameters storageAccountName=stmystorage fileShareName=myshare
```

## Examples

### SMB File Share

```bicep
module fileShare 'main.bicep' = {
  name: 'smbFileShareDeployment'
  params: {
    storageAccountName: 'stprod001'
    fileShareName: 'fs-shared-docs'
    accessTier: 'Hot'
    shareQuota: 500
    enabledProtocol: 'SMB'
  }
}
```

### NFS File Share

```bicep
module fileShare 'main.bicep' = {
  name: 'nfsFileShareDeployment'
  params: {
    storageAccountName: 'stprod001'
    fileShareName: 'fs-nfs-data'
    accessTier: 'Premium'
    shareQuota: 1024
    enabledProtocol: 'NFS'
  }
}
```

## Author

**Shaun Hardneck**  
[thatlazyadmin.com](https://thatlazyadmin.com)
