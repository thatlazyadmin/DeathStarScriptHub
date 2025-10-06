# Azure SQL Database Module

Deploy Azure SQL Database with enterprise-grade security and monitoring.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Features

- Azure SQL Server and Database deployment
- Azure AD authentication support
- Advanced Threat Protection
- Transparent Data Encryption (TDE)
- Auditing to Log Analytics
- Firewall rules configuration
- Private endpoint support
- Automated backups with configurable retention

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `serverName` | string | SQL Server name (must be globally unique) | Required |
| `databaseName` | string | SQL Database name | Required |
| `location` | string | Azure region | `resourceGroup().location` |
| `administratorLogin` | string | SQL Server admin username | Required |
| `administratorLoginPassword` | securestring | SQL Server admin password | Required |
| `skuName` | string | Database SKU name | `GP_Gen5_2` |
| `skuTier` | string | Database SKU tier | `GeneralPurpose` |
| `maxSizeBytes` | int | Max database size in bytes | `34359738368` (32GB) |
| `enableAzureADOnly` | bool | Enable Azure AD only authentication | `false` |
| `azureADAdminObjectId` | string | Azure AD admin object ID | `''` |
| `azureADAdminLogin` | string | Azure AD admin login name | `''` |
| `enableAdvancedThreatProtection` | bool | Enable Advanced Threat Protection | `true` |
| `enableAuditingToLogAnalytics` | bool | Enable auditing to Log Analytics | `true` |
| `logAnalyticsWorkspaceId` | string | Log Analytics workspace resource ID | `''` |
| `allowAzureIPs` | bool | Allow Azure services to access server | `true` |
| `tags` | object | Resource tags | `{}` |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `serverName` | string | SQL Server name |
| `serverId` | string | SQL Server resource ID |
| `databaseName` | string | SQL Database name |
| `databaseId` | string | SQL Database resource ID |
| `serverFqdn` | string | SQL Server fully qualified domain name |

## Usage

### Basic Deployment

```bash
az deployment group create \
  --resource-group rg-sql-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

### PowerShell Deployment

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-sql-prod" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.json"
```

### Example with Azure AD Authentication

```bicep
module sqlDatabase 'modules/database/sql-database/main.bicep' = {
  name: 'sqlDatabase'
  params: {
    serverName: 'sql-myapp-prod'
    databaseName: 'sqldb-myapp'
    location: 'eastus'
    administratorLogin: 'sqladmin'
    administratorLoginPassword: sqlAdminPassword
    enableAzureADOnly: true
    azureADAdminObjectId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    azureADAdminLogin: 'admin@contoso.com'
    enableAdvancedThreatProtection: true
    enableAuditingToLogAnalytics: true
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    tags: {
      Environment: 'Production'
      Application: 'MyApp'
    }
  }
}
```

## Security Best Practices

1. **Password Management**: Store admin password in Azure Key Vault
2. **Azure AD Authentication**: Enable Azure AD authentication and consider AD-only mode
3. **Firewall Rules**: Configure minimal required firewall rules
4. **Private Endpoints**: Use private endpoints for enhanced network security
5. **Encryption**: TDE is enabled by default, consider customer-managed keys
6. **Threat Protection**: Enable Advanced Threat Protection for security alerts
7. **Auditing**: Enable auditing to Log Analytics for compliance
8. **Backup**: Configure backup retention based on compliance requirements

## SKU Options

### General Purpose (GP)

- **GP_Gen5_2**: 2 vCores, 10.4 GB RAM
- **GP_Gen5_4**: 4 vCores, 20.8 GB RAM
- **GP_Gen5_8**: 8 vCores, 41.6 GB RAM

### Business Critical (BC)

- **BC_Gen5_2**: 2 vCores, 10.4 GB RAM, local SSD
- **BC_Gen5_4**: 4 vCores, 20.8 GB RAM, local SSD
- **BC_Gen5_8**: 8 vCores, 41.6 GB RAM, local SSD

### Hyperscale

- **HS_Gen5_2**: 2 vCores, highly scalable storage
- **HS_Gen5_4**: 4 vCores, highly scalable storage

## Troubleshooting

### Connection Issues

```bash
# Test SQL Server connectivity
Test-NetConnection -ComputerName <server-name>.database.windows.net -Port 1433
```

### Check Firewall Rules

```bash
az sql server firewall-rule list \
  --resource-group <resource-group> \
  --server <server-name>
```

### View Database Details

```bash
az sql db show \
  --resource-group <resource-group> \
  --server <server-name> \
  --name <database-name>
```

## Related Resources

- [Azure SQL Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [SQL Database Security](https://docs.microsoft.com/azure/azure-sql/database/security-overview)
- [SQL Database Pricing](https://azure.microsoft.com/pricing/details/sql-database/)
