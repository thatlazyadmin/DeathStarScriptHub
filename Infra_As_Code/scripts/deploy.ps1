<#
.SYNOPSIS
    Deployment script for Azure resources using Bicep templates.

.DESCRIPTION
    This script deploys Azure resources using Bicep templates with parameter files.
    Created by: Shaun Hardneck
    Website: thatlazyadmin.com

.PARAMETER ResourceGroup
    Name of the resource group to deploy to.

.PARAMETER TemplateFile
    Path to the Bicep template file.

.PARAMETER ParameterFile
    Path to the parameters file (optional).

.PARAMETER Location
    Azure region for deployment (required if resource group doesn't exist).

.PARAMETER WhatIf
    Run deployment in what-if mode to preview changes.

.EXAMPLE
    ./deploy.ps1 -ResourceGroup "rg-prod-001" -TemplateFile "modules/storage/storage-account/main.bicep" -ParameterFile "modules/storage/storage-account/parameters.json"

.NOTES
    Author: Shaun Hardneck
    Website: thatlazyadmin.com
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$TemplateFile,

    [Parameter(Mandatory = $false)]
    [string]$ParameterFile,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Banner
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Azure Bicep Deployment Script" -ForegroundColor Cyan
Write-Host "Created by: Shaun Hardneck" -ForegroundColor Cyan
Write-Host "Website: thatlazyadmin.com" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Validate Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✓ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed. Please install it from https://aka.ms/installazurecli"
    exit 1
}

# Validate Bicep is installed
try {
    $bicepVersion = az bicep version
    Write-Host "✓ Bicep version: $bicepVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing Bicep..." -ForegroundColor Yellow
    az bicep install
}

# Check if logged in to Azure
Write-Host "`nChecking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Not logged in to Azure. Initiating login..." -ForegroundColor Yellow
    az login
} else {
    $accountInfo = $account | ConvertFrom-Json
    Write-Host "✓ Logged in as: $($accountInfo.user.name)" -ForegroundColor Green
    Write-Host "✓ Subscription: $($accountInfo.name) ($($accountInfo.id))" -ForegroundColor Green
}

# Validate template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    exit 1
}
Write-Host "✓ Template file found: $TemplateFile" -ForegroundColor Green

# Validate parameter file if provided
if ($ParameterFile) {
    if (-not (Test-Path $ParameterFile)) {
        Write-Error "Parameter file not found: $ParameterFile"
        exit 1
    }
    Write-Host "✓ Parameter file found: $ParameterFile" -ForegroundColor Green
}

# Check if resource group exists
Write-Host "`nChecking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "Resource group '$ResourceGroup' does not exist. Creating..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location
    Write-Host "✓ Resource group created successfully" -ForegroundColor Green
} else {
    Write-Host "✓ Resource group '$ResourceGroup' exists" -ForegroundColor Green
}

# Build deployment command
Write-Host "`nPreparing deployment..." -ForegroundColor Yellow
$deploymentName = "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$deployCmd = "az deployment group create ``
    --name $deploymentName ``
    --resource-group $ResourceGroup ``
    --template-file `"$TemplateFile`""

if ($ParameterFile) {
    $deployCmd += " ``
    --parameters `"@$ParameterFile`""
}

if ($WhatIf) {
    $deployCmd += " ``
    --what-if"
    Write-Host "`n Running in WHAT-IF mode (no changes will be made)" -ForegroundColor Magenta
}

Write-Host "`nDeployment command:" -ForegroundColor Cyan
Write-Host $deployCmd -ForegroundColor Gray

# Execute deployment
Write-Host "`nStarting deployment..." -ForegroundColor Yellow
Write-Host "Deployment name: $deploymentName" -ForegroundColor Cyan

try {
    Invoke-Expression $deployCmd
    
    if ($WhatIf) {
        Write-Host "`n✓ What-if analysis completed successfully" -ForegroundColor Green
    } else {
        Write-Host "`n✓ Deployment completed successfully" -ForegroundColor Green
        
        # Get deployment outputs
        Write-Host "`nRetrieving deployment outputs..." -ForegroundColor Yellow
        $outputs = az deployment group show `
            --name $deploymentName `
            --resource-group $ResourceGroup `
            --query properties.outputs `
            --output json | ConvertFrom-Json
        
        if ($outputs) {
            Write-Host "`nDeployment Outputs:" -ForegroundColor Cyan
            $outputs | ConvertTo-Json -Depth 10
        }
    }
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Deployment script completed" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
