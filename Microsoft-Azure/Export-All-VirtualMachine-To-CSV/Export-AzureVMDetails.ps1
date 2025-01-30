<#
.SYNOPSIS
    Export Azure Virtual Machine details across all subscriptions.

.DESCRIPTION
    This script loops through all Azure subscriptions to fetch details for all virtual machines, including:
    - Virtual Machine Name
    - Operating System Type (Windows/Linux)
    - Current Private IP Address
    The details are exported to a CSV file.

.AUTHOR
    Shaun Hardneck 
    www.thatlazyadmin.com
    Email: Shaun@thatlazyadmin.com
#>

# Display a banner
Write-Host "############################################################" -ForegroundColor Cyan
Write-Host "# Azure Virtual Machines Details Exporter                  #" -ForegroundColor Cyan
Write-Host "# Created by: Shaun Hardneck                              #" -ForegroundColor Cyan
Write-Host "# Email: Shaun@thatlazyadmin.com                          #" -ForegroundColor Cyan
Write-Host "############################################################" -ForegroundColor Cyan

# Set the output file
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outputFile = "VM_Details_$timestamp.csv"

# Add CSV headers
$csvData = @()
Write-Host "Starting to loop through all subscriptions..." -ForegroundColor Green

# Loop through all subscriptions
$subscriptions = az account list --query "[].id" -o tsv
foreach ($subscription in $subscriptions) {
    Write-Host "Switching to subscription: $subscription" -ForegroundColor Yellow
    az account set --subscription $subscription

    # Get VM details
    $vms = az vm list -d --query "[].{Name:name, OSType:storageProfile.osDisk.osType, IPAddress:privateIps}" -o json | ConvertFrom-Json

    if (-not $vms) {
        Write-Host "No virtual machines found in subscription: $subscription" -ForegroundColor Red
        continue
    }

    foreach ($vm in $vms) {
        $subscriptionName = az account show --query "name" -o tsv
        $csvData += [PSCustomObject]@{
            SubscriptionName = $subscriptionName
            VMName           = $vm.Name
            OSType           = $vm.OSType
            IPAddress        = $vm.IPAddress
        }
    }
}

# Export to CSV
if ($csvData.Count -gt 0) {
    $csvData | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    Write-Host "Export completed. Details saved to $outputFile" -ForegroundColor Green
} else {
    Write-Host "No data to export. Ensure there are virtual machines in your subscriptions." -ForegroundColor Red
}
