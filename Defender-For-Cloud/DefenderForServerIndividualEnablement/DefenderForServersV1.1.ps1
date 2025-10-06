# ================================[ SUPPRESS WARNINGS ]=================================
$WarningPreference = "SilentlyContinue"  # Suppresses all PowerShell warnings

# ================================[ BANNER ]=================================
Clear-Host  # Clears PowerShell screen on script execution
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "                 Defender for Servers Management Script             " -ForegroundColor Yellow
Write-Host "               Created by Shaun Hardneck - ThatLazyAdmin             " -ForegroundColor Green
Write-Host "              www.thatlazyadmin.com | Microsoft Defender             " -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "`n"

# ================================[ LOGIN & ACCESS TOKEN ]=================================
Write-Host "Checking Azure authentication..." -ForegroundColor Cyan
try {
    $accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
    if (-not $accessToken) {
        Write-Host "ERROR: Failed to retrieve access token. Please check your Azure login session." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Unable to obtain Azure access token." -ForegroundColor Red
    Write-Host "DETAILS: $_.Exception.Message"
    exit 1
}
Write-Host "Successfully authenticated with Azure." -ForegroundColor Green
Write-Host "`n"

# ================================[ USER INPUTS ]=================================
Write-Host "Enter your Azure details below:" -ForegroundColor Cyan
$subscriptionId = Read-Host "Enter your Azure Subscription ID"
$resourceGroup = Read-Host "Enter the Resource Group Name"
$vmName = Read-Host "Enter the Virtual Machine Name"
Write-Host "`n"

# ================================[ CHECK IF VM EXISTS (Azure VM or Arc)]=================================
Write-Host "Checking if the VM exists in Azure..." -ForegroundColor Cyan
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -ErrorAction SilentlyContinue

# If VM is not found under Compute, check for Arc-enabled machines
if (-not $vm) {
    Write-Host "VM not found under Azure Compute, checking for Arc-enabled machines..." -ForegroundColor Yellow

    # Query Arc Machines at Subscription Level
    $arcUrl = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.HybridCompute/machines?api-version=2022-12-27"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }

    try {
        $arcMachines = (Invoke-RestMethod -Uri $arcUrl -Headers $headers -Method Get).value
        $arcMachine = $arcMachines | Where-Object { $_.name -eq $vmName }
        
        if ($arcMachine) {
            Write-Host "STATUS: Found Arc-enabled VM: " -NoNewline
            Write-Host "$vmName" -ForegroundColor Green
            Write-Host " | LOCATION: " -NoNewline
            Write-Host "$($arcMachine.location)" -ForegroundColor Cyan
            $isArcMachine = $true
        } else {
            Write-Host "ERROR: VM '$vmName' not found in Resource Group '$resourceGroup' or as an Arc-enabled machine." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "ERROR: Failed to retrieve Arc-enabled machines." -ForegroundColor Red
        Write-Host "DETAILS: $_.Exception.Message"
        exit 1
    }
} else {
    Write-Host "STATUS: Found Azure VM: " -NoNewline
    Write-Host "$vmName" -ForegroundColor Green
    Write-Host " | LOCATION: " -NoNewline
    Write-Host "$($vm.Location)" -ForegroundColor Cyan
    $isArcMachine = $false
}

Write-Host "`n"

# ================================[ DEFINE API URL & HEADERS ]=================================
if ($isArcMachine) {
    # API for Arc Machines
    $pricingUrl = "https://management.azure.com$($arcMachine.id)/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
} else {
    # API for Azure Virtual Machines
    $pricingUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
}

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

# Debug Mode (Set to $true to see debug logs)
$debugMode = $false 

if ($debugMode) {
    Write-Host "DEBUG: API URL - $pricingUrl" -ForegroundColor Yellow
}

# ================================[ USER ACTION SELECTION ]=================================
Write-Host "Select an action for Defender for Servers on this VM:" -ForegroundColor Cyan
$PricingTier = Read-Host "Enter 'Enable-P1' to enable, 'Disable' to remove, or 'Exclude' to exclude"

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
        Invoke-RestMethod -Method Delete -Uri $pricingUrl -Headers $headers -ContentType "application/json"
        Write-Host "SUCCESS: VM '$vmName' has been excluded from Defender for Servers." -ForegroundColor Green
        exit 0
    } catch {
        Write-Host "ERROR: Failed to exclude VM '$vmName'" -ForegroundColor Red
        Write-Host "DETAILS: $_.Exception.Message"
        exit 1
    }
}

# ================================[ EXECUTE API CALL ]=================================
Write-Host "`nProcessing Defender for Servers action for VM '$vmName'..." -ForegroundColor Cyan

if ($debugMode) {
    Write-Host "DEBUG: Request Body - $(ConvertTo-Json $body -Depth 10)" -ForegroundColor Yellow
}

try {
    $response = Invoke-RestMethod -Method Put -Uri $pricingUrl -Body $body -Headers $headers -ContentType "application/json"
    Write-Host "SUCCESS: Defender for Servers configuration updated for VM '$vmName'" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to update Defender for Servers" -ForegroundColor Red
    Write-Host "DETAILS: $_.Exception.Message"
}

# ================================[ SUMMARY ]=================================
Write-Host "`n===================================================================" -ForegroundColor Cyan
Write-Host "                             ACTION SUMMARY                            " -ForegroundColor Yellow
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "SUBSCRIPTION ID:  $subscriptionId" -ForegroundColor Cyan
Write-Host "RESOURCE GROUP:   $resourceGroup" -ForegroundColor Green
Write-Host "VM NAME:         $vmName" -ForegroundColor Green
Write-Host "ACTION TAKEN:    $PricingTier" -ForegroundColor Yellow
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "`n"
