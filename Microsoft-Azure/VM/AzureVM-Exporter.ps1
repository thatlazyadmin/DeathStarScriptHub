# Azure CLI script to export all Azure VMs to CSV
# Created by: Shaun Hardneck | www.thatlazyadmin.com

# Define output files
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = ".\Azure_VMs_$timestamp.csv"
$errorLog = ".\Azure_VM_Errors_$timestamp.txt"

# Ensure Azure CLI is logged in
Write-Host "`nChecking Azure CLI authentication..." -ForegroundColor Cyan
$azLogin = az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure CLI is not logged in. Please log in using 'az login'." -ForegroundColor Red
    exit
}

# Retrieve all subscriptions
Write-Host "`nRetrieving Azure subscriptions..." -ForegroundColor Yellow
$subscriptions = az account list --query "[].id" -o tsv

if (-not $subscriptions) {
    Write-Host "No subscriptions found!" -ForegroundColor Red
    exit
}

# Initialize VM list
$vmList = @()

# Loop through each subscription
foreach ($sub in $subscriptions) {
    Write-Host "`nSwitching to subscription: $sub" -ForegroundColor Green
    az account set --subscription $sub

    # Get all VMs in the current subscription
    $vms = az vm list --query "[].{Name:name, OS:storageProfile.imageReference.offer}" -o json | ConvertFrom-Json

    if ($vms) {
        foreach ($vm in $vms) {
            try {
                # Create an object for the CSV export
                $vmObject = [PSCustomObject]@{
                    SubscriptionID = $sub
                    ServerName     = $vm.Name
                    OSVersion      = $vm.OS
                }
                $vmList += $vmObject
            }
            catch {
                Write-Output "Error processing VM: $($_.Exception.Message)" | Out-File -Append -FilePath $errorLog
            }
        }
    } else {
        Write-Host "No VMs found in subscription: $sub" -ForegroundColor Gray
    }
}

# Export to CSV
if ($vmList.Count -gt 0) {
    $vmList | Export-Csv -Path $csvFile -NoTypeInformation
    Write-Host "`nExport complete! CSV file saved as: $csvFile" -ForegroundColor Green
} else {
    Write-Host "`nNo VMs found across all subscriptions." -ForegroundColor Red
}
