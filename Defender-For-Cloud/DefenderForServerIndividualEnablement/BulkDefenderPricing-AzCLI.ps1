# ================================[ BANNER ]=================================
Clear-Host
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "             Defender for Servers Bulk Pricing Management           " -ForegroundColor Yellow
Write-Host "               Created by Shaun Hardneck - Marcus Burnap           " -ForegroundColor Green
Write-Host "              www.thatlazyadmin.com - www.MBCloudteck.com | Microsoft Defender           " -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "`n"

# ================================[ AUTHENTICATION ]=================================
Write-Host "Azure Cloud Shell (or CLI) is already authenticated." -ForegroundColor Green
$accessToken = az account get-access-token --resource=https://management.azure.com/ --query accessToken -o tsv
$expireson   = az account get-access-token --resource=https://management.azure.com/ --query expiresOn -o tsv

if (-not $accessToken) {
    Write-Host "ERROR: Failed to retrieve Azure CLI access token. Please check your session." -ForegroundColor Red
    exit 1
}
Write-Host "Successfully retrieved Azure CLI access token." -ForegroundColor Green
Write-Host "`n"

# ================================[ USER INPUTS ]=================================
$SubscriptionId = Read-Host "Enter your SubscriptionId"
$mode = Read-Host "Enter 'RG' to set pricing for all resources under a given Resource Group, or 'TAG' to set pricing for all resources with a given tagName and tagValue"
while($mode.ToLower() -ne "rg" -and $mode.ToLower() -ne "tag"){
    $mode = Read-Host "Enter 'RG' to set pricing for all resources under a given Resource Group, or 'TAG' to set pricing for all resources with a given tagName and tagValue"
}

$vmResponseMachines   = @()
$vmssResponseMachines = @()
$arcResponseMachines  = @()
$vmCount = 0; $vmssCount = 0; $arcCount = 0

if ($mode.ToLower() -eq "rg") {
    $resourceGroupName = Read-Host "Enter the name of the resource group"
    try {
        # Get all virtual machines, VMSSs, and ARC machines in the resource group
        $vmUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines?api-version=2021-04-01"
        do {
            $vmResponse = Invoke-RestMethod -Method Get -Uri $vmUrl -Headers @{Authorization = "Bearer $accessToken"}
            $vmResponseMachines += $vmResponse.value
            $vmUrl = $vmResponse.nextLink
        } while (![string]::IsNullOrEmpty($vmUrl))

        $vmssUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachineScaleSets?api-version=2021-04-01"
        do {
            $vmssResponse = Invoke-RestMethod -Method Get -Uri $vmssUrl -Headers @{Authorization = "Bearer $accessToken"}
            $vmssResponseMachines += $vmssResponse.value
            $vmssUrl = $vmssResponse.nextLink
        } while (![string]::IsNullOrEmpty($vmssUrl))

        $arcUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines?api-version=2022-12-27"
        do {
            $arcResponse = Invoke-RestMethod -Method Get -Uri $arcUrl -Headers @{Authorization = "Bearer $accessToken"}
            $arcResponseMachines += $arcResponse.value
            $arcUrl = $arcResponse.nextLink
        } while (![string]::IsNullOrEmpty($arcUrl))
    }
    catch {
        Write-Host "Failed to Get resources! " -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
} elseif ($mode.ToLower() -eq "tag") {
    $tagName  = Read-Host "Enter the name of the tag"
    $tagValue = Read-Host "Enter the value of the tag"
    try {
        # Get all virtual machines, VMSSs, and ARC machines in the subscription based on the given tag
        $vmUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resources?`$filter=resourceType eq 'Microsoft.Compute/virtualMachines'&api-version=2021-04-01"
        do {
            $vmResponse = Invoke-RestMethod -Method Get -Uri $vmUrl -Headers @{Authorization = "Bearer $accessToken"}
            $vmResponseMachines += $vmResponse.value | Where-Object { $_.tags.$tagName -eq $tagValue }
            $vmUrl = $vmResponse.nextLink
        } while (![string]::IsNullOrEmpty($vmUrl))

        $vmssUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resources?`$filter=resourceType eq 'Microsoft.Compute/virtualMachineScaleSets'&api-version=2021-04-01"
        do {
            $vmssResponse = Invoke-RestMethod -Method Get -Uri $vmssUrl -Headers @{Authorization = "Bearer $accessToken"}
            $vmssResponseMachines += $vmssResponse.value | Where-Object { $_.tags.$tagName -eq $tagValue }
            $vmssUrl = $vmssResponse.nextLink
        } while (![string]::IsNullOrEmpty($vmssUrl))

        $arcUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resources?`$filter=resourceType eq 'Microsoft.HybridCompute/machines'&api-version=2023-07-01"
        do {
            $arcResponse = Invoke-RestMethod -Method Get -Uri $arcUrl -Headers @{Authorization = "Bearer $accessToken"}
            $arcResponseMachines += $arcResponse.value | Where-Object { $_.tags.$tagName -eq $tagValue }
            $arcUrl = $arcResponse.nextLink
        } while (![string]::IsNullOrEmpty($arcUrl))
    }
    catch {
        Write-Host "Failed to Get resources! " -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Entered invalid mode. Exiting script."
    exit 1
}
Write-Host "Found the following resources:" -ForegroundColor Green

Write-Host "Virtual Machines:"
$vmCount = 0
foreach ($machine in $vmResponseMachines) {
    $vmCount++
    Write-Host "$vmCount : $($machine.name)"
}
Write-Host "-------------------"
Write-Host "Virtual Machine Scale Sets:"
$vmssCount = 0
foreach ($machine in $vmssResponseMachines) {
    $vmssCount++
    Write-Host "$vmssCount : $($machine.name)"
}
Write-Host "-------------------"
Write-Host "ARC Machines:"
$arcCount = 0
foreach ($machine in $arcResponseMachines) {
    $arcCount++
    Write-Host "$arcCount : $($machine.name)"
}
Write-Host "-----------------------------------------------------------------------"
Write-Host "`n"

$continue = Read-Host "Press any key to proceed or press 'N' to exit"
if ($continue.ToLower() -eq "n") { exit 0 }

$PricingTier = Read-Host "Enter the command for these resources - 'Free', 'Standard', 'Delete', or 'Read' (choosing 'Free' will remove the Defender protection; 'Standard' will enable the 'P1' subplan; 'Delete' will remove any explicitly set config; 'Read' will show current config)"
while ($PricingTier.ToLower() -notin @("free", "standard", "delete", "read")) {
    $PricingTier = Read-Host "Enter the command for these resources - 'Free', 'Standard', 'Delete', or 'Read'"
}

# Processing function for all resource types
function Set-DefenderPricing ($machines, $type) {
    $success = 0; $fail = 0
    foreach ($machine in $machines) {
        $pricingUrl = "https://management.azure.com$($machine.id)/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
        if ($PricingTier.ToLower() -eq "free") {
            $pricingBody = @{ properties = @{ pricingTier = $PricingTier } }
        } else {
            $pricingBody = @{ properties = @{ pricingTier = $PricingTier; subPlan = "P1" } }
        }
        Write-Host "Processing pricing for '$($machine.name)' ($type):"
        try {
            if ($PricingTier.ToLower() -eq "delete") {
                $pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
                Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
                $success++
            } elseif ($PricingTier.ToLower() -eq "read") {
                $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
                Write-Host "Current pricing configuration for $($machine.name):" -ForegroundColor Green
                Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
                $success++
            } else {
                $pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
                Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
                $success++
            }
        } catch {
            $fail++
            Write-Host "Failed to process $($machine.name)" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
        Write-Host ""
        Start-Sleep -Seconds 0.3
    }
    return @{ Success = $success; Fail = $fail }
}

Write-Host "-------------------"
$vmResult   = Set-DefenderPricing $vmResponseMachines   "VM"
$vmssResult = Set-DefenderPricing $vmssResponseMachines "VMSS"
$arcResult  = Set-DefenderPricing $arcResponseMachines  "ARC"

Write-Host "-----------------------------------------------------------------------"
Write-Host "Summary of Pricing API results:"
Write-Host "-------------------"
Write-Host "Found Virtual Machines count:" $vmCount
Write-Host "Successfully processed VMs:" $($vmResult.Success) -ForegroundColor Green
Write-Host "Failed processing VMs:" $($vmResult.Fail) -ForegroundColor $(if ($vmResult.Fail -gt 0) {'Red'} else {'Green'})
Write-Host ""
Write-Host "Found Virtual Machine Scale Sets count:" $vmssCount
Write-Host "Successfully processed VMSSs:" $($vmssResult.Success) -ForegroundColor Green
Write-Host "Failed processing VMSSs:" $($vmssResult.Fail) -ForegroundColor $(if ($vmssResult.Fail -gt 0) {'Red'} else {'Green'})
Write-Host ""
Write-Host "Found ARC machines count:" $arcCount
Write-Host "Successfully processed ARC Machines:" $($arcResult.Success) -ForegroundColor Green
Write-Host "Failed processing ARC Machines:" $($arcResult.Fail) -ForegroundColor $(if ($arcResult.Fail -gt 0) {'Red'} else {'Green'})
Write-Host "-------------------"
Write-Host "Overall"
$totalSuccess = $vmResult.Success + $vmssResult.Success + $arcResult.Success
$totalFail = $vmResult.Fail + $vmssResult.Fail + $arcResult.Fail
Write-Host "Successfully processed resources: $totalSuccess" -ForegroundColor Green
Write-Host "Failures processing resources: $totalFail" -ForegroundColor $(if ($totalFail -gt 0) {'Red'} else {'Green'})
Write-Host "`n"
