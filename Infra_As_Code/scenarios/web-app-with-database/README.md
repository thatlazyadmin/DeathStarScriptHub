# Web Application with Database Scenario

Complete infrastructure for a production-ready web application with database backend.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Architecture

This scenario deploys:

1. **Compute**: App Service (to be added) with managed identity
2. **Database**: Azure SQL Database with Advanced Threat Protection
3. **Security**: Key Vault for secrets, Managed Identity for authentication
4. **Storage**: Storage Account for static content and files
5. **Network**: Virtual Network with service endpoints
6. **Monitoring**: Diagnostic logging (to be enhanced)

## Components

### Security Layer

- **Managed Identity**: User-assigned identity for all Azure resource authentication
- **Key Vault**: Stores database passwords and connection strings
- **RBAC**: Least-privilege access with built-in roles

### Network Layer

- **Virtual Network**: Isolated network (10.0.0.0/16)
- **App Subnet**: For App Service VNet integration (10.0.1.0/24)
- **Data Subnet**: For database private endpoints (10.0.2.0/24)
- **Service Endpoints**: Enabled for SQL, Storage, Key Vault

### Data Layer

- **SQL Database**: General Purpose tier with auto-scaling
- **Storage Account**: Geo-redundant storage for production
- **Backup**: Automated SQL backups with point-in-time restore

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `environmentName` | string | Environment (dev/staging/prod) |
| `applicationName` | string | Application name (3-10 chars) |
| `location` | string | Azure region |
| `sqlAdminUsername` | string | SQL admin username |
| `sqlAdminPassword` | securestring | SQL admin password |
| `tags` | object | Additional resource tags |

## Deployment

### Using Azure CLI

```bash
# Create resource group
az group create \
  --name rg-mywebapp-prod \
  --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group rg-mywebapp-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json
```

### Using PowerShell

```powershell
# Create resource group
New-AzResourceGroup `
  -Name "rg-mywebapp-prod" `
  -Location "eastus"

# Deploy infrastructure
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-mywebapp-prod" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.prod.json"
```

### Using Azure DevOps Pipeline

```yaml
- task: AzureCLI@2
  displayName: 'Deploy Web App Infrastructure'
  inputs:
    azureSubscription: 'Azure-ServiceConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az deployment group create \
        --resource-group $(resourceGroup) \
        --template-file scenarios/web-app-with-database/main.bicep \
        --parameters scenarios/web-app-with-database/parameters.$(environment).json \
        --parameters sqlAdminPassword=$(sqlAdminPassword)
```

## Post-Deployment Steps

### 1. Store SQL Password in Key Vault

```bash
# Get Key Vault name from deployment output
KV_NAME=$(az deployment group show \
  --resource-group rg-mywebapp-prod \
  --name main \
  --query properties.outputs.keyVaultUri.value -o tsv | cut -d'/' -f3 | cut -d'.' -f1)

# Store SQL connection string
SQL_CONN_STRING="Server=tcp:$(az deployment group show --resource-group rg-mywebapp-prod --name main --query properties.outputs.sqlServerFqdn.value -o tsv),1433;Database=$(az deployment group show --resource-group rg-mywebapp-prod --name main --query properties.outputs.sqlDatabaseName.value -o tsv);User ID=sqladmin;Password={your-password};Encrypt=true;"

az keyvault secret set \
  --vault-name $KV_NAME \
  --name "SqlConnectionString" \
  --value "$SQL_CONN_STRING"
```

### 2. Configure Application Settings

```bash
# For App Service (when added)
az webapp config appsettings set \
  --resource-group rg-mywebapp-prod \
  --name app-mywebapp-prod \
  --settings \
    "SqlConnectionString=@Microsoft.KeyVault(SecretUri=https://${KV_NAME}.vault.azure.net/secrets/SqlConnectionString/)" \
    "StorageAccountName=$(az deployment group show --resource-group rg-mywebapp-prod --name main --query properties.outputs.storageAccountName.value -o tsv)"
```

### 3. Initialize Database Schema

```bash
# Connect to SQL Database
sqlcmd -S <sql-server-fqdn> -d <database-name> -U sqladmin -P <password> -i schema.sql
```

## Application Configuration

### Connection String Reference (from Key Vault)

```csharp
// .NET Example
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var credential = new DefaultAzureCredential();
var client = new SecretClient(new Uri(keyVaultUri), credential);
var secret = await client.GetSecretAsync("SqlConnectionString");
string connectionString = secret.Value.Value;
```

### Environment-Specific Settings

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| SQL SKU | GP_Gen5_2 | GP_Gen5_2 | GP_Gen5_4 |
| Storage SKU | Standard_LRS | Standard_LRS | Standard_GRS |
| Key Vault SKU | Standard | Standard | Premium |
| Purge Protection | Disabled | Disabled | Enabled |
| Public Network | Enabled | Enabled | Disabled (recommended) |

## Cost Estimation

### Production Environment (Monthly)

- **SQL Database** (GP_Gen5_4): ~$730
- **App Service** (P1v3): ~$200
- **Storage** (100GB GRS): ~$5
- **Key Vault**: ~$0.03
- **VNet**: Free
- **Total**: ~$935/month

### Development Environment (Monthly)

- **SQL Database** (GP_Gen5_2): ~$365
- **App Service** (B1): ~$13
- **Storage** (10GB LRS): ~$0.50
- **Key Vault**: ~$0.03
- **Total**: ~$380/month

## Security Checklist

- [x] Managed Identity for Azure resource authentication
- [x] Key Vault for secret storage
- [x] SQL Advanced Threat Protection enabled
- [x] HTTPS-only storage access
- [x] TLS 1.2 minimum
- [x] Service endpoints on subnets
- [ ] Private endpoints for production (recommended)
- [ ] Azure AD authentication for SQL (recommended)
- [ ] Network Security Groups (to be added)
- [ ] Application Gateway with WAF (to be added)

## Monitoring and Alerts

### Recommended Alerts

```bash
# SQL DTU usage
az monitor metrics alert create \
  --name "SQL High DTU" \
  --resource-group rg-mywebapp-prod \
  --scopes <sql-database-id> \
  --condition "avg cpu_percent > 80" \
  --window-size 5m \
  --evaluation-frequency 1m

# Storage capacity
az monitor metrics alert create \
  --name "Storage High Usage" \
  --resource-group rg-mywebapp-prod \
  --scopes <storage-account-id> \
  --condition "avg UsedCapacity > 500GB" \
  --window-size 6h
```

## Troubleshooting

### Can't Connect to SQL Database

```bash
# Check firewall rules
az sql server firewall-rule list \
  --resource-group rg-mywebapp-prod \
  --server sql-mywebapp-prod-xxxxx

# Add your IP
az sql server firewall-rule create \
  --resource-group rg-mywebapp-prod \
  --server sql-mywebapp-prod-xxxxx \
  --name "MyIP" \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>
```

### Key Vault Access Denied

```bash
# Check role assignments
az role assignment list \
  --assignee <managed-identity-principal-id> \
  --scope <key-vault-id>

# Verify RBAC is enabled
az keyvault show \
  --name kv-mywebapp-prod-xxxxx \
  --query properties.enableRbacAuthorization
```

## Next Steps

1. Deploy App Service or Container App
2. Configure CI/CD pipeline
3. Set up Application Insights
4. Configure auto-scaling rules
5. Add Azure Front Door for global distribution
6. Implement backup and disaster recovery

## Related Resources

- [App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [SQL Database Best Practices](https://docs.microsoft.com/azure/azure-sql/database/performance-guidance)
- [Key Vault Integration](https://docs.microsoft.com/azure/app-service/app-service-key-vault-references)
