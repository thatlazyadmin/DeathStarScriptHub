# Module Template

Use this template when creating new Bicep modules for this repository.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Creating a New Module

### 1. Create Module Directory

```bash
# Choose appropriate category: compute, storage, network, database, security
mkdir -p modules/{category}/{module-name}
cd modules/{category}/{module-name}
```

### 2. Create main.bicep

```bicep
// =========================================================================================================
// Azure {Resource Type} Module
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
// Description: Deploys {brief description of what this module does}
// =========================================================================================================

@description('{Resource} name')
param resourceName string

@description('Location for the {resource}')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

// Add more parameters as needed
@description('SKU name')
@allowed([
  'Standard'
  'Premium'
])
param skuName string = 'Standard'

// Main resource definition
resource mainResource 'Microsoft.{Provider}/{ResourceType}@2023-XX-XX' = {
  name: resourceName
  location: location
  tags: union(tags, {
    CreatedBy: 'Shaun Hardneck'
    Website: 'thatlazyadmin.com'
  })
  properties: {
    // Resource-specific properties
  }
}

// Optional: Additional resources (diagnostic settings, role assignments, etc.)
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostics'
  scope: mainResource
  properties: {
    // Diagnostic properties
  }
}

// Outputs
@description('{Resource} name')
output resourceName string = mainResource.name

@description('{Resource} resource ID')
output resourceId string = mainResource.id

// Add more outputs as needed
```

### 3. Create parameters.json

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "resourceName": {
      "value": "{resource-name}"
    },
    "location": {
      "value": "eastus"
    },
    "skuName": {
      "value": "Standard"
    },
    "tags": {
      "value": {
        "Environment": "Production",
        "ManagedBy": "IaC",
        "CreatedBy": "Shaun Hardneck",
        "Website": "thatlazyadmin.com"
      }
    }
  }
}
```

### 4. Create README.md

````markdown
# Azure {Resource Type} Module

{Brief description of what this module deploys}

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Features

- {Feature 1}
- {Feature 2}
- {Feature 3}
- Security best practices
- Diagnostic logging
- RBAC support

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `resourceName` | string | {Resource} name | Required |
| `location` | string | Azure region | `resourceGroup().location` |
| `skuName` | string | SKU (Standard/Premium) | `Standard` |
| `tags` | object | Resource tags | `{}` |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `resourceName` | string | {Resource} name |
| `resourceId` | string | {Resource} resource ID |

## Usage

### Basic Deployment

```bash
az deployment group create \
  --resource-group rg-{resource}-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

### PowerShell Deployment

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-{resource}-prod" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.json"
```

### Example with Custom Parameters

```bicep
module myResource 'modules/{category}/{module-name}/main.bicep' = {
  name: '{resource}-deployment'
  params: {
    resourceName: '{resource-name}'
    location: 'eastus'
    skuName: 'Premium'
    tags: {
      Environment: 'Production'
      Application: 'MyApp'
    }
  }
}
```

## Security Best Practices

1. **{Practice 1}**: {Description}
2. **{Practice 2}**: {Description}
3. **{Practice 3}**: {Description}
4. **Monitoring**: Enable diagnostic logs
5. **RBAC**: Use least-privilege access

## Troubleshooting

### {Common Issue 1}

```bash
# {Troubleshooting command}
az {command} show \
  --resource-group <resource-group> \
  --name <resource-name>
```

### {Common Issue 2}

```bash
# {Troubleshooting command}
az {command} list \
  --resource-group <resource-group>
```

## Cost Estimation

### Development

- **{Configuration}**: ~${cost}/month

### Production

- **{Configuration}**: ~${cost}/month

## Related Resources

- [{Resource} Documentation](https://docs.microsoft.com/azure/{service}/)
- [{Resource} Best Practices](https://docs.microsoft.com/azure/{service}/best-practices)
- [{Resource} Pricing](https://azure.microsoft.com/pricing/details/{service}/)

---

**Created by**: Shaun Hardneck  
**Website**: [thatlazyadmin.com](https://thatlazyadmin.com)
````

## Module Checklist

Use this checklist when creating a new module:

### Structure

- [ ] Directory created in appropriate category
- [ ] `main.bicep` file created
- [ ] `parameters.json` file created
- [ ] `README.md` file created

### Bicep Template

- [ ] Header comment with branding
- [ ] Parameter descriptions (`@description`)
- [ ] Parameter validation (`@allowed`, `@minLength`, etc.)
- [ ] Default values where appropriate
- [ ] Latest stable API version
- [ ] Proper resource naming
- [ ] Tags with branding
- [ ] Outputs documented
- [ ] Diagnostic settings (where applicable)
- [ ] Security best practices implemented

### Parameters File

- [ ] Correct schema
- [ ] All required parameters
- [ ] Example values
- [ ] Tags with branding
- [ ] Comments for clarity

### Documentation

- [ ] Title and description
- [ ] Branding header
- [ ] Features list
- [ ] Parameters table
- [ ] Outputs table
- [ ] Usage examples (bash and PowerShell)
- [ ] Advanced examples
- [ ] Security best practices section
- [ ] Troubleshooting section
- [ ] Cost estimates
- [ ] Related resources links
- [ ] Branding footer

### Testing

- [ ] Template validates without errors
- [ ] Bicep linting passes
- [ ] Parameters are valid
- [ ] What-if deployment reviewed
- [ ] Actual deployment tested
- [ ] Outputs verified

### Quality

- [ ] Follows naming conventions
- [ ] Consistent with other modules
- [ ] Comprehensive documentation
- [ ] Security-first design
- [ ] Production-ready defaults

## Example Module Categories

### Compute

- App Service / App Service Plan
- Container Apps
- Azure Functions
- Virtual Machine Scale Sets
- Batch Accounts

### Storage

- Storage Account (✅ Complete)
- File Share (✅ Complete)
- Disk Encryption Set
- NetApp Files

### Network

- Virtual Network (✅ Complete)
- Network Security Group (✅ Complete)
- Application Gateway
- Azure Firewall
- Load Balancer
- Private DNS Zone
- VPN Gateway

### Database

- SQL Database (✅ Complete)
- Cosmos DB (✅ Complete)
- PostgreSQL
- MySQL
- Redis Cache

### Security

- Key Vault (✅ Complete)
- Managed Identity (✅ Complete)
- Private Endpoint
- DDoS Protection Plan

### Monitoring

- Log Analytics Workspace
- Application Insights
- Action Groups
- Alert Rules

### Integration

- Service Bus
- Event Grid
- Event Hubs
- API Management

## Best Practices for New Modules

### 1. Security First

Always implement:

- Encryption at rest and in transit
- HTTPS/TLS enforcement
- Managed Identity support
- RBAC integration
- Private endpoint readiness
- Network security
- Diagnostic logging

### 2. Production Ready

Include:

- High availability options
- Backup configurations
- Disaster recovery considerations
- Monitoring and alerting
- Auto-scaling (where applicable)

### 3. Parameter Design

- Provide sensible defaults
- Use `@allowed` for restricted values
- Validate inputs (`@minLength`, `@maxLength`)
- Document each parameter
- Support environment-specific configs

### 4. Output Design

Export:

- Resource name
- Resource ID
- Connection information
- URLs/endpoints
- Identity principal IDs

### 5. Documentation

Include:

- Clear description
- All features listed
- Multiple usage examples
- Security guidance
- Troubleshooting steps
- Cost transparency

## Naming Conventions

### Resource Naming

Follow Azure naming conventions:

- Storage Account: `st{app}{env}{unique}`
- Virtual Machine: `vm-{app}-{env}-{instance}`
- SQL Server: `sql-{app}-{env}-{unique}`
- AKS: `aks-{app}-{env}-{unique}`
- VNet: `vnet-{app}-{env}-{region}`
- Key Vault: `kv-{app}{env}{unique}` (max 24 chars)

### Parameter Naming

Use camelCase:

- `resourceName`
- `skuName`
- `enableDiagnostics`
- `logAnalyticsWorkspaceId`

### Output Naming

Use descriptive camelCase:

- `resourceName`
- `resourceId`
- `connectionString`
- `primaryKey`

## Testing New Modules

### 1. Validation Test

```bash
az deployment group validate \
  --resource-group test-rg \
  --template-file main.bicep \
  --parameters parameters.json
```

### 2. What-If Test

```bash
az deployment group what-if \
  --resource-group test-rg \
  --template-file main.bicep \
  --parameters parameters.json
```

### 3. Deployment Test

```bash
# Deploy to dev environment first
az deployment group create \
  --resource-group test-rg \
  --template-file main.bicep \
  --parameters parameters.json
```

### 4. Verification Test

```bash
# Verify resource was created
az resource show \
  --resource-group test-rg \
  --name {resource-name} \
  --resource-type Microsoft.{Provider}/{ResourceType}
```

### 5. Cleanup Test

```bash
# Clean up test resources
az group delete --name test-rg --yes --no-wait
```

## Publishing Checklist

Before committing a new module:

- [ ] All files created and complete
- [ ] Bicep template validates
- [ ] Parameters file is correct
- [ ] README is comprehensive
- [ ] Security best practices implemented
- [ ] Branding applied throughout
- [ ] Module tested in dev environment
- [ ] Documentation reviewed
- [ ] Examples work as documented
- [ ] Troubleshooting section helpful

---

**Created by**: Shaun Hardneck  
**Website**: [thatlazyadmin.com](https://thatlazyadmin.com)
