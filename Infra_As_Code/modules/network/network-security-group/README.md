# Network Security Group Module

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This module deploys a Network Security Group with custom security rules.

## Features

- ✅ Custom security rules
- ✅ Inbound and outbound traffic control
- ✅ Priority-based rule processing
- ✅ Protocol-specific rules

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `nsgName` | string | Yes | - | NSG name |
| `location` | string | No | resourceGroup().location | Azure region |
| `securityRules` | array | No | [] | Security rules |
| `tags` | object | No | {} | Resource tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `nsgId` | string | NSG resource ID |
| `nsgName` | string | NSG name |

## Usage

```bash
az deployment group create \
  --resource-group rg-network \
  --template-file main.bicep \
  --parameters @parameters.json
```

## Author

**Shaun Hardneck**  
[thatlazyadmin.com](https://thatlazyadmin.com)
