# AzurePublicIPComplianceAudit.ps1

# Function to check if the necessary modules are installed and import them
function Import-RequiredModule {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Installing module $ModuleName..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Force -Scope CurrentUser
    }
    Import-Module $ModuleName -Force
}

# Suppress warning messages related to Azure subscriptions
$PSDefaultParameterValues = @{"*:WarningAction" = "SilentlyContinue"}

# Import necessary modules
# Import-RequiredModule -ModuleName Az
# Import-RequiredModule -ModuleName Az.Network
# Import-RequiredModule -ModuleName ImportExcel

# Variables
$OutputFile = "AzurePublicIPComplianceReport.xlsx"
$Results = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Function to check a control and return the result
function Check-Control {
    param (
        [string]$ControlId,
        [string]$Description,
        [scriptblock]$CheckScript,
        [string]$SubscriptionId
    )
    $result = @{
        ControlId = $ControlId
        Description = $Description
        Status = "Not Implemented"
        Subscription = $SubscriptionId
    }
    try {
        $status = & $CheckScript
        $result.Status = if ($status) { "Implemented" } else { "Not Implemented" }
    }
    catch {
        $result.Status = "Feature not enabled or configured"
    }
    return $result
}

# Function to check if VM's with public IPs are protected by NSG
function Check-B0101 {
    param (
        [string]$SubscriptionId
    )
    $publicIPs = Get-AzPublicIpAddress -SubscriptionId $SubscriptionId
    foreach ($publicIP in $publicIPs) {
        if ($publicIP.IpConfiguration -and ($publicIP.IpConfiguration | Get-AzNetworkInterfaceIpConfig).NetworkSecurityGroup) {
            return $true
        }
    }
    return $false
}

# Function to check if VMs with public IPs are moved behind Azure Firewall Premium
function Check-B0102 {
    param (
        [string]$SubscriptionId
    )
    # Check implementation logic for firewall protection
    $firewallRules = Get-AzFirewallRule -SubscriptionId $SubscriptionId
    return ($firewallRules | Where-Object { $_.RuleCollection -match 'AzureFirewallPremium' }).Count -gt 0
}

# Function to check if VM's that don't need public IPs do not have public IPs
function Check-B0103 {
    param (
        [string]$SubscriptionId
    )
    $vms = Get-AzVM -SubscriptionId $SubscriptionId
    foreach ($vm in $vms) {
        if ($vm.NetworkProfile.NetworkInterfaces | Get-AzNetworkInterfaceIpConfig | Where-Object { $_.PublicIpAddress }) {
            return $false
        }
    }
    return $true
}

# Iterate through all subscriptions and check controls
foreach ($subscription in $subscriptions) {
    Write-Host "Checking subscription: $($subscription.Name)" -ForegroundColor Cyan
    Select-AzSubscription -SubscriptionId $subscription.Id

    $Results += Check-Control -ControlId "B01.01" -Description "VM's with public IPs should be protected by NSG" -CheckScript { Check-B0101 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B01.02" -Description "VMs with public IPs are moved behind Azure Firewall Premium" -CheckScript { Check-B0102 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B01.03" -Description "VM's that don't need public IPs do not have public IPs" -CheckScript { Check-B0103 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
}

# Display results on screen
foreach ($result in $Results) {
    if ($result.Status -eq "Implemented") {
        Write-Host "$($result.ControlId) - $($result.Description): $($result.Status)" -ForegroundColor Green
    }
    else {
        Write-Host "$($result.ControlId) - $($result.Description): $($result.Status)" -ForegroundColor Red
    }
}

# Prepare data for Excel export
$FlattenedResults = $Results | ForEach-Object {
    [PSCustomObject]@{
        ControlId    = $_.ControlId
        Description  = $_.Description
        Status       = $_.Status
        Subscription = $_.Subscription
    }
}

# Export results to Excel
$FlattenedResults | Export-Excel -Path $OutputFile -AutoSize -WorkSheetName "ComplianceReport"
Write-Host "Report generated: $OutputFile" -ForegroundColor Green