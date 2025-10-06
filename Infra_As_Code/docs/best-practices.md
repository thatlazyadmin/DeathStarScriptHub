# Azure Infrastructure as Code - Best Practices

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Table of Contents

- [Security](#security)
- [Networking](#networking)
- [Compute](#compute)
- [Storage](#storage)
- [Monitoring](#monitoring)
- [Cost Optimization](#cost-optimization)
- [Naming Conventions](#naming-conventions)
- [Tagging Strategy](#tagging-strategy)

## Security

### Authentication & Authorization

1. **Use Managed Identities**
   - Prefer system-assigned or user-assigned managed identities
   - Avoid storing credentials in code or configuration files
   - Use managed identities for Azure resource authentication

2. **Implement RBAC**
   - Follow principle of least privilege
   - Use built-in roles when possible
   - Create custom roles only when necessary
   - Regularly review and audit role assignments

3. **Secrets Management**
   - Store secrets in Azure Key Vault
   - Reference Key Vault secrets in Bicep templates
   - Enable soft delete and purge protection on Key Vault
   - Rotate secrets regularly

```bicep
// Example: Reference Key Vault secret
param adminPassword string {
  secure: true
  metadata: {
    description: 'Reference from Key Vault'
  }
}
```

### Network Security

1. **Private Endpoints**
   - Use private endpoints for PaaS services
   - Disable public access where possible
   - Implement network segmentation

2. **Network Security Groups**
   - Apply NSGs to all subnets
   - Use service tags instead of IP ranges
   - Deny by default, allow explicitly
   - Log NSG flow logs for auditing

3. **TLS/SSL**
   - Enforce minimum TLS version 1.2
   - Use HTTPS/TLS for all communications
   - Disable older protocol versions

## Networking

### Virtual Network Design

1. **Address Space Planning**
   - Plan IP address ranges carefully
   - Use non-overlapping CIDR blocks
   - Reserve address space for future growth
   - Document IP allocations

2. **Subnet Segmentation**
   - Separate workloads by subnet
   - Use dedicated subnets for specific services (AKS, App Service, etc.)
   - Apply NSGs at subnet level
   - Enable service endpoints where needed

3. **Hub-Spoke Topology**
   - Implement hub-spoke for multi-region or complex architectures
   - Centralize shared services in hub VNet
   - Use VNet peering or VPN for spoke connectivity

### DNS

1. Use Azure Private DNS Zones for private endpoints
2. Configure custom DNS servers if needed
3. Implement DNS forwarding for hybrid scenarios

## Compute

### Virtual Machines

1. **Image Selection**
   - Use latest OS images
   - Enable automatic updates
   - Use Azure Marketplace images when possible

2. **Disk Management**
   - Use Premium SSD for production workloads
   - Enable disk encryption at host
   - Implement backup policies
   - Use managed disks (never unmanaged)

3. **High Availability**
   - Deploy VMs across availability zones
   - Use availability sets for older regions
   - Implement load balancing
   - Configure auto-shutdown for dev/test

4. **Security**
   - Enable Trusted Launch
   - Enable Secure Boot and vTPM
   - Use SSH keys for Linux (never passwords)
   - Implement Just-In-Time (JIT) access

### Azure Kubernetes Service (AKS)

1. **Node Pools**
   - Separate system and user node pools
   - Use auto-scaling for user pools
   - Deploy across availability zones
   - Right-size VM SKUs

2. **Network**
   - Use Azure CNI for production
   - Implement network policies
   - Use private clusters for sensitive workloads
   - Configure egress lockdown

3. **Security**
   - Enable Azure AD integration
   - Use Azure Policy for compliance
   - Implement Pod Security Standards
   - Enable Microsoft Defender for Containers

4. **Monitoring**
   - Enable Container Insights
   - Configure log retention
   - Set up alerts for critical metrics
   - Use Application Insights for apps

## Storage

### Storage Accounts

1. **Redundancy**
   - Use ZRS or GRS for production
   - Implement geo-redundancy for critical data
   - Test failover procedures

2. **Security**
   - Disable public blob access
   - Use private endpoints
   - Enable firewall rules
   - Implement soft delete

3. **Performance**
   - Use Premium storage for high IOPS workloads
   - Enable large file shares when needed
   - Configure access tiers appropriately

### File Shares

1. Use Azure Files Premium for performance-intensive workloads
2. Implement snapshots for backup
3. Configure appropriate quota limits
4. Use SMB 3.0 with encryption

## Monitoring

### Diagnostic Settings

1. **Enable for All Resources**
   - Send logs to Log Analytics
   - Configure retention periods
   - Export to storage for long-term retention

2. **Log Categories**
   - Enable relevant log categories
   - Include metrics
   - Configure audit logs

### Azure Monitor

1. **Alerts**
   - Set up alerts for critical metrics
   - Use action groups for notifications
   - Implement auto-remediation where possible

2. **Workbooks**
   - Create custom workbooks for dashboards
   - Share across teams
   - Schedule regular reviews

3. **Application Insights**
   - Instrument applications
   - Configure availability tests
   - Set up dependency tracking

## Cost Optimization

### Resource Sizing

1. Right-size VMs based on actual usage
2. Use Azure Advisor recommendations
3. Implement auto-scaling
4. Use spot instances for dev/test

### Reservations

1. Purchase reserved instances for predictable workloads
2. Use Azure Hybrid Benefit for Windows/SQL Server
3. Consider savings plans for flexible commitments

### Tagging for Cost Management

```bicep
param tags object = {
  Environment: 'Production'
  CostCenter: 'IT-001'
  Owner: 'Shaun Hardneck'
  Project: 'WebApp'
  ManagedBy: 'thatlazyadmin.com'
}
```

### Lifecycle Management

1. Implement storage lifecycle policies
2. Delete unused resources regularly
3. Use auto-shutdown for dev/test VMs
4. Archive old data to cool/archive tiers

## Naming Conventions

Follow Cloud Adoption Framework (CAF) naming standards:

### Resource Types

- **Resource Group**: `rg-<workload>-<environment>-<region>-<###>`
- **Virtual Network**: `vnet-<workload>-<environment>-<region>-<###>`
- **Subnet**: `subnet-<workload>-<environment>-<###>`
- **VM**: `vm<workload><environment><###>`
- **Storage Account**: `st<workload><environment><###>`
- **AKS**: `aks-<workload>-<environment>-<region>-<###>`
- **Key Vault**: `kv-<workload>-<environment>-<region>-<###>`

### Examples

```text
rg-webapp-prod-eastus-001
vnet-webapp-prod-eastus-001
subnet-web-prod-001
vmwebprod001
stwebapprod001
aks-webapp-prod-eastus-001
kv-webapp-prod-eastus-001
```

## Tagging Strategy

### Required Tags

Every resource should have:

- **Environment**: `Dev`, `Staging`, `Production`
- **Owner**: Email or team name
- **CostCenter**: Department or cost center code
- **ManagedBy**: Tool or process managing the resource

### Optional Tags

- **Project**: Project or application name
- **ExpiryDate**: For temporary resources
- **Compliance**: Compliance requirements
- **DataClassification**: Data sensitivity level

### Implementation

```bicep
var commonTags = {
  Environment: environment
  Owner: 'Shaun Hardneck'
  CostCenter: 'IT-001'
  ManagedBy: 'thatlazyadmin.com'
  Project: projectName
  DeployedBy: 'Bicep'
  DeployedOn: utcNow('yyyy-MM-dd')
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  // ... rest of configuration
}
```

## Infrastructure as Code

### Template Organization

1. **Modularity**
   - Create reusable modules
   - One module per resource type
   - Use parameters for flexibility

2. **Parameters**
   - Use parameter files for environments
   - Store secrets in Key Vault
   - Provide sensible defaults

3. **Outputs**
   - Return resource IDs
   - Export connection strings
   - Provide FQDN/endpoints

### Version Control

1. Store templates in Git
2. Use branches for features
3. Implement pull request reviews
4. Tag releases

### CI/CD

1. Automate deployments with Azure DevOps or GitHub Actions
2. Implement what-if checks in pipelines
3. Use approval gates for production
4. Run linting and validation

## Documentation

1. **Module README**
   - Include usage examples
   - Document all parameters
   - List outputs
   - Provide troubleshooting tips

2. **Change Log**
   - Track template changes
   - Document breaking changes
   - Provide migration guides

3. **Architecture Diagrams**
   - Use draw.io or Visio
   - Keep diagrams up to date
   - Include network flows

## Compliance & Governance

### Azure Policy

1. Implement policies for:
   - Allowed locations
   - Required tags
   - SKU restrictions
   - Encryption requirements

2. Use policy initiatives for compliance frameworks
3. Set up remediation tasks
4. Audit non-compliant resources

### Blueprints

1. Define standards for workload deployment
2. Include role assignments
3. Add policy assignments
4. Version and track changes

## Backup & Disaster Recovery

1. **Backup Strategy**
   - Enable Azure Backup for VMs
   - Configure retention policies
   - Test restore procedures
   - Document RPO/RTO requirements

2. **Disaster Recovery**
   - Implement Azure Site Recovery
   - Test failover regularly
   - Document runbooks
   - Train team on procedures

## Security Baseline

1. Enable Microsoft Defender for Cloud
2. Implement security recommendations
3. Configure secure score goals
4. Regular security assessments

---

## Resources

- [Azure Cloud Adoption Framework](https://aka.ms/caf)
- [Azure Well-Architected Framework](https://aka.ms/waf)
- [Azure Verified Modules](https://aka.ms/avm)
- [Bicep Documentation](https://aka.ms/bicep)

---

**Author:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)
