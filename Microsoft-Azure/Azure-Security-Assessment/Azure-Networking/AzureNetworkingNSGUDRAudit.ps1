# AzureNetworkingNSGUDRAudit.ps1

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
$OutputFile = "AzureNetworkingNSGUDRAudit.xlsx"
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

# Function to check if NSG RBAC is used to restrict access to the network security team
function Check-B0201 {
    param (
        [string]$SubscriptionId
    )
    $nsgs = Get-AzNetworkSecurityGroup -SubscriptionId $SubscriptionId
    foreach ($nsg in $nsgs) {
        if ($nsg.SecurityRules -and ($nsg.SecurityRules | Where-Object { $_.Access -eq "Allow" })) {
            return $true
        }
    }
    return $false
}

# Function to check if NSG Inbound security rules do not contain a * (wildcard) in Source field
function Check-B0202 {
    param (
        [string]$SubscriptionId
    )
    $nsgs = Get-AzNetworkSecurityGroup -SubscriptionId $SubscriptionId
    foreach ($nsg in $nsgs) {
        if ($nsg.SecurityRules | Where-Object { $_.Direction -eq "Inbound" -and $_.SourceAddressPrefix -eq "*" }) {
            return $false
        }
    }
    return $true
}

# Function to check if NSG outbound security rules are used to control traffic to specific IP addresses
function Check-B0203 {
    param (
        [string]$SubscriptionId
    )
    $nsgs = Get-AzNetworkSecurityGroup -SubscriptionId $SubscriptionId
    foreach ($nsg in $nsgs) {
        if ($nsg.SecurityRules | Where-Object { $_.Direction -eq "Outbound" -and $_.DestinationAddressPrefix -ne "*" }) {
            return $true
        }
    }
    return $false
}

# Function to check if NSG do not have Source as a * (wildcard) in place
function Check-B0204 {
    param (
        [string]$SubscriptionId
    )
    $nsgs = Get-AzNetworkSecurityGroup -SubscriptionId $SubscriptionId
    foreach ($nsg in $nsgs) {
        if ($nsg.SecurityRules | Where-Object { $_.SourceAddressPrefix -eq "*" }) {
            return $false
        }
    }
    return $true
}

# Function to check if NSG Diagnostics send traffic to Sentinel LAW
function Check-B0205 {
    param (
        [string]$SubscriptionId
    )
    # Check implementation logic for NSG diagnostics
    $diagnostics = Get-AzNetworkWatcherNetworkSecurityGroupFlowLog -SubscriptionId $SubscriptionId
    return ($diagnostics | Where-Object { $_.StorageAccountId -match 'LAW' }).Count -gt 0
}

# Function to check if UDR RBAC is used to restrict access to the network security team
function Check-B0301 {
    param (
        [string]$SubscriptionId
    )
    $udrs = Get-AzRouteTable -SubscriptionId $SubscriptionId
    foreach ($udr in $udrs) {
        if ($udr.Routes -and ($udr.Routes | Where-Object { $_.NextHopType -eq "VirtualAppliance" })) {
            return $true
        }
    }
    return $false
}

# Function to check if UDR's are used to send all traffic to the Azure Firewall Premium
function Check-B0302 {
    param (
        [string]$SubscriptionId
    )
    $udrs = Get-AzRouteTable -SubscriptionId $SubscriptionId
    foreach ($udr in $udrs) {
        if ($udr.Routes | Where-Object { $_.NextHopType -eq "VirtualAppliance" -and $_.NextHopIpAddress -match 'AzureFirewallPremium' }) {
            return $true
        }
    }
    return $false
}

# Function to check if UDR's that do not send all traffic to AzureFirewallPremium are known and documented
function Check-B0303 {
    param (
        [string]$SubscriptionId
    )
    $udrs = Get-AzRouteTable -SubscriptionId $SubscriptionId
    foreach ($udr in $udrs) {
        if ($udr.Routes | Where-Object { $_.NextHopType -ne "VirtualAppliance" }) {
            return $true
        }
    }
    return $false
}

# Iterate through all subscriptions and check controls
foreach ($subscription in $subscriptions) {
    Write-Host "Checking subscription: $($subscription.Name)" -ForegroundColor Cyan
    Select-AzSubscription -SubscriptionId $subscription.Id

    $Results += Check-Control -ControlId "B02.01" -Description "NSG RBAC is used to restrict access to network security team" -CheckScript { Check-B0201 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B02.02" -Description "NSG Inbound security rules do not contain a * (wildcard) in Source field" -CheckScript { Check-B0202 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B02.03" -Description "NSG outbound security rules are used to control traffic to specific IP addresses" -CheckScript { Check-B0203 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B02.04" -Description "NSG do not have Source as a * (wildcard) in place" -CheckScript { Check-B0204 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B02.05" -Description "NSG Diagnostics send traffic to Sentinel LAW" -CheckScript { Check-B0205 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B03.01" -Description "UDR RBAC is used to restrict access to the network security team" -CheckScript { Check-B0301 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B03.02" -Description "UDR's are used to send all traffic to the Azure Firewall Premium" -CheckScript { Check-B0302 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
    $Results += Check-Control -ControlId "B03.03" -Description "UDR's that do not send all traffic to AzureFirewallPremium are known and documented" -CheckScript { Check-B0303 -SubscriptionId $subscription.Id } -SubscriptionId $subscription.Id
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