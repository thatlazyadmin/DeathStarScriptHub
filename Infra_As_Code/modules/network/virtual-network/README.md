# Virtual Network Module

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This module deploys an Azure Virtual Network with multiple subnets and optional DDoS protection.

## Features

- ✅ Multiple subnet support
- ✅ Custom DNS servers
- ✅ DDoS protection option
- ✅ VM protection option
- ✅ Private endpoint network policies
- ✅ Flexible address space

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `vnetName` | string | Yes | - | Virtual network name |
| `location` | string | No | resourceGroup().location | Azure region |
| `addressPrefixes` | array | No | ['10.0.0.0/16'] | Address space |
| `subnets` | array | No | See parameters.json | Subnet configuration |
| `enableDdosProtection` | bool | No | false | Enable DDoS protection |
| `enableVmProtection` | bool | No | false | Enable VM protection |
| `dnsServers` | array | No | [] | Custom DNS servers |
| `tags` | object | No | {} | Resource tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vnetId` | string | Virtual network resource ID |
| `vnetName` | string | Virtual network name |
| `subnetIds` | array | Array of subnet IDs |
| `subnets` | array | Array of subnet details |

## Usage

```bash
az deployment group create \
  --resource-group rg-network \
  --template-file main.bicep \
  --parameters @parameters.json
```

## Examples

### Basic VNet

```bicep
module vnet 'main.bicep' = {
  name: 'vnetDeployment'
  params: {
    vnetName: 'vnet-prod-001'
    addressPrefixes: ['10.0.0.0/16']
    subnets: [
      {
        name: 'subnet-web'
        addressPrefix: '10.0.1.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}
```

## Author

**Shaun Hardneck**  
[thatlazyadmin.com](https://thatlazyadmin.com)
