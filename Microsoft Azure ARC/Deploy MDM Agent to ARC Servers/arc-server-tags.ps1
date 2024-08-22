# Variables
$subscriptionId = "2ed2704e-c147-41f5-8056-9e58d2e72105"
$resourceGroupName = "rsg-arc-pilot"
$arcServerName = "WIN-0OJOR5QNO7U"
$tags = @{ "Environment"="Production"; "Role"="WebServer" }

# Login to Azure
Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionId $subscriptionId

# Apply tags to Azure Arc server
$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines/$arcServerName"
Set-AzResource -ResourceId $resourceId -Tag $tags