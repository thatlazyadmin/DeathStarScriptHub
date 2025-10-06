# Virtual Machine Deployment - Quick Reference

## Quick Deployment Commands

### Linux VM (Development)
```bash
# 1. Set your SSH public key
SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"

# 2. Create resource group
az group create --name rg-linux-dev --location eastus

# 3. Deploy
az deployment group create \
  --resource-group rg-linux-dev \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters adminPasswordOrKey="$SSH_KEY"

# 4. Get connection info
az deployment group show \
  --resource-group rg-linux-dev \
  --name main \
  --query 'properties.outputs.connectionInstructions.value' -o tsv
```

### Windows VM (Development)
```bash
# 1. Set strong password
PASSWORD='YourStr0ng!P@ssword123'

# 2. Create resource group
az group create --name rg-windows-dev --location eastus

# 3. Deploy
az deployment group create \
  --resource-group rg-windows-dev \
  --template-file main.bicep \
  --parameters @parameters.windows.json \
  --parameters adminPasswordOrKey="$PASSWORD"

# 4. Get connection info
az deployment group show \
  --resource-group rg-windows-dev \
  --name main \
  --query 'properties.outputs.connectionInstructions.value' -o tsv
```

### Production Linux VM
```bash
# Production = No Public IP, Availability Zone, Premium Disk

az deployment group create \
  --resource-group rg-linux-prod \
  --template-file main.bicep \
  --parameters @parameters.prod.json \
  --parameters adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)"
```

## Parameter Values You MUST Change

| Parameter | Where to Change | Example Value |
|-----------|-----------------|---------------|
| **adminPasswordOrKey** | Command line or parameter file | SSH public key or strong password |
| **workloadName** | Parameter file | `webapp`, `api`, `database` |
| **location** | Parameter file | `eastus`, `westeurope` |
| **osType** | Parameter file | `Linux` or `Windows` |
| **vmSize** | Parameter file | `Standard_D2s_v3` |

## Parameter Files Included

- `parameters.dev.json` - Linux VM, Public IP, Dev-sized
- `parameters.prod.json` - Linux VM, No Public IP, Production-sized, Zone 1
- `parameters.windows.json` - Windows VM, Public IP, Dev-sized

## Common VM Sizes

| Size | vCPU | RAM | Cost/Month | Use For |
|------|------|-----|------------|---------|
| Standard_B2s | 2 | 4 GB | ~$30 | Dev/Test |
| Standard_D2s_v3 | 2 | 8 GB | ~$70 | Small Apps |
| Standard_D4s_v3 | 4 | 16 GB | ~$140 | Medium Apps |
| Standard_D8s_v3 | 8 | 32 GB | ~$280 | High Traffic |
| Standard_E4s_v3 | 4 | 32 GB | ~$170 | Databases |

## Outputs You'll Get

After deployment, you'll receive:

- VM Name
- VM ID
- Private IP Address
- Public IP Address (if enabled)
- Public FQDN (if enabled)
- Connection Instructions
- Managed Identity Principal ID

## Connect to Your VM

### Linux
```bash
# Get FQDN from outputs
FQDN=$(az deployment group show --resource-group rg-linux-dev --name main --query 'properties.outputs.publicFQDN.value' -o tsv)

# Connect
ssh azureuser@$FQDN
```

### Windows
```bash
# Get FQDN from outputs
FQDN=$(az deployment group show --resource-group rg-windows-dev --name main --query 'properties.outputs.publicFQDN.value' -o tsv)

# Connect (Windows)
mstsc /v:$FQDN

# Or from Mac/Linux
open rdp://$FQDN
```

## Delete Everything
```bash
az group delete --name rg-linux-dev --yes --no-wait
```

## Troubleshooting

**Issue:** Can't connect to VM  
**Fix:** Check NSG allows SSH (22) or RDP (3389) from your IP

**Issue:** SSH key not working  
**Fix:** Verify key format: `cat ~/.ssh/id_rsa.pub` should start with `ssh-rsa`

**Issue:** Password rejected  
**Fix:** Ensure 12+ chars with uppercase, lowercase, number, special character

**Issue:** Deployment fails with "QuotaExceeded"  
**Fix:** Request quota increase or choose different region/size

---

**Created by:** Shaun Hardneck | [thatlazyadmin.com](https://thatlazyadmin.com)
