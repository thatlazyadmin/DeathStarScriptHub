# Virtual Machine Module

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This module deploys an Azure Virtual Machine (Windows or Linux) with managed disks, security features, and best practices.

## Features

- ✅ Windows Server 2022 or Ubuntu 22.04 LTS
- ✅ Trusted Launch with Secure Boot and vTPM
- ✅ Encryption at host enabled
- ✅ Availability zone support
- ✅ Accelerated networking
- ✅ SSH key or password authentication
- ✅ Premium SSD managed disks
- ✅ Boot diagnostics support

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `vmName` | string | Yes | - | Virtual machine name |
| `location` | string | No | resourceGroup().location | Azure region |
| `vmSize` | string | No | Standard_D2s_v3 | VM size |
| `osType` | string | No | Linux | OS type (Windows/Linux) |
| `osDiskSizeGB` | int | No | 128 | OS disk size in GB |
| `osDiskStorageType` | string | No | Premium_LRS | OS disk storage type |
| `adminUsername` | string | Yes | - | Admin username |
| `adminPasswordOrKey` | securestring | Yes | - | Password or SSH public key |
| `authenticationType` | string | No | sshPublicKey | Auth type (password/sshPublicKey) |
| `subnetId` | string | Yes | - | Subnet resource ID |
| `enableAcceleratedNetworking` | bool | No | true | Enable accelerated networking |
| `availabilityZone` | string | No | 1 | Availability zone (1, 2, 3, or empty) |
| `enableBootDiagnostics` | bool | No | true | Enable boot diagnostics |
| `bootDiagnosticsStorageAccountName` | string | No | '' | Storage account for boot diagnostics |
| `tags` | object | No | {} | Resource tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vmId` | string | Virtual machine resource ID |
| `vmName` | string | Virtual machine name |
| `privateIPAddress` | string | Private IP address |
| `nicId` | string | Network interface ID |

## Usage

### Deploy Linux VM with SSH

```bash
az deployment group create \
  --resource-group rg-vms \
  --template-file main.bicep \
  --parameters \
    vmName=vm-web-001 \
    adminUsername=azureuser \
    adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)" \
    subnetId="/subscriptions/.../subnets/subnet-web"
```

### Deploy Windows VM with Password

```bash
az deployment group create \
  --resource-group rg-vms \
  --template-file main.bicep \
  --parameters \
    vmName=vm-app-001 \
    osType=Windows \
    authenticationType=password \
    adminUsername=azureadmin \
    adminPasswordOrKey="P@ssw0rd123!" \
    subnetId="/subscriptions/.../subnets/subnet-app"
```

## Examples

### Linux VM in Availability Zone 1

```bicep
module vm 'main.bicep' = {
  name: 'linuxVmDeployment'
  params: {
    vmName: 'vm-linux-001'
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    adminUsername: 'azureuser'
    adminPasswordOrKey: sshPublicKey
    authenticationType: 'sshPublicKey'
    subnetId: subnet.id
    availabilityZone: '1'
  }
}
```

### Windows VM with Custom Disk

```bicep
module vm 'main.bicep' = {
  name: 'windowsVmDeployment'
  params: {
    vmName: 'vm-win-001'
    osType: 'Windows'
    vmSize: 'Standard_E4s_v3'
    osDiskSizeGB: 256
    osDiskStorageType: 'Premium_LRS'
    adminUsername: 'winadmin'
    adminPasswordOrKey: adminPassword
    authenticationType: 'password'
    subnetId: subnet.id
    availabilityZone: '2'
  }
}
```

## Security Features

- **Trusted Launch**: Secure Boot and vTPM enabled
- **Encryption at Host**: OS and data disks encrypted
- **Network Security**: Private IP only by default
- **SSH Keys**: Recommended over password authentication
- **Accelerated Networking**: Improved network performance

## Best Practices

1. Use **SSH keys** for Linux VMs (never passwords in production)
2. Store secrets in **Azure Key Vault** (reference in parameters)
3. Enable **Azure Backup** for production workloads
4. Use **Availability Zones** for high availability
5. Implement **Update Management** for patch management
6. Enable **Azure Monitor** for diagnostics
7. Use **Managed Identities** for application authentication

## Author

**Shaun Hardneck**  
[thatlazyadmin.com](https://thatlazyadmin.com)
