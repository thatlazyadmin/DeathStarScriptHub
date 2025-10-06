# Azure Managed Identity Module

Create user-assigned managed identities for secure authentication to Azure resources.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Features

- User-assigned managed identity creation
- No credential management required
- Works with Azure AD authentication
- Can be assigned to multiple resources
- Supports RBAC role assignments

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `managedIdentityName` | string | Managed Identity name | Required |
| `location` | string | Azure region | `resourceGroup().location` |
| `tags` | object | Resource tags | `{}` |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `managedIdentityName` | string | Managed Identity name |
| `managedIdentityId` | string | Managed Identity resource ID |
| `principalId` | string | Service Principal ID (for role assignments) |
| `clientId` | string | Client ID (for authentication) |
| `tenantId` | string | Azure AD tenant ID |

## Usage

### Basic Deployment

```bash
az deployment group create \
  --resource-group rg-security-prod \
  --template-file main.bicep \
  --parameters managedIdentityName=id-myapp-prod
```

### PowerShell Deployment

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-security-prod" `
  -TemplateFile "main.bicep" `
  -managedIdentityName "id-myapp-prod"
```

### Complete Example with Role Assignments

```bicep
// Create managed identity
module managedIdentity 'modules/security/managed-identity/main.bicep' = {
  name: 'managedIdentity'
  params: {
    managedIdentityName: 'id-myapp-prod'
    location: 'eastus'
    tags: {
      Environment: 'Production'
      Application: 'MyApp'
    }
  }
}

// Assign Key Vault Secrets User role
resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.outputs.principalId, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: managedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign Storage Blob Data Contributor role
resource storageBlobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.outputs.principalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: managedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Attach to App Service
module appService 'modules/compute/app-service/main.bicep' = {
  name: 'appService'
  params: {
    appServiceName: 'app-myapp-prod'
    managedIdentityId: managedIdentity.outputs.managedIdentityId
  }
}
```

### Using with Azure Functions

```bicep
module managedIdentity 'modules/security/managed-identity/main.bicep' = {
  name: 'managedIdentity'
  params: {
    managedIdentityName: 'id-function-prod'
    location: location
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'func-myapp-prod'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.outputs.managedIdentityId}': {}
    }
  }
  properties: {
    // ... other properties
    keyVaultReferenceIdentity: managedIdentity.outputs.managedIdentityId
  }
}
```

### Using with Virtual Machine

```bicep
module managedIdentity 'modules/security/managed-identity/main.bicep' = {
  name: 'managedIdentity'
  params: {
    managedIdentityName: 'id-vm-prod'
    location: location
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-myapp-prod'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.outputs.managedIdentityId}': {}
    }
  }
  properties: {
    // ... other properties
  }
}
```

## Common Role Assignments

| Role | Role ID | Use Case |
|------|---------|----------|
| Key Vault Secrets User | `4633458b-17de-408a-b874-0445c86b69e6` | Read secrets from Key Vault |
| Storage Blob Data Reader | `2a2b9908-6ea1-4ae2-8e65-a410df84e7d1` | Read blob data |
| Storage Blob Data Contributor | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` | Read/write blob data |
| Storage Queue Data Reader | `19e7f393-937e-4f77-808e-94535e297925` | Read queue messages |
| Storage Queue Data Contributor | `974c5e8b-45b9-4653-ba55-5f855dd0fb88` | Read/write queue messages |
| SQL DB Contributor | `9b7fa17d-e63e-47b0-bb0a-15c516ac86ec` | Manage SQL databases |
| Cosmos DB Account Reader | `fbdf93bf-df7d-467e-a4d2-9458aa1360c8` | Read Cosmos DB data |
| AcrPull | `7f951dda-4ed3-4680-a7ca-43fe172d538d` | Pull container images |
| Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` | Full management access |
| Reader | `acdd72a7-3385-48ef-bd42-f606fba81ae7` | Read-only access |

## Authentication in Application Code

### .NET Example

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var credential = new DefaultAzureCredential();
var client = new SecretClient(
    new Uri("https://kv-myapp-prod.vault.azure.net/"),
    credential
);

var secret = await client.GetSecretAsync("DatabasePassword");
```

### Python Example

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(
    vault_url="https://kv-myapp-prod.vault.azure.net/",
    credential=credential
)

secret = client.get_secret("DatabasePassword")
```

### JavaScript/Node.js Example

```javascript
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const credential = new DefaultAzureCredential();
const client = new SecretClient(
  'https://kv-myapp-prod.vault.azure.net/',
  credential
);

const secret = await client.getSecret('DatabasePassword');
```

## Best Practices

1. **Use User-Assigned Over System-Assigned**: Allows reuse across multiple resources
2. **Principle of Least Privilege**: Grant only required permissions
3. **Separate Identities**: Use different identities for dev/staging/prod
4. **Resource Naming**: Use consistent naming (e.g., `id-{app}-{env}`)
5. **Documentation**: Document which identity has access to what
6. **Monitoring**: Track identity usage with Azure Monitor
7. **Lifecycle Management**: Remove unused identities

## Troubleshooting

### Check Identity Details

```bash
az identity show \
  --resource-group rg-security-prod \
  --name id-myapp-prod
```

### List Role Assignments

```bash
az role assignment list \
  --assignee <principal-id> \
  --all
```

### Test Access from VM/App

```bash
# Get access token (from within the VM/App)
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' \
  -H Metadata:true
```

## Related Resources

- [Managed Identities Documentation](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Azure RBAC Roles](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Best Practices](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/managed-identity-best-practice-recommendations)
