# Azure Cosmos DB Module

Deploy Azure Cosmos DB with multi-region replication and enterprise security.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Features

- Multi-API support (SQL, MongoDB, Cassandra, Gremlin, Table)
- Multi-region replication with automatic failover
- Serverless and provisioned throughput options
- Analytical storage integration
- Advanced security with firewall and VNet rules
- Automated backups with geo-redundancy
- Diagnostic logging to Log Analytics
- Zone redundancy support

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `accountName` | string | Cosmos DB account name (globally unique) | Required |
| `location` | string | Azure region | `resourceGroup().location` |
| `databaseApiType` | string | API type (Sql, MongoDB, Cassandra, Gremlin, Table) | `Sql` |
| `consistencyLevel` | string | Consistency level | `Session` |
| `enableAutomaticFailover` | bool | Enable automatic failover | `true` |
| `enableMultipleWriteLocations` | bool | Enable multi-region writes | `false` |
| `enableServerless` | bool | Enable serverless mode | `false` |
| `enableFreeTier` | bool | Enable free tier | `false` |
| `locations` | array | Replication locations | Single region |
| `enableAnalyticalStorage` | bool | Enable analytical storage | `false` |
| `publicNetworkAccess` | string | Public network access (Enabled/Disabled) | `Enabled` |
| `ipRules` | array | IP firewall rules | `[]` |
| `virtualNetworkRules` | array | VNet rules | `[]` |
| `enableBackup` | bool | Enable automated backup | `true` |
| `backupStorageRedundancy` | string | Backup redundancy (Geo/Local/Zone) | `Geo` |
| `backupIntervalInMinutes` | int | Backup interval | `240` |
| `backupRetentionIntervalInHours` | int | Backup retention | `8` |
| `enableDiagnostics` | bool | Enable diagnostic settings | `true` |
| `logAnalyticsWorkspaceId` | string | Log Analytics workspace ID | `''` |
| `tags` | object | Resource tags | `{}` |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `accountName` | string | Cosmos DB account name |
| `accountId` | string | Cosmos DB account resource ID |
| `endpoint` | string | Cosmos DB endpoint URL |
| `primaryKey` | string | Primary master key (secure) |
| `secondaryKey` | string | Secondary master key (secure) |
| `connectionString` | string | Connection string (secure) |

## Usage

### Basic SQL API Deployment

```bash
az deployment group create \
  --resource-group rg-cosmos-prod \
  --template-file main.bicep \
  --parameters parameters.json
```

### Multi-Region Deployment

```bicep
module cosmosDb 'modules/database/cosmos-db/main.bicep' = {
  name: 'cosmosDb'
  params: {
    accountName: 'cosmos-myapp-prod'
    location: 'eastus'
    databaseApiType: 'Sql'
    consistencyLevel: 'Session'
    enableAutomaticFailover: true
    locations: [
      {
        locationName: 'eastus'
        failoverPriority: 0
        isZoneRedundant: true
      }
      {
        locationName: 'westus'
        failoverPriority: 1
        isZoneRedundant: true
      }
      {
        locationName: 'northeurope'
        failoverPriority: 2
        isZoneRedundant: false
      }
    ]
    enableDiagnostics: true
    logAnalyticsWorkspaceId: logAnalytics.id
    tags: {
      Environment: 'Production'
      Application: 'MyApp'
    }
  }
}
```

### MongoDB API with VNet Integration

```bicep
module cosmosDb 'modules/database/cosmos-db/main.bicep' = {
  name: 'cosmosDb'
  params: {
    accountName: 'cosmos-mongodb-prod'
    databaseApiType: 'MongoDB'
    consistencyLevel: 'Strong'
    publicNetworkAccess: 'Disabled'
    virtualNetworkRules: [
      {
        id: subnet.id
        ignoreMissingVNetServiceEndpoint: false
      }
    ]
    enableBackup: true
    backupStorageRedundancy: 'Geo'
  }
}
```

### Serverless Deployment

```bicep
module cosmosDb 'modules/database/cosmos-db/main.bicep' = {
  name: 'cosmosDb'
  params: {
    accountName: 'cosmos-serverless-dev'
    databaseApiType: 'Sql'
    enableServerless: true
    consistencyLevel: 'Session'
    locations: [
      {
        locationName: 'eastus'
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}
```

## API Types

### SQL (Core) API

- Document database with SQL query language
- Best for: New applications, JSON documents
- Supports: Change feed, stored procedures, triggers

### MongoDB API

- MongoDB wire protocol compatibility
- Best for: Existing MongoDB applications
- Supports: MongoDB 3.6, 4.0, 4.2, 5.0

### Cassandra API

- Apache Cassandra wire protocol compatibility
- Best for: Existing Cassandra applications
- Supports: CQL query language

### Gremlin (Graph) API

- Graph database with Gremlin query language
- Best for: Graph data, relationship queries
- Supports: Apache TinkerPop

### Table API

- Azure Table Storage compatibility
- Best for: Existing Table Storage applications
- Supports: Premium table storage

## Consistency Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| **Strong** | Linearizability guarantee | Critical consistency requirements |
| **Bounded Staleness** | Bounded by time/operations | Consistent reads with lag tolerance |
| **Session** | Consistent within session | Default, best balance |
| **Consistent Prefix** | Reads never see out-of-order writes | Social feeds, comments |
| **Eventual** | Highest availability | Analytics, metrics |

## Security Best Practices

1. **Network Security**
   - Use VNet service endpoints or private endpoints
   - Configure IP firewall rules
   - Disable public network access for production

2. **Authentication**
   - Use managed identities instead of keys
   - Rotate keys regularly
   - Use Azure AD authentication (SQL API)

3. **Encryption**
   - Data encrypted at rest by default
   - Data encrypted in transit (TLS 1.2+)
   - Consider customer-managed keys

4. **Monitoring**
   - Enable diagnostic logs
   - Monitor RU consumption
   - Set up alerts for throttling

## Troubleshooting

### Check Account Status

```bash
az cosmosdb show \
  --resource-group <resource-group> \
  --name <account-name>
```

### List Connection Strings

```bash
az cosmosdb keys list \
  --resource-group <resource-group> \
  --name <account-name> \
  --type connection-strings
```

### Monitor Request Units

```bash
az monitor metrics list \
  --resource <account-id> \
  --metric TotalRequestUnits \
  --interval PT1M
```

## Related Resources

- [Azure Cosmos DB Documentation](https://docs.microsoft.com/azure/cosmos-db/)
- [Cosmos DB Security](https://docs.microsoft.com/azure/cosmos-db/database-security)
- [Cosmos DB Pricing](https://azure.microsoft.com/pricing/details/cosmos-db/)
- [Capacity Calculator](https://cosmos.azure.com/capacitycalculator/)
