# Script Name: ExportAllTenantSubscriptionsToCSV.ps1
# Created by: Shaun Hardneck
# Description: This script exports all subscriptions visible to the logged-in user to a CSV file, including those accessed via Azure Lighthouse.
# Synopsis: This script connects to Azure, loops through all tenants accessible by the logged-in user (including those accessed via Azure Lighthouse), retrieves subscription details for each tenant, and exports these details to a CSV file.

# Set the output CSV file path
$outputCSV = ".\AllSubscriptions.csv"

# Connect to Azure account
Connect-AzAccount

# Get all tenants
$tenants = Get-AzTenant

# Initialize an array to store subscription details
$subscriptionDetails = @()

# Loop through each tenant and get subscriptions
foreach ($tenant in $tenants) {
    Write-Host "Processing tenant: $($tenant.DisplayName) ($($tenant.Id))" -ForegroundColor Cyan
    try {
        # Set the current context to the tenant
        Set-AzContext -TenantId $tenant.Id

        # Get subscriptions for the current tenant
        $subscriptions = Get-AzSubscription

        # Add subscription details to the array
        foreach ($subscription in $subscriptions) {
            Write-Host "  Found subscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Green
            $subscriptionDetails += [PSCustomObject]@{
                TenantId         = $tenant.Id
                TenantName       = $tenant.DisplayName
                SubscriptionId   = $subscription.Id
                SubscriptionName = $subscription.Name
            }
        }
    } catch {
        Write-Warning "Unable to process tenant: $($tenant.DisplayName) ($($tenant.Id))"
        Write-Warning $_.Exception.Message
    }
}

# Check if any subscription details were collected
if ($subscriptionDetails.Count -gt 0) {
    # Export subscription details to CSV
    $subscriptionDetails | Export-Csv -Path $outputCSV -NoTypeInformation
    Write-Host "Subscription details have been exported to $outputCSV" -ForegroundColor Yellow
} else {
    Write-Host "No subscription details were collected." -ForegroundColor Red
}