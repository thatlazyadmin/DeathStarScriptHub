# Azure Key Vault Module

Deploy Azure Key Vault with enterprise security and compliance features.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Features

- Soft delete and purge protection
- RBAC-based access control
- Network security with firewall rules
- VNet integration support
- Private endpoint ready
- Diagnostic logging
- Azure Policy integration
- Template deployment enabled

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `keyVaultName` | string | Key Vault name (globally unique, 3-24 chars) | Required |
| `location` | string | Azure region | `resourceGroup().location` |
| `skuName` | string | SKU (standard/premium) | `standard` |
| `enableSoftDelete` | bool | Enable soft delete | `true` |
| `softDeleteRetentionInDays` | int | Soft delete retention (7-90 days) | `90` |
| `enablePurgeProtection` | bool | Enable purge protection | `true` |
| `enableRbacAuthorization` | bool | Use RBAC instead of access policies | `true` |
| `publicNetworkAccess` | string | Public network access (Enabled/Disabled) | `Enabled` |
| `networkAclsDefaultAction` | string | Default network action (Allow/Deny) | `Deny` |
| `ipRules` | array | IP firewall rules | `[]` |
| `virtualNetworkRules` | array | VNet subnet IDs | `[]` |
| `enableAzureServicesBypass` | bool | Allow trusted Azure services | `true` |
| `tenantId` | string | Azure AD tenant ID | `subscription().tenantId` |
| `enableDiagnostics` | bool | Enable diagnostic settings | `true` |
| `logAnalyticsWorkspaceId` | string | Log Analytics workspace ID | `''` |
| `tags` | object | Resource tags | `{}` |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `keyVaultName` | string | Key Vault name |
| `keyVaultId` | string | Key Vault resource ID |
| `keyVaultUri` | string | Key Vault URI |

## Usage

### Basic Deployment

```bash
az deployment group create \
  --resource-group rg-security-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

### PowerShell Deployment

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-security-prod" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.json"
```

### Production Configuration with RBAC

```bicep
module keyVault 'modules/security/key-vault/main.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: 'kv-myapp-prod'
    location: 'eastus'
    skuName: 'premium'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    networkAclsDefaultAction: 'Deny'
    virtualNetworkRules: [
      subnet.id
    ]
    enableDiagnostics: true
    logAnalyticsWorkspaceId: logAnalytics.id
    tags: {
      Environment: 'Production'
      Compliance: 'PCI-DSS'
    }
  }
}

// Grant Key Vault Secrets Officer role to managed identity
resource secretsOfficerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.outputs.keyVaultId, managedIdentity.id, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: resourceId('Microsoft.KeyVault/vaults', keyVault.outputs.keyVaultName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### Storing Secrets

```bash
# Add a secret to Key Vault
az keyvault secret set \
  --vault-name kv-myapp-prod \
  --name "DatabasePassword" \
  --value "ComplexP@ssw0rd123!"

# Reference secret in Bicep
param sqlPassword string = az.keyvault('kv-myapp-prod', 'DatabasePassword')
```

### With Private Endpoint

```bicep
module keyVault 'modules/security/key-vault/main.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: 'kv-myapp-prod'
    publicNetworkAccess: 'Disabled'
    networkAclsDefaultAction: 'Deny'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-keyvault'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault-connection'
        properties: {
          privateLinkServiceId: keyVault.outputs.keyVaultId
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}
```

## RBAC Roles

When using RBAC authorization, assign these built-in roles:

| Role | Role ID | Purpose |
|------|---------|---------|
| Key Vault Administrator | `00482a5a-887f-4fb3-b975-3cba7e825d70` | Full access to all Key Vault resources |
| Key Vault Secrets Officer | `b86a8fe4-44ce-4948-aee5-eccb2c155cd7` | Manage secrets |
| Key Vault Secrets User | `4633458b-17de-408a-b874-0445c86b69e6` | Read secrets |
| Key Vault Crypto Officer | `14b46e9e-c2b7-41b4-b07b-48a6ebf60603` | Manage keys |
| Key Vault Crypto User | `12338af0-0e69-4776-bea7-57ae8d297424` | Perform cryptographic operations |
| Key Vault Certificates Officer | `a4417e6f-fecd-4de8-b567-7b0420556985` | Manage certificates |

## Security Best Practices

1. **Enable Purge Protection**: Prevents accidental permanent deletion
2. **Use RBAC**: More granular than access policies
3. **Network Isolation**: Use private endpoints for production
4. **Soft Delete**: Always enable with 90-day retention
5. **Monitoring**: Enable diagnostic logs to Log Analytics
6. **Managed Identities**: Use instead of service principals
7. **Firewall**: Configure IP allowlist and VNet rules
8. **Premium SKU**: Use for HSM-backed keys (compliance)

## Troubleshooting

### Access Denied Errors

```bash
# Check your permissions
az role assignment list \
  --assignee <your-object-id> \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv-name>
```

### List Secrets

```bash
# List all secrets
az keyvault secret list \
  --vault-name kv-myapp-prod
```

### Recover Deleted Key Vault

```bash
# List deleted vaults
az keyvault list-deleted

# Recover deleted vault
az keyvault recover \
  --name kv-myapp-prod
```

### Purge Deleted Key Vault

```bash
# Permanently delete (requires purge protection disabled)
az keyvault purge \
  --name kv-myapp-prod
```

## Related Resources

- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Key Vault Security](https://docs.microsoft.com/azure/key-vault/general/security-features)
- [Key Vault Best Practices](https://docs.microsoft.com/azure/key-vault/general/best-practices)
- [RBAC for Key Vault](https://docs.microsoft.com/azure/key-vault/general/rbac-guide)
