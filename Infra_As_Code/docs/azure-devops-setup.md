# Azure DevOps Setup Guide

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Overview

This guide provides step-by-step instructions for setting up your Azure DevOps environment to work with this Infrastructure as Code repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Azure DevOps Project Setup](#azure-devops-project-setup)
- [Service Connections](#service-connections)
- [Variable Groups](#variable-groups)
- [Environments](#environments)
- [Pipeline Setup](#pipeline-setup)
- [Branch Policies](#branch-policies)
- [Security & Permissions](#security--permissions)

## Prerequisites

1. **Azure DevOps Organization**
   - Create an organization at [dev.azure.com](https://dev.azure.com)
   - Have appropriate permissions (Project Administrator or higher)

2. **Azure Subscription**
   - Active Azure subscription
   - Contributor or Owner role on the subscription

3. **Required Extensions**
   - Azure Pipelines (included by default)
   - Azure Repos (included by default)

## Azure DevOps Project Setup

### 1. Create a New Project

1. Navigate to your Azure DevOps organization
2. Click **New Project**
3. Configure project:
   - **Project name**: `InfrastructureAsCode` (or your preferred name)
   - **Visibility**: Private (recommended)
   - **Version control**: Git
   - **Work item process**: Agile

### 2. Import Repository

```bash
# Clone the repository locally
git clone <source-repository-url>
cd DeathStarScriptHub

# Add Azure DevOps remote
git remote add azdo https://dev.azure.com/{your-org}/{your-project}/_git/DeathStarScriptHub

# Push to Azure DevOps
git push azdo main
```

Or use Azure DevOps import feature:

1. Navigate to **Repos** → **Files**
2. Click **Import repository**
3. Enter repository URL
4. Click **Import**

## Service Connections

### Create Azure Resource Manager Service Connection

1. Navigate to **Project Settings** → **Service connections**
2. Click **New service connection**
3. Select **Azure Resource Manager**
4. Choose **Workload Identity federation (automatic)** (recommended)
5. Configure:
   - **Subscription**: Select your Azure subscription
   - **Resource group**: Leave empty for subscription-level access
   - **Service connection name**: `Azure-ServiceConnection`
   - **Grant access permission to all pipelines**: ✅ (or manage per pipeline)
6. Click **Save**

### Verify Service Connection

```yaml
# Test in a simple pipeline
trigger: none
pool:
  vmImage: 'ubuntu-latest'
steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: 'Azure-ServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az account show
        az group list --output table
```

## Variable Groups

### Create Infrastructure Variable Group

1. Navigate to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `infra-variables`
4. Add variables:

| Variable Name | Value | Secret |
|---------------|-------|--------|
| `devResourceGroup` | `rg-infra-dev-001` | No |
| `stagingResourceGroup` | `rg-infra-staging-001` | No |
| `prodResourceGroup` | `rg-infra-prod-001` | No |
| `location` | `eastus` | No |
| `environment` | `$(environmentName)` | No |

5. Click **Save**

### Link Variable Group to Pipeline

The pipeline (`azure-pipelines.yml`) already references the variable group:

```yaml
variables:
  - group: infra-variables
```

### Optional: Link to Azure Key Vault

For sensitive values (passwords, connection strings):

1. In the variable group, click **Link secrets from an Azure key vault**
2. Select your Azure subscription
3. Select Key Vault
4. Authorize and add secrets as variables

## Environments

### Create Deployment Environments

Environments enable deployment approvals and gates.

#### 1. Development Environment

1. Navigate to **Pipelines** → **Environments**
2. Click **New environment**
3. Configure:
   - **Name**: `Development`
   - **Description**: Development environment
   - **Resource**: None
4. Click **Create**

#### 2. Staging Environment

1. Create environment named `Staging`
2. Add approval check:
   - Click **Approvals and checks** (…)
   - Select **Approvals**
   - Add approvers (team leads, etc.)
   - Configure timeout and options
   - Click **Create**

#### 3. Production Environment

1. Create environment named `Production`
2. Add multiple checks:
   - **Approvals**: Add senior team members
   - **Branch control**: Restrict to `main` branch only
   - **Business hours**: Optional - deploy only during work hours
   - **Required reviewers**: Minimum number of approvals
3. Save all checks

## Pipeline Setup

### 1. Create Pipeline from Repository

1. Navigate to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select your repository
5. Select **Existing Azure Pipelines YAML file**
6. Choose `/Infra_As_Code/azure-pipelines.yml`
7. Click **Continue**
8. Review the pipeline
9. Click **Run**

### 2. Configure Pipeline Settings

1. Click **Edit** on the pipeline
2. Click the three dots (…) → **Settings**
3. Configure:
   - **Processing of new run requests**: Latest
   - **Badge enabled**: ✅
   - **Automatically link work items**: ✅

### 3. Pipeline Variables

Override variables for specific runs:

1. Click **Run pipeline**
2. Click **Variables**
3. Add/override variables as needed
4. Click **Run**

## Branch Policies

### Configure Branch Protection

1. Navigate to **Repos** → **Branches**
2. Find `main` branch, click **…** → **Branch policies**
3. Configure policies:

#### Require Pull Request Reviews

- ✅ **Require a minimum number of reviewers**: 2
- ✅ **Allow requestors to approve their own changes**: ❌
- ✅ **Prohibit the most recent pusher from approving**: ✅
- ✅ **Reset code reviewer votes when new changes**: ✅

#### Build Validation

- ✅ **Add build policy**
  - **Build pipeline**: Select your infrastructure pipeline
  - **Path filter**: `Infra_As_Code/**`
  - **Trigger**: Automatic
  - **Policy requirement**: Required
  - **Build expiration**: 12 hours

#### Status Checks

- ✅ **Require status checks to pass before merging**
- Add required checks (linting, security scanning, etc.)

#### Additional Settings

- ✅ **Check for linked work items**: Required
- ✅ **Check for comment resolution**: All active comments must be resolved
- ✅ **Limit merge types**: Squash merge only (recommended)

### Configure Develop Branch (Optional)

Repeat the above for `develop` branch with lighter policies:

- Minimum reviewers: 1
- Build validation: Required
- Less stringent approval requirements

## Security & Permissions

### Repository Permissions

1. Navigate to **Project Settings** → **Repositories**
2. Select your repository
3. Click **Security** tab
4. Configure permissions for groups:

**Contributors:**
- Read: Allow
- Contribute: Allow
- Create branch: Allow
- Contribute to pull requests: Allow
- Force push: Deny
- Manage permissions: Deny

**Build Service:**
- Read: Allow
- Contribute: Allow
- Create branch: Allow

### Pipeline Permissions

1. Navigate to **Pipelines** → Select pipeline → **…** → **Security**
2. Configure permissions:

**Contributors:**
- Queue builds: Allow
- Edit build pipeline: Allow
- Delete builds: Deny
- Administer build permissions: Deny

**Readers:**
- View builds: Allow
- View build pipeline: Allow

### Service Connection Permissions

1. Navigate to **Project Settings** → **Service connections**
2. Select your service connection
3. Click **Security**
4. Configure:
   - ✅ **Grant access permission to all pipelines**: For convenience
   - Or manually approve each pipeline

### Environment Approvals

Production environment approvals already configured in [Environments](#environments) section.

## CI/CD Workflow

### Continuous Integration (CI)

**Trigger:** Push to any branch

1. Validate all Bicep templates
2. Run linting checks
3. Build and publish artifacts
4. Block PR if validation fails

### Continuous Deployment (CD)

**Development:**
- Trigger: Push to `develop` branch
- Automatic deployment
- No approvals required

**Staging:**
- Trigger: Push to `main` branch
- What-if analysis
- Approval required
- Deploy to staging environment

**Production:**
- Trigger: After successful staging deployment
- Multiple approvals required
- Branch policy: `main` only
- Deploy to production environment

## Pipeline Customization

### Add Custom Stages

Edit `azure-pipelines.yml`:

```yaml
- stage: CustomStage
  displayName: 'Custom Stage'
  dependsOn: Validate
  jobs:
    - job: CustomJob
      displayName: 'Custom Job'
      pool:
        vmImage: 'ubuntu-latest'
      steps:
        - task: AzureCLI@2
          displayName: 'Custom Step'
          inputs:
            azureSubscription: $(azureServiceConnection)
            scriptType: 'bash'
            scriptLocation: 'inlineScript'
            inlineScript: |
              echo "Custom step"
```

### Add Security Scanning

```yaml
- stage: SecurityScan
  displayName: 'Security Scanning'
  dependsOn: Validate
  jobs:
    - job: ScanTemplates
      displayName: 'Scan Bicep Templates'
      pool:
        vmImage: 'ubuntu-latest'
      steps:
        - task: PowerShell@2
          displayName: 'Run PSRule for Azure'
          inputs:
            targetType: 'inline'
            script: |
              Install-Module -Name PSRule.Rules.Azure -Force -Scope CurrentUser
              Assert-PSRule -InputPath '$(workingDirectory)' -Module PSRule.Rules.Azure
```

## Troubleshooting

### Pipeline Fails at Service Connection

**Problem:** Service connection authentication fails

**Solution:**
1. Verify service connection has correct permissions
2. Check subscription access
3. Recreate service connection if needed

### Variable Group Not Found

**Problem:** Pipeline can't find variable group

**Solution:**
1. Verify variable group name matches YAML
2. Grant pipeline access to variable group
3. Check variable group exists in correct project

### Environment Not Found

**Problem:** Deployment stage fails to find environment

**Solution:**
1. Create environment in Azure DevOps
2. Ensure environment name matches YAML exactly
3. Grant pipeline access to environment

## Best Practices

1. **Use Workload Identity Federation** for service connections (no secrets)
2. **Enable branch policies** on main branches
3. **Require approvals** for production deployments
4. **Use variable groups** for environment-specific values
5. **Store secrets in Azure Key Vault** and link to variable groups
6. **Implement what-if** checks before production deployments
7. **Use environments** for deployment tracking and approvals
8. **Tag pipeline runs** with version numbers
9. **Enable build badges** for visibility
10. **Set up notifications** for failed deployments

## Notifications

### Configure Email Notifications

1. Navigate to **Project Settings** → **Notifications**
2. Click **New subscription**
3. Configure:
   - **Category**: Build
   - **Template**: Build completes
   - **Filter**: Your pipeline
   - **Deliver to**: Your email or team channel
4. Save

### Teams/Slack Integration

1. Install Azure Pipelines app in Teams/Slack
2. Subscribe to pipeline notifications
3. Configure alerts for failures

## Resources

- [Azure Pipelines Documentation](https://learn.microsoft.com/azure/devops/pipelines/)
- [YAML Schema Reference](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema)
- [Service Connections](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints)
- [Environments](https://learn.microsoft.com/azure/devops/pipelines/process/environments)

---

**Author:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)
