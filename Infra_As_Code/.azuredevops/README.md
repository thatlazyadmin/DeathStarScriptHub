# Azure DevOps Configuration Files

This directory contains Azure DevOps-specific configuration files.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## Files

### azure-pipelines.yml (Root)

Main CI/CD pipeline for infrastructure deployment:
- **Validation**: Validates all Bicep templates
- **Development**: Auto-deploys to dev environment
- **Staging**: Deploys to staging with what-if analysis
- **Production**: Deploys to production with approval gates

### Variable Groups Required

Create the following variable group in Azure DevOps:

**infra-variables:**
- `devResourceGroup`: Development resource group name
- `stagingResourceGroup`: Staging resource group name
- `prodResourceGroup`: Production resource group name
- `location`: Azure region for deployments

### Service Connections Required

Create an Azure Resource Manager service connection:
- **Name**: `Azure-ServiceConnection`
- **Type**: Workload Identity federation (automatic)
- **Scope**: Subscription level

### Environments Required

Create the following environments in Azure DevOps:
1. **Development** - No approvals
2. **Staging** - Requires 1 approval
3. **Production** - Requires 2 approvals + branch control

## Setup Guide

See [Azure DevOps Setup Guide](../docs/azure-devops-setup.md) for detailed instructions.
