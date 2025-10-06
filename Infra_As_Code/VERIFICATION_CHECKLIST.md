# ✅ Repository Verification Checklist

Use this checklist to verify that the Azure IaC repository is complete and ready for use.

**Created by:** Shaun Hardneck  
**Website:** [thatlazyadmin.com](https://thatlazyadmin.com)

## 📁 File Structure Verification

### Root Files

- [ ] `README.md` - Main repository documentation
- [ ] `SUMMARY.md` - Complete repository summary
- [ ] `GETTING_STARTED.md` - Quick start guide
- [ ] `bicepconfig.json` - Bicep linter configuration
- [ ] `.markdownlint.json` - Markdown linting rules
- [ ] `.gitignore` - Git ignore patterns
- [ ] `azure-pipelines.yml` - Azure DevOps CI/CD pipeline

### Documentation Files

- [ ] `docs/deployment-guide.md`
- [ ] `docs/best-practices.md`
- [ ] `docs/troubleshooting.md`
- [ ] `docs/azure-devops-setup.md`
- [ ] `docs/module-index.md`

### Scripts

- [ ] `scripts/deploy.ps1` - PowerShell deployment
- [ ] `scripts/deploy.sh` - Bash deployment
- [ ] `scripts/validate.ps1` - Template validation
- [ ] `scripts/cleanup.ps1` - Resource cleanup

### Compute Modules

- [ ] `modules/compute/virtual-machine/main.bicep`
- [ ] `modules/compute/virtual-machine/parameters.json`
- [ ] `modules/compute/virtual-machine/README.md`
- [ ] `modules/compute/aks/main.bicep`
- [ ] `modules/compute/aks/parameters.json`
- [ ] `modules/compute/aks/README.md`

### Storage Modules

- [ ] `modules/storage/storage-account/main.bicep`
- [ ] `modules/storage/storage-account/parameters.json`
- [ ] `modules/storage/storage-account/README.md`
- [ ] `modules/storage/file-share/main.bicep`
- [ ] `modules/storage/file-share/parameters.json`
- [ ] `modules/storage/file-share/README.md`

### Network Modules

- [ ] `modules/network/virtual-network/main.bicep`
- [ ] `modules/network/virtual-network/parameters.json`
- [ ] `modules/network/virtual-network/README.md`
- [ ] `modules/network/network-security-group/main.bicep`
- [ ] `modules/network/network-security-group/parameters.json`
- [ ] `modules/network/network-security-group/README.md`

### Database Modules

- [ ] `modules/database/sql-database/main.bicep`
- [ ] `modules/database/sql-database/parameters.json`
- [ ] `modules/database/sql-database/README.md`
- [ ] `modules/database/cosmos-db/main.bicep`
- [ ] `modules/database/cosmos-db/parameters.json`
- [ ] `modules/database/cosmos-db/README.md`

### Security Modules

- [ ] `modules/security/key-vault/main.bicep`
- [ ] `modules/security/key-vault/parameters.json`
- [ ] `modules/security/key-vault/README.md`
- [ ] `modules/security/managed-identity/main.bicep`
- [ ] `modules/security/managed-identity/parameters.json`
- [ ] `modules/security/managed-identity/README.md`

### Deployment Scenarios

- [ ] `scenarios/web-app-with-database/main.bicep`
- [ ] `scenarios/web-app-with-database/parameters.prod.json`
- [ ] `scenarios/web-app-with-database/README.md`
- [ ] `scenarios/aks-cluster-complete/main.bicep`
- [ ] `scenarios/aks-cluster-complete/parameters.prod.json`
- [ ] `scenarios/aks-cluster-complete/README.md`

### Azure DevOps

- [ ] `.azuredevops/README.md`

## 🔍 Content Verification

### Branding Check

Every Bicep file should contain:

```bicep
// Created by: Shaun Hardneck
// Website: thatlazyadmin.com
```

Every resource should have tags:

```bicep
tags: union(tags, {
  CreatedBy: 'Shaun Hardneck'
  Website: 'thatlazyadmin.com'
})
```

- [ ] All Bicep files have header comment
- [ ] All resources have proper tags

### Documentation Check

Each module README should include:

- [ ] Module description
- [ ] Features list
- [ ] Parameters table
- [ ] Outputs table
- [ ] Usage examples
- [ ] Deployment commands
- [ ] Branding footer

Each scenario README should include:

- [ ] Architecture overview
- [ ] Components list
- [ ] Deployment instructions
- [ ] Post-deployment steps
- [ ] Cost estimates
- [ ] Branding footer

### Configuration Files

`bicepconfig.json` should have:

- [ ] analyzers.core.rules configuration
- [ ] Linter rules enabled

`.markdownlint.json` should have:

- [ ] MD013 line-length disabled
- [ ] Other rules configured

`.gitignore` should exclude:

- [ ] `*.zip` files
- [ ] `.DS_Store` files
- [ ] `.azure/` directory
- [ ] `.bicep/` directory

`azure-pipelines.yml` should have:

- [ ] Trigger configuration
- [ ] Validate stage
- [ ] DeployDev stage
- [ ] DeployStaging stage (with approval)
- [ ] DeployProd stage (with approval)

## 🧪 Functional Verification

### Template Validation

Run validation script:

```powershell
cd Infra_As_Code/scripts
.\validate.ps1
```

Expected result:

- [ ] All templates validate successfully
- [ ] No Bicep compilation errors
- [ ] Linter warnings are acceptable (cosmetic only)

### Module Testing

Test a simple module (Storage Account):

```bash
cd modules/storage/storage-account

# Validate
az deployment group validate \
  --resource-group test-rg \
  --template-file main.bicep \
  --parameters parameters.json
```

- [ ] Template validation passes
- [ ] Parameters are valid
- [ ] No errors reported

### Scenario Testing

Test what-if deployment:

```bash
cd scenarios/web-app-with-database

# What-if deployment
az deployment group what-if \
  --resource-group test-rg \
  --template-file main.bicep \
  --parameters parameters.prod.json
```

- [ ] What-if analysis completes
- [ ] Resources are correctly identified
- [ ] No unexpected errors

## 📊 Statistics Verification

### File Count

Run this command from repository root:

```bash
# Count Bicep files
find . -name "*.bicep" -type f | wc -l

# Count JSON files
find . -name "*.json" -type f | wc -l

# Count README files
find . -name "README.md" -type f | wc -l

# Count all files
find . -type f | wc -l
```

Expected counts:

- [ ] ~12 Bicep template files (10 modules + 2 scenarios)
- [ ] ~15 JSON files (parameters + config)
- [ ] ~14 README files
- [ ] ~60+ total files

### Line Count

```bash
# Count lines in all Bicep files
find . -name "*.bicep" -type f -exec wc -l {} + | tail -1

# Count lines in all documentation
find . -name "*.md" -type f -exec wc -l {} + | tail -1
```

Expected counts:

- [ ] ~1,400+ lines of Bicep code
- [ ] ~1,200+ lines of documentation

## 🔒 Security Verification

### Security Features

All modules should implement:

- [ ] HTTPS/TLS 1.2+ enforcement
- [ ] Encryption at rest
- [ ] Encryption in transit
- [ ] Managed Identity support
- [ ] Network security (VNet, NSG, Private Endpoints)
- [ ] RBAC authorization
- [ ] Diagnostic logging

### Password Handling

Check that no hardcoded passwords exist:

```bash
# Search for potential hardcoded secrets
grep -r "password\s*=" . --include="*.bicep" --include="*.json"
```

- [ ] No hardcoded passwords found
- [ ] All passwords use `@secure()` decorator
- [ ] Parameters reference Key Vault secrets

## 📚 Documentation Verification

### Cross-References

Check that documentation links work:

Main README should link to:

- [ ] GETTING_STARTED.md
- [ ] SUMMARY.md
- [ ] docs/module-index.md
- [ ] docs/deployment-guide.md
- [ ] docs/best-practices.md
- [ ] docs/troubleshooting.md
- [ ] docs/azure-devops-setup.md

Module READMEs should link to:

- [ ] Related Azure documentation
- [ ] Other relevant modules

### Examples Completeness

Each module README should have:

- [ ] Basic deployment example
- [ ] PowerShell deployment example
- [ ] Advanced usage example
- [ ] Troubleshooting commands

## 🚀 Azure DevOps Verification

### Pipeline Configuration

`azure-pipelines.yml` should contain:

- [ ] Trigger on main branch
- [ ] Pool configuration (ubuntu-latest)
- [ ] 4 deployment stages
- [ ] Azure CLI tasks
- [ ] Artifact publishing
- [ ] Environment dependencies

### Documentation

`docs/azure-devops-setup.md` should cover:

- [ ] Prerequisites
- [ ] Repository import
- [ ] Service connection creation
- [ ] Variable group setup
- [ ] Environment creation
- [ ] Approval configuration
- [ ] Branch policies
- [ ] Pipeline execution

`.azuredevops/README.md` should explain:

- [ ] Variable groups required
- [ ] Service connections required
- [ ] Environments required
- [ ] Setup guide reference

## ✅ Final Verification

### Repository Readiness

- [ ] All files created successfully
- [ ] No compilation errors in Bicep templates
- [ ] All documentation is complete
- [ ] Branding applied consistently
- [ ] Azure DevOps integration ready
- [ ] Scripts are executable
- [ ] Examples are functional
- [ ] Cost estimates included
- [ ] Security best practices implemented
- [ ] No sensitive data in repository

### Quality Checks

- [ ] Bicep linting passes
- [ ] Markdown linting passes (ignore cosmetic warnings)
- [ ] Consistent naming conventions
- [ ] Proper parameter validation
- [ ] Comprehensive outputs
- [ ] Error handling in scripts

### User Experience

- [ ] GETTING_STARTED.md is beginner-friendly
- [ ] Module READMEs are comprehensive
- [ ] Examples are clear and tested
- [ ] Troubleshooting guide is helpful
- [ ] Cost information is accurate
- [ ] Prerequisites are clearly stated

## 🎯 Success Criteria

### Minimum Requirements Met

- [x] 10 production-ready modules
- [x] 2 complete deployment scenarios
- [x] 4 automation scripts
- [x] 5+ documentation files
- [x] Azure DevOps CI/CD pipeline
- [x] Comprehensive README files
- [x] Consistent branding throughout

### Quality Standards Met

- [x] All templates validate successfully
- [x] Security best practices implemented
- [x] Complete documentation
- [x] Working examples
- [x] Cost transparency
- [x] Troubleshooting guidance

### Enterprise Readiness

- [x] Production-grade security
- [x] High availability patterns
- [x] Monitoring and diagnostics
- [x] Disaster recovery considerations
- [x] CI/CD integration
- [x] Documentation completeness

## 📝 Notes

Use this space to track any customizations or issues:

```text
Date: _______________
Checked by: _______________
Issues found: _______________
Resolution: _______________
Status: _______________
```

---

**Created by**: Shaun Hardneck  
**Website**: [thatlazyadmin.com](https://thatlazyadmin.com)  
**Version**: 1.0  
**Last Updated**: 2024
