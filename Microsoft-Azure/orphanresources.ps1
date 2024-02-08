# Login to Azure Account
Connect-AzAccount

# Get all subscriptions in the tenant
$subscriptions = Get-AzSubscription

# Prepare the results array
$results = @()

foreach ($sub in $subscriptions) {
    # Select the subscription
    Select-AzSubscription -SubscriptionId $sub.Id

    # Identify orphaned Unattached Disks
    $unattachedDisks = Get-AzDisk | Where-Object { -not $_.ManagedBy }
    foreach ($disk in $unattachedDisks) {
        $lastUsed = (Get-AzLog -ResourceId $disk.Id -MaxRecord 1 -WarningAction SilentlyContinue).EventTimestamp
        $results += [PSCustomObject]@{
            SubscriptionId    = $sub.Id
            ResourceType      = 'Disk'
            ResourceName      = $disk.Name
            ResourceGroupName = $disk.ResourceGroupName
            LastUsed          = $lastUsed
        }
    }

    # Identify Unused Network Interfaces (NICs)
    $unusedNICs = Get-AzNetworkInterface | Where-Object { -not $_.VirtualMachine -and $_.ProvisioningState -eq 'Succeeded' }
    foreach ($nic in $unusedNICs) {
        $results += [PSCustomObject]@{
            SubscriptionId    = $sub.Id
            ResourceType      = 'Network Interface'
            ResourceName      = $nic.Name
            ResourceGroupName = $nic.ResourceGroupName
            LastUsed          = $null  # Last used logic might not be directly applicable to NICs
        }
    }

    # Identify Idle Virtual Machines (VMs)
    $idleVMs = Get-AzVM | Where-Object {
        $status = Get-AzVM -Status -ResourceGroupName $_.ResourceGroupName -Name $_.Name
        $status.Statuses[1].Code -eq 'PowerState/deallocated' -and
        (Get-AzLog -ResourceId $_.Id -StartTime (Get-Date).AddMonths(-1)).Count -eq 0
    }
    foreach ($vm in $idleVMs) {
        $lastUsed = (Get-AzLog -ResourceId $vm.Id -MaxRecord 1 -WarningAction SilentlyContinue).EventTimestamp
        $results += [PSCustomObject]@{
            SubscriptionId    = $sub.Id
            ResourceType      = 'Virtual Machine'
            ResourceName      = $vm.Name
            ResourceGroupName = $vm.ResourceGroupName
            LastUsed          = $lastUsed
        }
    }

    # Identify Orphaned Public IP Addresses
    $orphanedPublicIPs = Get-AzPublicIpAddress | Where-Object { -not $_.IpConfiguration -and -not $_.AssociatedToLoadBalancer }
    foreach ($pip in $orphanedPublicIPs) {
        $results += [PSCustomObject]@{
            SubscriptionId    = $sub.Id
            ResourceType      = 'Public IP Address'
            ResourceName      = $pip.Name
            ResourceGroupName = $pip.ResourceGroupName
            LastUsed          = $null  # Last used logic might not be directly applicable to Public IPs
        }
    }

    # Identify Unused Virtual Networks (Vnets)
    $unusedVnets = Get-AzVirtualNetwork | Where-Object {
        $used = $false
        foreach ($subnet in $_.Subnets) {
            if ($subnet.IpConfigurations.Count -gt 0) {
                $used = $true
                break
            }
        }
        -not $used
    }
    foreach ($vnet in $unusedVnets) {
        $results += [PSCustomObject]@{
            SubscriptionId    = $sub.Id
            ResourceType      = 'Virtual Network'
            ResourceName      = $vnet.Name
            ResourceGroupName = $vnet.ResourceGroupName
            LastUsed          = $null  # Last used logic might not be directly applicable to Vnets
        }
    }

    # Identify Orphaned Resource Groups
    $orphanedResourceGroups = Get-AzResourceGroup | Where-Object {
        (Get-AzResource -ResourceGroupName $_.ResourceGroupName).Count -eq 0
    }
    foreach ($rg in $orphanedResourceGroups) {
        $results += [PSCustomObject]@{
            SubscriptionId    = $sub.Id
            ResourceType      = 'Resource Group'
            ResourceName      = $rg.ResourceGroupName
            ResourceGroupName = $rg.ResourceGroupName
            LastUsed          = $null  # Resource groups don't have a direct "last used" property
        }
    }
}

# Output results to CSV file
$results | Export-Csv -Path "orphaned-resources.csv" -NoTypeInformation

# Confirm completion
Write-Host "Orphaned resources have been identified and listed in orphaned-resources.csv"