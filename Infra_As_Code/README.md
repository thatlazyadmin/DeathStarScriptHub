# Azure Infrastructure as Code - Verified Modules

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

[![Bicep](https://img.shields.io/badge/Bicep-Latest-blue)](https://aka.ms/bicep)
[![Azure Verified Modules](https://img.shields.io/badge/AVM-Enabled-green)](https://aka.ms/avm)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Overview

This repository contains production-ready Infrastructure as Code (IaC) templates using **Azure Verified Modules (AVM)** and **Bicep**. It provides reusable, tested, and well-documented modules for deploying Azure resources following Microsoft's best practices.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Available Modules](#available-modules)
- [Deployment Scenarios](#deployment-scenarios)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)
- [License](#license)

## Quick Links

- **[� Getting Started](GETTING_STARTED.md)** - 5-minute quick start guide for first-time users
- **[�📋 Complete Summary](SUMMARY.md)** - Overview of everything in this repository
- **[📖 Module Index](docs/module-index.md)** - Quick reference for all modules
- **[🚀 Deployment Guide](docs/deployment-guide.md)** - Step-by-step deployment instructions
- **[⚡ Best Practices](docs/best-practices.md)** - Azure IaC best practices
- **[🔧 Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[🔄 Azure DevOps Setup](docs/azure-devops-setup.md)** - CI/CD pipeline configuration

## Features

- ✅ **Azure Verified Modules** - Uses official Microsoft AVM modules
- ✅ **Production-Ready** - Battle-tested templates with security best practices
- ✅ **Modular Design** - Reusable components for any Azure deployment
- ✅ **Well-Documented** - Comprehensive README files for each module
- ✅ **Parameter Files** - Example configurations for quick deployment
- ✅ **Cross-Platform Scripts** - PowerShell and Bash deployment scripts
- ✅ **Security-First** - Managed Identity, Key Vault, and RBAC integration
- ✅ **Naming Conventions** - Consistent Azure resource naming standards

## Prerequisites

Before you begin, ensure you have the following installed:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (v2.50.0 or later)
- [Bicep CLI](https://aka.ms/bicep/install) (v0.20.0 or later)
- [PowerShell 7+](https://aka.ms/powershell) (for PowerShell scripts)
- Azure Subscription with appropriate permissions

### Verify Installation

```bash
# Check Azure CLI version
az --version

# Check Bicep version
az bicep version

# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

## Quick Start

### 1. Clone the Repository

```bash
# Clone from Azure DevOps
git clone https://dev.azure.com/{your-org}/{your-project}/_git/DeathStarScriptHub
cd DeathStarScriptHub/Infra_As_Code
```

### 2. Deploy a Storage Account

```bash
# Using Azure CLI
az deployment group create \
  --resource-group rg-demo \
  --template-file modules/storage/storage-account/main.bicep \
  --parameters @modules/storage/storage-account/parameters.json

# Using PowerShell
./scripts/deploy.ps1 -ResourceGroup "rg-demo" -TemplateFile "modules/storage/storage-account/main.bicep"
```

### 3. Deploy a Complete Scenario

```bash
# Deploy AKS cluster with networking
az deployment group create \
  --resource-group rg-aks-prod \
  --template-file scenarios/aks-cluster-complete/main.bicep \
  --parameters @scenarios/aks-cluster-complete/parameters.json
```

## Repository Structure

```text
Infra_As_Code/
├── README.md                          # This file
├── bicepconfig.json                   # Bicep linter configuration
├── .markdownlint.json                 # Markdown linting rules
├── .gitignore                         # Git ignore rules
├── azure-pipelines.yml                # Azure DevOps CI/CD pipeline
├── .azuredevops/                      # Azure DevOps configuration
│   └── README.md                      # Pipeline setup guide
├── modules/                           # Reusable Bicep modules
│   ├── compute/                       # Compute resources
│   │   ├── virtual-machine/           # Virtual Machine module
│   │   │   ├── main.bicep
│   │   │   ├── parameters.json
│   │   │   └── README.md
│   │   └── aks/                       # Azure Kubernetes Service module
│   │       ├── main.bicep
│   │       ├── parameters.json
│   │       └── README.md
│   ├── storage/                       # Storage resources
│   │   ├── storage-account/           # Storage Account module
│   │   │   ├── main.bicep
│   │   │   ├── parameters.json
│   │   │   └── README.md
│   │   └── file-share/                # File Share module
│   │       ├── main.bicep
│   │       ├── parameters.json
│   │       └── README.md
│   ├── network/                       # Networking resources
│   │   ├── virtual-network/           # Virtual Network module
│   │   │   ├── main.bicep
│   │   │   ├── parameters.json
│   │   │   └── README.md
│   │   └── network-security-group/    # NSG module
│   │       ├── main.bicep
│   │       ├── parameters.json
│   │       └── README.md
│   ├── database/                      # Database resources
│   │   ├── sql-database/              # Azure SQL Database module
│   │   │   ├── main.bicep
│   │   │   ├── parameters.json
│   │   │   └── README.md
│   │   └── cosmos-db/                 # Cosmos DB module
│   │       ├── main.bicep
│   │       ├── parameters.json
│   │       └── README.md
│   └── security/                      # Security resources
│       ├── key-vault/                 # Key Vault module
│       │   ├── main.bicep
│       │   ├── parameters.json
│       │   └── README.md
│       └── managed-identity/          # Managed Identity module
│           ├── main.bicep
│           ├── parameters.json
│           └── README.md
├── scenarios/                         # Complete deployment scenarios
│   ├── web-app-with-database/         # Web app + SQL scenario
│   │   ├── main.bicep
│   │   ├── parameters.prod.json
│   │   └── README.md
│   └── aks-cluster-complete/          # Complete AKS scenario
│       ├── main.bicep
│       ├── parameters.prod.json
│       └── README.md
├── scripts/                           # Deployment automation scripts
│   ├── deploy.ps1                     # PowerShell deployment script
│   ├── deploy.sh                      # Bash deployment script
│   ├── validate.ps1                   # Bicep validation script
│   └── cleanup.ps1                    # Resource cleanup script
└── docs/                              # Documentation
    ├── deployment-guide.md            # Deployment guide
    ├── best-practices.md              # Best practices
    ├── troubleshooting.md             # Troubleshooting guide
    └── azure-devops-setup.md          # Azure DevOps setup guide
```

## Available Modules

### Compute Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| **Virtual Machine** | Deploy Windows/Linux VMs | Trusted Launch, encryption at host, managed disks |
| **Azure Kubernetes Service** | Deploy AKS clusters | Auto-scaling, Azure CNI, monitoring, RBAC |

### Storage Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| **Storage Account** | General-purpose storage | Blob, File, Queue, Table, encryption, HTTPS-only |
| **File Share** | Azure Files deployment | SMB/NFS protocols, premium/standard tiers |

### Network Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| **Virtual Network** | VNet with subnets | Service endpoints, NSG support, peering-ready |
| **Network Security Group** | Traffic filtering | Security rules, application security groups |

### Database Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| **SQL Database** | Azure SQL Database | Advanced Threat Protection, Azure AD auth, TDE |
| **Cosmos DB** | Multi-model database | Multi-region, multiple APIs, serverless option |

### Security Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| **Key Vault** | Secrets management | Soft delete, purge protection, RBAC, private endpoints |
| **Managed Identity** | Azure AD identities | User-assigned, RBAC support, no credentials |

## Deployment Scenarios

### Web Application with Database

Complete infrastructure for a web application with SQL backend:

- Managed Identity for authentication
- Key Vault for secrets
- Azure SQL Database
- Storage Account for static content
- Virtual Network with service endpoints

```bash
az deployment group create 
  --resource-group rg-webapp-prod 
  --template-file scenarios/web-app-with-database/main.bicep 
  --parameters scenarios/web-app-with-database/parameters.prod.json
```

### Complete AKS Cluster

Production-ready Kubernetes cluster:

- AKS with system and user node pools
- Virtual Network with dedicated subnet
- Managed Identity with proper RBAC
- Auto-scaling enabled
- Container Insights monitoring

```bash
az deployment group create 
  --resource-group rg-aks-prod 
  --template-file scenarios/aks-cluster-complete/main.bicep 
  --parameters scenarios/aks-cluster-complete/parameters.prod.json
```

## Available Modules

### Compute

| Module | Description | Documentation |
|--------|-------------|---------------|
| Virtual Machine | Deploy Windows/Linux VMs with managed disks | [README](modules/compute/virtual-machine/README.md) |
| AKS | Azure Kubernetes Service cluster | [README](modules/compute/aks/README.md) |

### Storage

| Module | Description | Documentation |
|--------|-------------|---------------|
| Storage Account | General-purpose v2 storage accounts | [README](modules/storage/storage-account/README.md) |
| File Share | Azure Files with SMB/NFS support | [README](modules/storage/file-share/README.md) |

### Network

| Module | Description | Documentation |
|--------|-------------|---------------|
| Virtual Network | VNet with subnets and NSG | [README](modules/network/virtual-network/README.md) |
| NSG | Network Security Groups with rules | [README](modules/network/network-security-group/README.md) |

### Database

| Module | Description | Documentation |
|--------|-------------|---------------|
| SQL Database | Azure SQL Database with failover | [README](modules/database/sql-database/README.md) |
| Cosmos DB | Cosmos DB with multiple APIs | [README](modules/database/cosmos-db/README.md) |

### Security

| Module | Description | Documentation |
|--------|-------------|---------------|
| Key Vault | Key Vault with RBAC and secrets | [README](modules/security/key-vault/README.md) |
| Managed Identity | User/System Managed Identities | [README](modules/security/managed-identity/README.md) |

## Deployment Scenarios

### Web App with Database

Complete three-tier architecture with App Service, SQL Database, and Key Vault.

[View Scenario](scenarios/web-app-with-database/README.md)

### AKS Production Cluster

Production-grade AKS cluster with:

- Azure CNI networking
- Managed Identity
- Azure Policy
- Container Insights
- Private cluster option

[View Scenario](scenarios/aks-cluster-complete/README.md)

### Virtual Machine Workload

VM deployment with:

- Managed disks (Premium SSD)
- Availability zones
- Network security
- Backup policy

[View Scenario](scenarios/virtual-machine-workload/README.md)

## Usage Examples

### Deploy with PowerShell

```powershell
# Deploy a resource group scoped deployment
./scripts/deploy.ps1 `
  -ResourceGroup "rg-prod-001" `
  -TemplateFile "modules/storage/storage-account/main.bicep" `
  -ParameterFile "modules/storage/storage-account/parameters.json" `
  -Location "eastus"
```

### Deploy with Bash

```bash
# Deploy a subscription scoped deployment
./scripts/deploy.sh \
  --resource-group "rg-prod-001" \
  --template-file "scenarios/aks-cluster-complete/main.bicep" \
  --parameter-file "scenarios/aks-cluster-complete/parameters.json" \
  --location "eastus"
```

### Validate Templates

```powershell
# Validate all Bicep templates
./scripts/validate.ps1 -Path "modules"
```

### Cleanup Resources

```powershell
# Delete resource group and all resources
./scripts/cleanup.ps1 -ResourceGroup "rg-demo"
```

## Best Practices

This repository follows Azure best practices:

- **Naming Conventions** - Uses CAF naming standards
- **Tagging** - All resources tagged with environment, owner, cost center
- **Security** - Managed Identity over service principals
- **Network** - Private endpoints where applicable
- **Monitoring** - Diagnostic settings enabled by default
- **High Availability** - Zone redundancy for production workloads
- **Backup** - Retention policies configured

See [Best Practices Guide](docs/best-practices.md) for details.

## Contributing

Contributions are welcome! Please read our Contributing Guide for details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

**Shaun Hardneck**  
Website: [thatlazyadmin.com](https://thatlazyadmin.com)  
Azure DevOps: Contact for repository access

## Acknowledgments

- [Azure Verified Modules](https://aka.ms/avm)
- [Bicep Documentation](https://aka.ms/bicep)
- [Azure Architecture Center](https://aka.ms/architecture)
- [Azure DevOps](https://azure.microsoft.com/services/devops/)

---

**Need Help?** Check our [Troubleshooting Guide](docs/troubleshooting.md) or contact your Azure DevOps team.
