<#
.SYNOPSIS
    Cleanup Azure resources in a resource group.

.DESCRIPTION
    This script deletes a resource group and all its resources.
    Created by: Shaun Hardneck
    Website: thatlazyadmin.com

.PARAMETER ResourceGroup
    Name of the resource group to delete.

.PARAMETER Force
    Skip confirmation prompt.

.EXAMPLE
    ./cleanup.ps1 -ResourceGroup "rg-demo" -Force

.NOTES
    Author: Shaun Hardneck
    Website: thatlazyadmin.com
    WARNING: This operation is irreversible!
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Red
Write-Host "Azure Resource Cleanup Script" -ForegroundColor Red
Write-Host "Created by: Shaun Hardneck" -ForegroundColor Cyan
Write-Host "Website: thatlazyadmin.com" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: This will delete ALL resources in the resource group!" -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host ""

# Check if resource group exists
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "Resource group '$ResourceGroup' does not exist." -ForegroundColor Yellow
    exit 0
}

# List resources in the group
Write-Host "Resources in '$ResourceGroup':" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroup --output table

# Confirm deletion
if (-not $Force) {
    Write-Host ""
    $confirmation = Read-Host "Are you sure you want to delete this resource group and all its resources? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Delete resource group
Write-Host "`nDeleting resource group '$ResourceGroup'..." -ForegroundColor Yellow
try {
    az group delete --name $ResourceGroup --yes --no-wait
    Write-Host "✓ Deletion initiated (running in background)" -ForegroundColor Green
    Write-Host "  You can check the status with: az group show --name $ResourceGroup" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to delete resource group: $_"
    exit 1
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Cleanup script completed" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
