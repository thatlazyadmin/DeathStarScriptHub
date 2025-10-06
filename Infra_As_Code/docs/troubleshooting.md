# Troubleshooting Guide

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Table of Contents

- [Common Deployment Errors](#common-deployment-errors)
- [Bicep Compilation Errors](#bicep-compilation-errors)
- [Authentication Issues](#authentication-issues)
- [Network Connectivity Issues](#network-connectivity-issues)
- [Resource-Specific Issues](#resource-specific-issues)
- [Performance Issues](#performance-issues)
- [Debugging Tips](#debugging-tips)

## Common Deployment Errors

### Error: Resource Name Already Exists

**Problem:**
```text
Error: The storage account name 'mystorageaccount' is already taken.
```

**Solution:**
- Storage account names must be globally unique
- Change the storage account name to something unique
- Use a naming convention with random suffix

**Example:**
```bicep
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'
```

### Error: Insufficient Permissions

**Problem:**
```text
Error: The client does not have authorization to perform action
```

**Solution:**
1. Verify your account has appropriate RBAC role
2. Required roles:
   - **Contributor** for resource deployment
   - **User Access Administrator** for RBAC assignments
3. Check subscription-level permissions

```bash
# Check your current roles
az role assignment list --assignee <your-email> --output table

# Request access from subscription admin if needed
```

### Error: Quota Exceeded

**Problem:**
```text
Error: Operation could not be completed as it results in exceeding approved quota.
```

**Solution:**
1. Check current quota usage:
```bash
az vm list-usage --location eastus --output table
```

2. Request quota increase:
   - Azure Portal → Support → New Support Request
   - Issue type: Service and subscription limits (quotas)

3. Consider alternative VM sizes or regions

### Error: Parameter Validation Failed

**Problem:**
```text
Error: InvalidTemplate - Deployment template validation failed
```

**Solution:**
1. Validate template before deployment:
```bash
az deployment group validate \
  --resource-group rg-test \
  --template-file main.bicep \
  --parameters @parameters.json
```

2. Check parameter types and constraints
3. Ensure required parameters are provided
4. Verify parameter values meet validation rules

## Bicep Compilation Errors

### Error: Cannot find module

**Problem:**
```text
Error: Unable to load module from file 'modules/vm.bicep'
```

**Solution:**
1. Verify file path is correct (relative to main template)
2. Check file exists
3. Ensure case sensitivity (Linux/macOS)

```bicep
// Correct relative path
module vm './modules/vm.bicep' = {
  name: 'vmDeploy'
  params: { }
}
```

### Error: Circular Dependency

**Problem:**
```text
Error: Found circular reference in modules
```

**Solution:**
1. Review module dependencies
2. Use `dependsOn` carefully
3. Avoid mutual dependencies between resources

```bicep
// Incorrect - circular dependency
resource a 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  dependsOn: [b]
}

resource b 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  dependsOn: [a]
}

// Correct - one-way dependency
resource b 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {}

resource a 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  dependsOn: [b]
}
```

### Error: Parameter Type Mismatch

**Problem:**
```text
Error: Expected value of type 'string' but received value of type 'int'
```

**Solution:**
1. Check parameter types in template
2. Verify parameter file values match expected types
3. Use type conversion functions if needed

```bicep
// Ensure types match
param vmSize string = 'Standard_D2s_v3'  // string
param vmCount int = 2                     // int
param enableBackup bool = true            // bool
```

## Authentication Issues

### Error: Not Logged In

**Problem:**
```text
Error: Please run 'az login' to setup account.
```

**Solution:**
```bash
# Standard login
az login

# Login with specific tenant
az login --tenant <tenant-id>

# Login with service principal
az login --service-principal \
  --username <app-id> \
  --password <password> \
  --tenant <tenant-id>
```

### Error: Token Expired

**Problem:**
```text
Error: The access token expiry UTC time is '...'. Current time is '...'.
```

**Solution:**
```bash
# Re-authenticate
az login

# Or refresh token
az account get-access-token
```

### Error: Wrong Subscription

**Problem:**
Resources deploying to wrong subscription

**Solution:**
```bash
# List subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"

# Verify current subscription
az account show --output table
```

## Network Connectivity Issues

### Error: Cannot Connect to VM

**Problem:**
Cannot SSH/RDP to virtual machine

**Solution:**
1. Check NSG rules:
```bash
az network nsg rule list \
  --resource-group rg-prod \
  --nsg-name nsg-vm \
  --output table
```

2. Verify VM is running:
```bash
az vm get-instance-view \
  --resource-group rg-prod \
  --name vm-web-001 \
  --query instanceView.statuses[1] \
  --output table
```

3. Check if VM has public IP (if expected):
```bash
az vm list-ip-addresses \
  --resource-group rg-prod \
  --name vm-web-001 \
  --output table
```

4. Use Azure Bastion or Serial Console as alternative

### Error: AKS Cluster Unreachable

**Problem:**
Cannot access AKS cluster

**Solution:**
1. Get credentials:
```bash
az aks get-credentials \
  --resource-group rg-aks \
  --name aks-prod-001 \
  --overwrite-existing
```

2. Check cluster status:
```bash
az aks show \
  --resource-group rg-aks \
  --name aks-prod-001 \
  --query provisioningState
```

3. Test connection:
```bash
kubectl get nodes
kubectl cluster-info
```

4. For private clusters, ensure you're on allowed network

## Resource-Specific Issues

### Storage Account Issues

**Problem:** Cannot access storage account

**Solution:**
1. Check network rules:
```bash
az storage account show \
  --name mystorageaccount \
  --query networkRuleSet
```

2. Add your IP to firewall:
```bash
az storage account network-rule add \
  --account-name mystorageaccount \
  --ip-address YOUR_IP_ADDRESS
```

3. Verify authentication method:
```bash
# Use account key
az storage blob list \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --account-key $(az storage account keys list --account-name mystorageaccount --query '[0].value' -o tsv)

# Use Azure AD
az storage blob list \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --auth-mode login
```

### SQL Database Issues

**Problem:** Cannot connect to SQL Database

**Solution:**
1. Check firewall rules:
```bash
az sql server firewall-rule list \
  --resource-group rg-sql \
  --server sqlserver-prod
```

2. Add your IP:
```bash
az sql server firewall-rule create \
  --resource-group rg-sql \
  --server sqlserver-prod \
  --name AllowMyIP \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP
```

3. Verify connection string
4. Check if private endpoint is configured
5. Ensure SQL authentication is enabled (if using SQL auth)

### Key Vault Issues

**Problem:** Cannot access secrets in Key Vault

**Solution:**
1. Check access policies:
```bash
az keyvault show \
  --name kv-prod-001 \
  --query properties.accessPolicies
```

2. Grant yourself access:
```bash
az keyvault set-policy \
  --name kv-prod-001 \
  --upn your-email@domain.com \
  --secret-permissions get list
```

3. Check network restrictions
4. Verify you're using correct identity (user vs service principal)

## Performance Issues

### Slow Deployments

**Problem:** Bicep deployments taking too long

**Solution:**
1. Deploy resources in parallel where possible
2. Avoid unnecessary dependencies
3. Use smaller resource groups
4. Consider batch deployments for large numbers of resources

### VM Performance

**Problem:** Virtual machine running slow

**Solution:**
1. Check VM metrics in Azure Monitor:
```bash
az vm list --resource-group rg-prod --show-details --output table
```

2. Review CPU, memory, disk, and network metrics
3. Consider resizing VM
4. Check for disk throttling (IOPS limits)
5. Enable accelerated networking if supported

## Debugging Tips

### Enable Verbose Logging

```bash
# Azure CLI with debug output
az deployment group create \
  --resource-group rg-test \
  --template-file main.bicep \
  --debug

# PowerShell with verbose output
./scripts/deploy.ps1 -Verbose
```

### View Deployment Operations

```bash
# List deployment operations
az deployment group list \
  --resource-group rg-prod \
  --output table

# Show specific deployment
az deployment group show \
  --resource-group rg-prod \
  --name deploy-20241006

# View deployment operations (detailed)
az deployment operation group list \
  --resource-group rg-prod \
  --name deploy-20241006 \
  --output table
```

### Check Activity Log

```bash
# View activity log
az monitor activity-log list \
  --resource-group rg-prod \
  --start-time 2024-10-06T00:00:00Z \
  --output table

# Filter by specific resource
az monitor activity-log list \
  --resource-id /subscriptions/.../resourceGroups/rg-prod/providers/Microsoft.Compute/virtualMachines/vm-001 \
  --output table
```

### Use What-If

Always test deployments with what-if:

```bash
az deployment group create \
  --resource-group rg-prod \
  --template-file main.bicep \
  --parameters @parameters.json \
  --what-if
```

### Validate Templates

```bash
# Validate before deploying
az deployment group validate \
  --resource-group rg-prod \
  --template-file main.bicep \
  --parameters @parameters.json

# Or use the validation script
./scripts/validate.ps1 -Path modules -Recursive
```

## Getting Help

### Azure Support

1. **Azure Portal**
   - Navigate to Support → New Support Request
   - Provide deployment correlation ID

2. **Azure CLI**
```bash
az support tickets create \
  --ticket-name "Deployment Issue" \
  --title "Cannot deploy storage account" \
  --description "Detailed description..." \
  --problem-classification "/providers/Microsoft.Support/services/quota_service_guid/problemClassifications/quota_service_guid" \
  --severity minimal
```

### Community Resources

- [Microsoft Q&A](https://learn.microsoft.com/answers)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/azure)
- [Azure Updates](https://azure.microsoft.com/updates/)
- [Bicep GitHub](https://github.com/Azure/bicep/issues)

### Documentation

- [Azure Documentation](https://learn.microsoft.com/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)

---

## Still Having Issues?

If you're still experiencing problems after trying the above solutions:

1. Check the module-specific README files
2. Review Azure service health status
3. Check for known issues in Azure updates
4. Open an issue on GitHub
5. Contact [thatlazyadmin.com](https://thatlazyadmin.com) for support

---

**Author:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)
