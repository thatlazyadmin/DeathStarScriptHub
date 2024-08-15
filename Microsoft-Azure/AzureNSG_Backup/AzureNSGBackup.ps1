<#
.SYNOPSIS
    This script backs up all NSG (Network Security Group) rules from Azure and exports them to JSON and CSV files.

.DESCRIPTION
    The script connects to the Azure environment, retrieves all NSG rules for each subscription, and exports the rules to JSON and CSV files. 
    The exported files are organized into a folder structure based on the subscription and NSG names. Each subscription will have its own 
    set of files within its respective folder.

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Date: August 15, 2024

#>

# Define error log file
$ErrorLogPath = "AzureNSG_Backup_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ErrorActionPreference = "Stop"

# Function to handle errors
function Handle-Error {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )
    $ErrorMessage | Out-File -FilePath $ErrorLogPath -Append
}

# Display banner
$banner = @"
=======================================================================
Backing Up Azure NSG Rules - Created by Shaun Hardneck
=======================================================================
"@
Write-Host $banner -ForegroundColor Cyan

# Check if necessary modules are already imported, if not, import them
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    try {
        Import-Module Az.Accounts -ErrorAction Stop
    } catch {
        Handle-Error "Failed to import Az.Accounts module: $_"
        return
    }
}
if (-not (Get-Module -ListAvailable -Name Az.Network)) {
    try {
        Import-Module Az.Network -ErrorAction Stop
    } catch {
        Handle-Error "Failed to import Az.Network module: $_"
        return
    }
}

# Connect to Azure using device authentication
try {
    Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop
} catch {
    Handle-Error "Failed to connect to Azure: $_"
    return
}

# Get all subscriptions
try {
    $subscriptions = Get-AzSubscription
} catch {
    Handle-Error "Failed to retrieve subscriptions: $_"
    return
}

# Create a root folder for the backup with date and timestamp
$rootFolderPath = "AzureNSG_Backup_$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
try {
    New-Item -ItemType Directory -Path $rootFolderPath -Force | Out-Null
} catch {
    Handle-Error "Failed to create backup directory: $_"
    return
}

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    try {
        Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop
        
        Write-Host "Processing Subscription: $($subscription.Name)" -ForegroundColor Yellow
        
        # Create a folder for the subscription
        $subscriptionFolderPath = Join-Path -Path $rootFolderPath -ChildPath $subscription.Name
        New-Item -ItemType Directory -Path $subscriptionFolderPath -Force | Out-Null
        
        # Get all NSGs in the current subscription
        $nsgs = Get-AzNetworkSecurityGroup
        
        foreach ($nsg in $nsgs) {
            $nsgName = $nsg.Name
            $resourceGroupName = $nsg.ResourceGroupName

            # Create a folder for the NSG
            $nsgFolderPath = Join-Path -Path $subscriptionFolderPath -ChildPath $nsgName
            New-Item -ItemType Directory -Path $nsgFolderPath -Force | Out-Null

            # Get NSG rules
            $nsgRules = $nsg.SecurityRules | ForEach-Object {
                [PSCustomObject]@{
                    Name                      = $_.Name
                    Description               = $_.Description
                    Direction                 = $_.Direction
                    Priority                  = $_.Priority
                    Access                    = $_.Access
                    Protocol                  = $_.Protocol
                    SourcePortRange           = ($_.SourcePortRange -join ",")
                    DestinationPortRange      = ($_.DestinationPortRange -join ",")
                    SourceAddressPrefix       = ($_.SourceAddressPrefix -join ",")
                    DestinationAddressPrefix  = ($_.DestinationAddressPrefix -join ",")
                }
            }
            
            # Export to JSON
            $jsonFilePath = Join-Path -Path $nsgFolderPath -ChildPath "$($nsgName)_NSGRules.json"
            $nsgRules | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFilePath -Force

            # Export to CSV
            $csvFilePath = Join-Path -Path $nsgFolderPath -ChildPath "$($nsgName)_NSGRules.csv"
            $nsgRules | Export-Csv -Path $csvFilePath -NoTypeInformation -Force
        }
    } catch {
        Handle-Error "Failed to process subscription $($subscription.Name): $_"
    }
}

Write-Host "Backup completed successfully. All NSG rules have been exported to JSON and CSV files in the folder: $rootFolderPath" -ForegroundColor Cyan