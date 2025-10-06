# Virtual Machine Workload Deployment Scenario

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This scenario deploys a complete virtual machine infrastructure with best practices for security, networking, and monitoring. It includes all necessary components for a production-ready VM deployment.

## What Gets Deployed

This scenario creates the following Azure resources:

- ✅ **Virtual Machine** - Windows Server 2022 or Ubuntu 22.04 LTS
- ✅ **Virtual Network** - with multiple subnets for isolation
- ✅ **Network Security Group** - with environment-appropriate rules
- ✅ **Network Interface** - with optional accelerated networking
- ✅ **Managed Identity** - for secure authentication
- ✅ **Storage Account** - for boot diagnostics
- ✅ **Public IP** (Optional) - for remote access in dev/test environments

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Resource Group                           │
│                                                             │
│  ┌──────────────┐         ┌─────────────────────┐         │
│  │   VNet       │         │  Network Security   │         │
│  │  10.0.0.0/16 │────────▶│      Group          │         │
│  └──────────────┘         └─────────────────────┘         │
│        │                                                    │
│        │                                                    │
│  ┌─────▼──────────┐      ┌──────────────────────┐         │
│  │  Subnet-VM     │      │   Storage Account    │         │
│  │  10.0.1.0/24   │      │  (Boot Diagnostics)  │         │
│  └────────────────┘      └──────────────────────┘         │
│        │                                                    │
│        │                                                    │
│  ┌─────▼──────────┐      ┌──────────────────────┐         │
│  │      NIC       │◀─────│   Public IP (opt)    │         │
│  └────────────────┘      └──────────────────────┘         │
│        │                                                    │
│        │                                                    │
│  ┌─────▼──────────┐      ┌──────────────────────┐         │
│  │   Virtual      │      │  Managed Identity    │         │
│  │   Machine      │◀─────│                      │         │
│  └────────────────┘      └──────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Azure CLI (v2.50.0 or later)
- Bicep CLI (v0.20.0 or later)
- Azure subscription with appropriate permissions
- SSH key pair (for Linux VMs) or strong password (for Windows VMs)

## Values You Need to Modify

### Required Changes

Before deploying, you **MUST** update the following values in the parameter files:

#### 1. Authentication Credentials

**For Linux VMs (SSH):**
```json
"adminPasswordOrKey": {
  "value": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-email@example.com"
}
```
- Generate SSH key: `ssh-keygen -t rsa -b 4096 -C "your-email@example.com"`
- Copy public key: `cat ~/.ssh/id_rsa.pub`

**For Windows VMs (Password):**
```json
"adminPasswordOrKey": {
  "value": "YourStrongP@ssw0rd123!"
}
```
- Must be 12-123 characters long
- Must contain 3 of: uppercase, lowercase, numbers, special characters

#### 2. Basic Configuration

| Parameter | Description | Example Values | When to Change |
|-----------|-------------|----------------|----------------|
| `environmentName` | Environment type | `dev`, `staging`, `prod` | Always |
| `workloadName` | Application/workload name | `webapp`, `api`, `database` | Always |
| `location` | Azure region | `eastus`, `westus`, `westeurope` | Based on your region |
| `adminUsername` | VM admin username | `azureuser`, `azureadmin` | Optional |

#### 3. VM Configuration

| Parameter | Description | Options | When to Change |
|-----------|-------------|---------|----------------|
| `osType` | Operating system | `Linux`, `Windows` | Based on workload |
| `vmSize` | VM size/SKU | See table below | Based on requirements |
| `authenticationType` | Auth method | `sshPublicKey`, `password` | Linux=SSH, Windows=Password |
| `availabilityZone` | Availability zone | `""`, `"1"`, `"2"`, `"3"` | Production=1/2/3, Dev="" |
| `enablePublicIP` | Enable public IP | `true`, `false` | Dev=true, Prod=false |

#### 4. VM Size Selection Guide

| VM Size | vCPUs | RAM | Use Case | Monthly Cost (approx) |
|---------|-------|-----|----------|----------------------|
| `Standard_B2s` | 2 | 4 GB | Dev/Test, low traffic | ~$30 |
| `Standard_D2s_v3` | 2 | 8 GB | General purpose, small apps | ~$70 |
| `Standard_D4s_v3` | 4 | 16 GB | Medium workloads | ~$140 |
| `Standard_D8s_v3` | 8 | 32 GB | High-traffic apps | ~$280 |
| `Standard_E2s_v3` | 2 | 16 GB | Memory-intensive | ~$85 |
| `Standard_E4s_v3` | 4 | 32 GB | Database, cache | ~$170 |

#### 5. Optional Tags

```json
"tags": {
  "value": {
    "CostCenter": "IT",           // Change to your cost center
    "Owner": "Platform Team",     // Change to team name
    "Project": "Web Application", // Change to project name
    "Criticality": "High"         // Add for production
  }
}
```

## Deployment Examples

### Example 1: Deploy Linux VM for Development

```bash
# Create resource group
az group create --name rg-webapp-dev --location eastus

# Deploy using parameters file
az deployment group create \
  --resource-group rg-webapp-dev \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)"
```

### Example 2: Deploy Windows VM for Production

```bash
# Create resource group
az group create --name rg-winapp-prod --location eastus

# Deploy with secure password
az deployment group create \
  --resource-group rg-winapp-prod \
  --template-file main.bicep \
  --parameters @parameters.windows.json \
  --parameters adminPasswordOrKey='YourStr0ng!P@ssword'
```

### Example 3: Deploy with Custom Values

```bash
az deployment group create \
  --resource-group rg-custom \
  --template-file main.bicep \
  --parameters environmentName=staging \
  --parameters workloadName=api \
  --parameters osType=Linux \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters adminUsername=azureuser \
  --parameters adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)" \
  --parameters authenticationType=sshPublicKey \
  --parameters availabilityZone=2 \
  --parameters enablePublicIP=false
```

### Example 4: Using PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-webapp-dev" -Location "eastus"

# Deploy with parameter file
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-webapp-dev" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.dev.json" `
  -adminPasswordOrKey (Get-Content ~/.ssh/id_rsa.pub -Raw)
```

## Post-Deployment Steps

### 1. Retrieve Connection Information

```bash
# Get deployment outputs
az deployment group show \
  --resource-group rg-webapp-dev \
  --name <deployment-name> \
  --query properties.outputs
```

### 2. Connect to Your VM

**For Linux VMs:**
```bash
# With Public IP
ssh azureuser@<public-fqdn>

# With Private IP (requires VPN/ExpressRoute)
ssh azureuser@<private-ip>
```

**For Windows VMs:**
```bash
# With Public IP
mstsc /v:<public-fqdn>

# With Private IP (requires VPN/ExpressRoute)
mstsc /v:<private-ip>
```

### 3. Configure Managed Identity Permissions

```bash
# Grant VM's managed identity access to Key Vault
az keyvault set-policy \
  --name <keyvault-name> \
  --object-id <managed-identity-principal-id> \
  --secret-permissions get list

# Grant access to Storage Account
az role assignment create \
  --assignee <managed-identity-principal-id> \
  --role "Storage Blob Data Contributor" \
  --scope <storage-account-id>
```

## Environment-Specific Configurations

### Development Environment
- **VM Size:** `Standard_B2s` or `Standard_D2s_v3`
- **Public IP:** Enabled for easy access
- **Availability Zone:** Not configured (empty)
- **Disk Type:** StandardSSD_LRS
- **NSG Rules:** SSH/RDP allowed from internet (⚠️ change source to your IP)

### Production Environment
- **VM Size:** `Standard_D4s_v3` or higher
- **Public IP:** Disabled (use VPN/Bastion)
- **Availability Zone:** Configured (1, 2, or 3)
- **Disk Type:** Premium_LRS
- **NSG Rules:** SSH/RDP denied from internet

## Security Best Practices

1. **Never use passwords for Linux VMs** - Always use SSH keys
2. **Use strong passwords** for Windows VMs (min 12 characters)
3. **Disable public IPs** in production - use Azure Bastion or VPN
4. **Restrict NSG rules** - Allow only specific source IP addresses
5. **Enable boot diagnostics** - For troubleshooting
6. **Use managed identities** - Avoid storing credentials
7. **Enable Azure Disk Encryption** - Encrypt OS and data disks (post-deployment)
8. **Configure Update Management** - Keep VMs patched

## Common Customizations

### Change VM Size After Deployment

```bash
az vm resize \
  --resource-group rg-webapp-dev \
  --name vm-webapp-dev-xxxxx \
  --size Standard_D4s_v3
```

### Add Data Disk

```bash
az vm disk attach \
  --resource-group rg-webapp-dev \
  --vm-name vm-webapp-dev-xxxxx \
  --name data-disk-001 \
  --size-gb 128 \
  --sku Premium_LRS \
  --new
```

### Update NSG Rules

```bash
# Allow specific IP for SSH
az network nsg rule create \
  --resource-group rg-webapp-dev \
  --nsg-name nsg-webapp-dev-xxxxx \
  --name Allow-SSH-From-MyIP \
  --priority 100 \
  --source-address-prefixes <your-ip>/32 \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp
```

## Cost Optimization

- **Use B-series** for development (burstable VMs)
- **Deallocate VMs** when not in use: `az vm deallocate`
- **Use Azure Hybrid Benefit** for Windows VMs with existing licenses
- **Right-size VMs** based on actual usage
- **Consider Reserved Instances** for production (1-year or 3-year commitment)

## Troubleshooting

### Cannot connect to VM

1. Check NSG rules allow traffic
2. Verify public IP is attached (if using public IP)
3. Check VM is running: `az vm get-instance-view`
4. Review boot diagnostics in Azure Portal

### Authentication failures

1. Verify SSH key is correct format
2. Check username matches adminUsername
3. For Windows, ensure password meets complexity requirements

### VM won't start

1. Check boot diagnostics logs
2. Verify subscription has available quota
3. Check availability zone is available in region

## Clean Up

To remove all resources:

```bash
# Delete the entire resource group
az group delete --name rg-webapp-dev --yes --no-wait
```

## What's Next?

After deploying your VM:

1. **Install applications** and configure services
2. **Set up monitoring** with Azure Monitor
3. **Configure backups** with Azure Backup
4. **Enable Azure Security Center** recommendations
5. **Set up auto-shutdown** for dev VMs to save costs

## Support

For issues or questions:
- Check [Troubleshooting Guide](../../docs/troubleshooting.md)
- Review [Azure VM Documentation](https://docs.microsoft.com/azure/virtual-machines/)
- Visit [thatlazyadmin.com](https://thatlazyadmin.com)

---

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)
