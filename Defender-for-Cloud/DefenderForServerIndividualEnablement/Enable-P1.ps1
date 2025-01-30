<#
.SYNOPSIS
    Manage Defender for Servers at the individual VM level.
    
.DESCRIPTION
    This script allows enabling, disabling, and excluding individual Azure VMs from Defender for Servers 
    using the new Microsoft Defender for Cloud API. It supports:
    
    - Enabling Defender for Servers Plan 1 (P1) for a specific VM.
    - Disabling Defender for Servers for a VM.
    - Excluding a VM from Defender coverage when the subscription-level plan is enabled.

    Previously, Defender for Servers was managed only at the subscription level, but Microsoft 
    now allows enabling/disabling at the resource level.

.AUTHOR
    Shaun Hardneck - ThatLazyAdmin | www.thatlazyadmin.com

.VERSION
    1.0 - Initial release with individual VM management for Defender for Servers.

.LICENSE
    MIT License - Use at your own risk. No warranties provided.
#>

# ================================[ BANNER ]=================================
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      Defender for Servers Management Script" -ForegroundColor Yellow
Write-Host "   Created by Shaun Hardneck - That Lazy Admin" -ForegroundColor Green
Write-Host "     www.thatlazyadmin.com | Microsoft Defender" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "`n"

# Check if user is logged into Azure
$needLogin = $true
Try {
    $content = Get-AzContext
    if ($content) {
        $needLogin = ([string]::IsNullOrEmpty($content.Account))
    }
} Catch {
    if ($_ -like "*Login-AzAccount to login*") {
        $needLogin = $true
    } else {
        throw
    }
}

if ($needLogin) {
    Write-Host -ForegroundColor "yellow" "Need to log in now! Look for login window!"
    Connect-AzAccount
}

# Get Azure Access Token
$accessToken = Get-AzAccessToken | Select-Object -ExpandProperty token

# Get user inputs
$subscriptionId = Read-Host "Enter your Azure Subscription ID"
$resourceGroup = Read-Host "Enter the Resource Group Name"
$vmName = Read-Host "Enter the Virtual Machine Name"

# Validate if VM exists
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -ErrorAction SilentlyContinue

if (-not $vm) {
    Write-Host "VM '$vmName' not found in Resource Group '$resourceGroup'. Please check the name and try again." -ForegroundColor Red
    exit 1
}

Write-Host "`nFound VM: $($vmName) in Resource Group: $($resourceGroup)" -ForegroundColor Green
Write-Host "Location: $($vm.Location)" -ForegroundColor Green

# Set API URL
$pricingUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"

# Prompt user for action
$PricingTier = Read-Host "Enter 'Enable-P1' to enable Defender for Servers P1, 'Disable' to remove Defender protection, or 'Exclude' to exclude this VM if Defender is set at the subscription level"

while ($PricingTier.ToLower() -notin @("enable-p1", "disable", "exclude")) {
    $PricingTier = Read-Host "Invalid input. Enter 'Enable-P1', 'Disable', or 'Exclude'"
}

# Prepare API request body
if ($PricingTier.ToLower() -eq "enable-p1") {
    $body = @{
        location   = $vm.Location
        properties = @{
            pricingTier = "Standard"
            subPlan     = "P1"
        }
    } | ConvertTo-Json -Depth 10
} elseif ($PricingTier.ToLower() -eq "disable") {
    $body = @{
        location   = $vm.Location
        properties = @{
            pricingTier = "Free"
        }
    } | ConvertTo-Json -Depth 10
} elseif ($PricingTier.ToLower() -eq "exclude") {
    Write-Host "`nExcluding VM from Defender for Servers..." -ForegroundColor Yellow
    try {
        Invoke-RestMethod -Method Delete -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json"
        Write-Host "✅ Successfully excluded VM '$vmName' from Defender for Servers." -ForegroundColor Green
        exit 0
    } catch {
        Write-Host "❌ Failed to exclude VM '$vmName'" -ForegroundColor Red
        Write-Host "Error: $_.Exception.Message"
        exit 1
    }
}

# Execute API call
Write-Host "`nProcessing Defender for Servers action for VM '$vmName'..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Method Put -Uri $pricingUrl -Body $body -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json"
    Write-Host "✅ Successfully updated Defender for Servers configuration for VM '$vmName'" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update Defender for Servers" -ForegroundColor Red
    Write-Host "Error: $_.Exception.Message"
}

# ================================[ END OF SCRIPT ]=================================
Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "     Script execution completed. Review output above." -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "`n"
