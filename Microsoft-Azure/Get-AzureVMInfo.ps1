# Get-AzureVMInfo.ps1
#www.thatlazyadmin.com
#CreatedBy:Shaun Hardneck

# Authenticate to Azure
Connect-AzAccount

# Get all Azure Subscriptions
$subscriptions = Get-AzSubscription

# Initialize an empty array to store VM information
$vmInfo = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -Subscription $subscription

    # Get all Azure Virtual Machines in the current subscription
    $vms = Get-AzVM

    # Loop through each VM in the current subscription
    foreach ($vm in $vms) {
        $vmName = $vm.Name
        $resourceGroupName = $vm.ResourceGroupName
        $osType = $vm.StorageProfile.OsDisk.OsType
        $osVersion = $vm.StorageProfile.OsDisk.OsVersion

        # Get the IP addresses of the VM
        $networkInterfaces = Get-AzNetworkInterface | Where-Object { $_.VirtualMachine -ne $null -and $_.VirtualMachine.Id -eq $vm.Id }
        $ipAddresses = $networkInterfaces | ForEach-Object { $_.IpConfigurations[0].PrivateIpAddress }

        # Create an object to store VM information
        $vmObject = [PSCustomObject]@{
            'SubscriptionName' = $subscription.Name
            'VMName' = $vmName
            'ResourceGroupName' = $resourceGroupName
            'OSType' = $osType
            'OSVersion' = $osVersion
            'IPAddresses' = $ipAddresses -join ', '
        }

        # Add the VM information object to the array
        $vmInfo += $vmObject
    }
}

# Export the VM information to a text file
$vmInfo | Format-Table -AutoSize | Out-File -FilePath 'C:\Softlib\Github\Thatlazyadmin\Microsoft-Azure\AzureVMInfo.txt'

Write-Host "VM information exported to AzureVMInfo.txt file."