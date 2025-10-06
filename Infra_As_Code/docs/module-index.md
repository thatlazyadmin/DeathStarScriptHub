# Azure IaC Module Index

Quick reference guide for all available Bicep modules and scenarios.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Module Categories

### 🖥️ Compute Resources

#### Virtual Machine

Deploy Windows or Linux virtual machines with enterprise security.

- **Path**: `modules/compute/virtual-machine/`
- **Features**: Trusted Launch, encryption at host, availability zones
- **Use Cases**: Application servers, domain controllers, jump boxes
- **Documentation**: [VM Module README](modules/compute/virtual-machine/README.md)

#### Azure Kubernetes Service (AKS)

Deploy production-ready Kubernetes clusters.

- **Path**: `modules/compute/aks/`
- **Features**: Auto-scaling, Azure CNI, Container Insights, RBAC
- **Use Cases**: Containerized applications, microservices
- **Documentation**: [AKS Module README](modules/compute/aks/README.md)

### 💾 Storage Resources

#### Storage Account

General-purpose Azure Storage with all service types.

- **Path**: `modules/storage/storage-account/`
- **Features**: Blob, File, Queue, Table, Data Lake Gen2, encryption
- **Use Cases**: Application storage, backups, data lakes
- **Documentation**: [Storage Account README](modules/storage/storage-account/README.md)

#### File Share

Azure Files for cloud file shares.

- **Path**: `modules/storage/file-share/`
- **Features**: SMB/NFS protocols, premium performance, snapshots
- **Use Cases**: Shared application data, lift-and-shift scenarios
- **Documentation**: [File Share README](modules/storage/file-share/README.md)

### 🌐 Network Resources

#### Virtual Network

Azure Virtual Network with subnets and service endpoints.

- **Path**: `modules/network/virtual-network/`
- **Features**: Multiple subnets, service endpoints, DDoS protection
- **Use Cases**: Network isolation, hybrid connectivity
- **Documentation**: [VNet README](modules/network/virtual-network/README.md)

#### Network Security Group

Traffic filtering with security rules.

- **Path**: `modules/network/network-security-group/`
- **Features**: Inbound/outbound rules, ASG support, flow logs
- **Use Cases**: Network security, traffic control
- **Documentation**: [NSG README](modules/network/network-security-group/README.md)

### 🗄️ Database Resources

#### SQL Database

Azure SQL Database with enterprise features.

- **Path**: `modules/database/sql-database/`
- **Features**: Advanced Threat Protection, Azure AD auth, TDE, auditing
- **Use Cases**: Relational databases, OLTP workloads
- **Documentation**: [SQL Database README](modules/database/sql-database/README.md)

#### Cosmos DB

Multi-model, globally distributed database.

- **Path**: `modules/database/cosmos-db/`
- **Features**: Multi-region, multiple APIs, serverless, analytical storage
- **Use Cases**: NoSQL workloads, global applications, IoT
- **Documentation**: [Cosmos DB README](modules/database/cosmos-db/README.md)

### 🔐 Security Resources

#### Key Vault

Secrets, keys, and certificates management.

- **Path**: `modules/security/key-vault/`
- **Features**: Soft delete, purge protection, RBAC, private endpoints, HSM
- **Use Cases**: Secret storage, certificate management, encryption keys
- **Documentation**: [Key Vault README](modules/security/key-vault/README.md)

#### Managed Identity

User-assigned Azure AD identities for resources.

- **Path**: `modules/security/managed-identity/`
- **Features**: Azure AD authentication, RBAC support, multi-resource
- **Use Cases**: Service authentication, eliminate credentials
- **Documentation**: [Managed Identity README](modules/security/managed-identity/README.md)

## Deployment Scenarios

### 🌐 Web Application with Database

Complete web app infrastructure with SQL backend.

- **Path**: `scenarios/web-app-with-database/`
- **Includes**: Managed Identity, Key Vault, SQL Database, Storage, VNet
- **Environments**: Dev, Staging, Production
- **Documentation**: [Scenario README](scenarios/web-app-with-database/README.md)

### ☸️ Complete AKS Cluster

Production-ready Kubernetes cluster deployment.

- **Path**: `scenarios/aks-cluster-complete/`
- **Includes**: AKS, VNet, Managed Identity, auto-scaling, monitoring
- **Environments**: Dev, Production
- **Documentation**: [Scenario README](scenarios/aks-cluster-complete/README.md)

## Quick Start by Use Case

### "I need a web application with database"

```bash
cd scenarios/web-app-with-database
az deployment group create \
  --resource-group rg-webapp-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json
```

### "I need a Kubernetes cluster"

```bash
cd scenarios/aks-cluster-complete
az deployment group create \
  --resource-group rg-aks-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json
```

### "I need just a storage account"

```bash
cd modules/storage/storage-account
az deployment group create \
  --resource-group rg-storage-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

### "I need a SQL database"

```bash
cd modules/database/sql-database
az deployment group create \
  --resource-group rg-database-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

### "I need to store secrets securely"

```bash
cd modules/security/key-vault
az deployment group create \
  --resource-group rg-security-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

## Module Compatibility Matrix

| Module | VNet Integration | Private Endpoints | Managed Identity | Key Vault |
|--------|------------------|-------------------|------------------|-----------|
| Virtual Machine | ✅ | ✅ | ✅ | ✅ |
| AKS | ✅ | ✅ | ✅ | ✅ |
| Storage Account | ✅ | ✅ | ✅ | ✅ |
| File Share | ✅ | ✅ | ✅ | ✅ |
| SQL Database | ✅ | ✅ | ✅ | ✅ |
| Cosmos DB | ✅ | ✅ | ✅ | ✅ |
| Key Vault | ✅ | ✅ | ✅ | N/A |

## Automation Scripts

### Deployment Scripts

- **PowerShell**: `scripts/deploy.ps1` - Cross-platform deployment
- **Bash**: `scripts/deploy.sh` - Linux/macOS deployment

### Validation Scripts

- **PowerShell**: `scripts/validate.ps1` - Validate all Bicep templates

### Cleanup Scripts

- **PowerShell**: `scripts/cleanup.ps1` - Remove deployed resources

## CI/CD Integration

### Azure DevOps

Use the provided `azure-pipelines.yml` for multi-stage deployments:

- Validation stage
- Development deployment
- Staging deployment (with approval)
- Production deployment (with approval)

See [Azure DevOps Setup Guide](docs/azure-devops-setup.md) for configuration.

## Documentation

- **[Deployment Guide](docs/deployment-guide.md)**: Step-by-step deployment instructions
- **[Best Practices](docs/best-practices.md)**: Azure IaC best practices
- **[Troubleshooting](docs/troubleshooting.md)**: Common issues and solutions
- **[Azure DevOps Setup](docs/azure-devops-setup.md)**: CI/CD pipeline configuration

## Support

For questions or issues:

- Review the module-specific README files
- Check the [troubleshooting guide](docs/troubleshooting.md)
- Contact your Azure DevOps team administrator

## Version Information

- **Bicep Version**: Latest (validated with v0.24+)
- **API Versions**: 2023-2024 (latest stable versions)
- **PowerShell**: 7.0+ required
- **Azure CLI**: 2.50+ required

---

**Repository**: Azure IaC Modules  
**Created by**: Shaun Hardneck  
**Website**: [thatlazyadmin.com](https://thatlazyadmin.com)
