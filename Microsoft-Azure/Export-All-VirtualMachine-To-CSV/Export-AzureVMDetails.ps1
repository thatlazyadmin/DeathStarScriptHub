<#
.SYNOPSIS
    Export Azure Virtual Machine details across all subscriptions.

.DESCRIPTION
    This script loops through all Azure subscriptions to fetch details for all virtual machines, including:
    - Subscription & Resource Group
    - VM Name
    - Location
    - VM Size
    - OS Type (Windows/Linux)
    - Power State
    - Private & Public IPs
    - OS Disk Type
    - Managed Disk Details
    - Backup Status
    - Tags
    The details are exported to a CSV file.

.AUTHOR
    Shaun Hardneck 
    www.thatlazyadmin.com
    Email: Shaun@thatlazyadmin.com
#>

# Clear PowerShell Window
Clear-Host

# Suppress warnings and errors from being displayed in the console
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

# Ensure Azure PowerShell Module is installed
if (-not (Get-Module -ListAvailable -Name Az.RecoveryServices)) {
    Write-Host "Az.RecoveryServices module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Az.RecoveryServices -Force -AllowClobber -Scope CurrentUser
}

# Import necessary modules
Import-Module Az.RecoveryServices

# Display a banner
Write-Host "############################################################" -ForegroundColor Cyan
Write-Host "# Azure Virtual Machines Details Exporter                  #" -ForegroundColor Cyan
Write-Host "# Created by: Shaun Hardneck                               #" -ForegroundColor Cyan
Write-Host "# Email: Shaun@thatlazyadmin.com                           #" -ForegroundColor Cyan
Write-Host "############################################################" -ForegroundColor Cyan

# Connect to Azure if not already authenticated
Write-Host "`nConnecting to Azure..." -ForegroundColor Yellow
try {
    Connect-AzAccount -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
} catch {
    Write-Host "Error: Unable to connect to Azure. Ensure you have the required permissions." -ForegroundColor Red
    exit
}

# Set the output file
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outputFile = ".\Azure_VM_Details_$timestamp.csv"

# Initialize array to store VM data
$vmList = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription -WarningAction SilentlyContinue -ErrorAction Stop

foreach ($sub in $subscriptions) {
    Write-Host "`nProcessing Subscription: $($sub.Name) ($($sub.Id))" -ForegroundColor Green
    Set-AzContext -SubscriptionId $sub.Id -WarningAction SilentlyContinue | Out-Null

    # Get all Virtual Machines in the subscription
    $vms = Get-AzVM -Status -WarningAction SilentlyContinue

    # Get Recovery Services Vault (if any exist)
    $vault = Get-AzRecoveryServicesVault -WarningAction SilentlyContinue | Select-Object -First 1

    foreach ($vm in $vms) {
        # Extract OS Type
        $osType = $vm.StorageProfile.OsDisk.OsType

        # Get VM Power State
        $powerState = ($vm.Statuses | Where-Object { $_.Code -match "PowerState" }).DisplayStatus

        # Get Private IP Address
        $networkInterface = Get-AzNetworkInterface -WarningAction SilentlyContinue | Where-Object { $_.Id -match $vm.NetworkProfile.NetworkInterfaces[0].Id }
        $privateIp = $networkInterface.IpConfigurations.PrivateIpAddress

        # Get Public IP Address (if exists)
        $publicIp = ($networkInterface.IpConfigurations.PublicIpAddress.Id -split "/")[-1]
        if ($publicIp) {
            $publicIp = (Get-AzPublicIpAddress -WarningAction SilentlyContinue | Where-Object { $_.Id -match $networkInterface.IpConfigurations.PublicIpAddress.Id }).IpAddress
        } else {
            $publicIp = "N/A"
        }

        # Get OS Disk Type (SSD, HDD, etc.)
        $osDiskType = $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType

        # Get Managed Disk Details
        $managedDisks = ($vm.StorageProfile.DataDisks | ForEach-Object { $_.Name + " (" + $_.ManagedDisk.StorageAccountType + ")" }) -join "; "

        # Get Backup Status (Check if VM is protected in Recovery Services Vault)
        if ($vault) {
            $backupItem = Get-AzRecoveryServicesBackupProtectedItem -VaultId $vault.ID -WorkloadType "AzureVM" -ContainerType "AzureVM" -WarningAction SilentlyContinue | Where-Object { $_.Name -like "*$($vm.Name)*" }
            if ($backupItem) {
                $backupStatus = "Protected"
            } else {
                $backupStatus = "Not Protected"
            }
        } else {
            $backupStatus = "No Vault Found"
        }

        # Get Tags (Convert hash table to a readable format)
        $tags = if ($vm.Tags) { ($vm.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; " } else { "No Tags" }

        # Store VM details
        $vmList += [PSCustomObject]@{
            Subscription      = $sub.Name
            SubscriptionID    = $sub.Id
            ResourceGroup     = $vm.ResourceGroupName
            Name              = $vm.Name
            Location          = $vm.Location
            VMSize            = $vm.HardwareProfile.VmSize
            OS                = $osType
            PowerState        = $powerState
            PrivateIP         = $privateIp
            PublicIP          = $publicIp
            OSDiskType        = $osDiskType
            ManagedDisks      = $managedDisks
            BackupStatus      = $backupStatus
            Tags              = $tags
        }
    }
}

# Export to CSV
$vmList | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "`nExport completed! File saved as: $outputFile" -ForegroundColor Green
