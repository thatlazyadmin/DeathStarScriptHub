# Login to Azure
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Your Microsoft Partner ID
$partnerId = "4642842"

foreach ($subscription in $subscriptions) {
    # Set the context to the current subscription
    Set-AzContext -SubscriptionId $subscription.Id

    try {
        # Add the partner ID to the current subscription
        New-AzManagementPartner -PartnerId $partnerId

        Write-Host "Added Partner ID to subscription: $($subscription.Id)"
    } catch {
        Write-Host "Error adding Partner ID to subscription: $($subscription.Id). Error: $_"
    }
}

Write-Host "All subscriptions have been processed."
