# Login to Azure Account
Connect-AzAccount

# Specify the Azure Subscription
$subscriptionId = "2ed2704e-c147-41f5-8056-9e58d2e72105" # Replace <YourSubscriptionId> with your actual subscription ID
Set-AzContext -SubscriptionId $subscriptionId

# Set variables for the script
$resourceGroupName = "rd-unerd-veeam-prod-zan" # Replace <YourResourceGroupName> with your actual resource group name
$nsgName = "veeamm365-unerd-prod-01-nsg" # Replace <YourNSGName> with your actual NSG name
$storageAccountId = "thatlazyadminstorage" # Replace <YourStorageAccountId> with your actual storage account resource ID
$location = "southafricanorth" # Replace <AzureRegion> with the Azure region of your NSG (e.g., "eastus")

# Generate a relevant name for the DCR rule that includes 'DCR' and the NSG name
$flowLogName = "DCR-" + $nsgName + "-FlowLog"

$flowLogConfig = @{
    TargetResourceId = (Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName).Id
    StorageId = $storageAccountId
    Enabled = $true
    RetentionPolicy = @{
        Days    = 0 # Retain indefinitely. Set to a positive number for specific retention days.
        Enabled = $false # Change to $true if specifying retention days.
    }
    Format = @{
        Type = "JSON"
        Version = 1
    }
}

# Create or update the flow log with the dynamically generated name
Set-AzNetworkWatcherFlowLogConfiguration -Name $flowLogName -ResourceGroupName $resourceGroupName -Location $location @flowLogConfig

Write-Host "NSG Flow Logs have been enabled for NSG: $nsgName in the $location region, storing logs in the specified storage account under the DCR rule named $flowLogName."