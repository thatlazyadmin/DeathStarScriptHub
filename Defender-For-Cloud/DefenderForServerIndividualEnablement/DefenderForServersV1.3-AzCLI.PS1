# ================================[ BANNER ]=================================
Clear-Host
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "                 Defender for Servers Management Script             " -ForegroundColor Yellow
Write-Host "               Created by Shaun Hardneck - ThatLazyAdmin   FT Marcus Burnap           " -ForegroundColor Green
Write-Host "              www.thatlazyadmin.com - www.MBCloudTeck.com | Microsoft Defender           " -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "`n"

# ================================[ LOGIN & ACCESS TOKEN ]=================================
Write-Host "Checking Azure authentication..." -ForegroundColor Cyan

# (C) If not logged in, prompt for device code login
$azAccount = az account show 2>$null
if (-not $azAccount) {
    Write-Host "You are not logged in to Azure CLI. Logging in now (device code flow)..." -ForegroundColor Yellow
    az login --use-device-code
} else {
    Write-Host "Already authenticated with Azure CLI." -ForegroundColor Green
}

# (B) Get Azure CLI access token for management.azure.com
$accessToken = az account get-access-token --resource=https://management.azure.com/ --query accessToken -o tsv

# (A) Check that the token is valid
if (-not $accessToken) {
    Write-Host "ERROR: Failed to retrieve Azure CLI access token. Please check your login." -ForegroundColor Red
    exit 1
}
Write-Host "Successfully retrieved Azure CLI access token." -ForegroundColor Green
Write-Host "`n"

# ================================[ USER INPUTS ]=================================
Write-Host "Enter your Azure details below:" -ForegroundColor Cyan
$subscriptionId = Read-Host "Enter your Azure Subscription ID"
$resourceGroup = Read-Host "Enter the Resource Group Name"
$vmName = Read-Host "Enter the Virtual Machine Name"
Write-Host "`n"

# ================================[ CHECK IF VM EXISTS (Azure VM or Arc)]=================================
Write-Host "Checking if the VM exists in Azure..." -ForegroundColor Cyan
$vm = az vm show --resource-group $resourceGroup --name $vmName --subscription $subscriptionId --output json 2>$null | ConvertFrom-Json

if (-not $vm) {
    Write-Host "VM not found under Azure Compute, checking for Arc-enabled machines..." -ForegroundColor Yellow

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
    Write-Host "$($vm.location)" -ForegroundColor Cyan
    $isArcMachine = $false
}

Write-Host "`n"

# ================================[ DEFINE API URL & HEADERS ]=================================
if ($isArcMachine) {
    # API for Arc Machines
    $pricingUrl = "https://management.azure.com$($arcMachine.id)/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
    $location = $arcMachine.location
} else {
    # API for Azure Virtual Machines
    $pricingUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
    $location = $vm.location
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
        location   = $location
        properties = @{
            pricingTier = "Standard"
            subPlan     = "P1"
        }
    } | ConvertTo-Json -Depth 10
} elseif ($PricingTier.ToLower() -eq "disable") {
    $body = @{
        location   = $location
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
