#CreatedBy: Shaun Hardneck
#www.thatlazyadmin.com

# Login to Azure
Connect-AzAccount

# Get subscriptions and allow user to select
$subscriptions = Get-AzSubscription
for ($i = 0; $i -lt $subscriptions.Count; $i++) {
    Write-Host ("{0}: {1} - {2}" -f $i, $subscriptions[$i].Name, $subscriptions[$i].Id) -ForegroundColor Green
}
$selectedSubscriptionIndex = $null
while ($null -eq $selectedSubscriptionIndex) {
    $input = Read-Host "Enter the number of the subscription you want to select (0-$($subscriptions.Count - 1))"
    if ($input -match '^\d+$') {
        $inputInt = [int]$input
        if ($inputInt -ge 0 -and $inputInt -lt $subscriptions.Count) {
            $selectedSubscriptionIndex = $inputInt
        } else {
            Write-Host "Invalid selection, please select a valid subscription number" -ForegroundColor Red
        }
    } else {
        Write-Host "Please enter a numerical value" -ForegroundColor Red
    }
}
$context = Set-AzContext -SubscriptionId $subscriptions[$selectedSubscriptionIndex].Id

# Get VNets in the selected subscription and allow user to select
$vnets = Get-AzVirtualNetwork
for ($i = 0; $i -lt $vnets.Count; $i++) {
    Write-Host ("{0}: {1} - {2}" -f $i, $vnets[$i].Name, $vnets[$i].Id) -ForegroundColor Green
}
$selectedVNetIndex = $null
while ($null -eq $selectedVNetIndex) {
    $input = Read-Host "Enter the number of the VNet you want to select (0-$($vnets.Count - 1))"
    if ($input -match '^\d+$') {
        $inputInt = [int]$input
        if ($inputInt -ge 0 -and $inputInt -lt $vnets.Count) {
            $selectedVNetIndex = $inputInt
        } else {
            Write-Host "Invalid selection, please select a valid VNet number" -ForegroundColor Red
        }
    } else {
        Write-Host "Please enter a numerical value" -ForegroundColor Red
    }
}
$selectedVNet = $vnets[$selectedVNetIndex]

# Get Subnets in the selected VNet and allow user to select
$subnets = $selectedVNet.Subnets
for ($i = 0; $i -lt $subnets.Count; $i++) {
    Write-Host ("{0}: {1}" -f $i, $subnets[$i].Name) -ForegroundColor Green
}
$selectedSubnetIndex = $null
while ($null -eq $selectedSubnetIndex) {
    $input = Read-Host "Enter the number of the Subnet you want to select (0-$($subnets.Count - 1))"
    if ($input -match '^\d+$') {
        $inputInt = [int]$input
        if ($inputInt -ge 0 -and $inputInt -lt $subnets.Count) {
            $selectedSubnetIndex = $inputInt
        } else {
            Write-Host "Invalid selection, please select a valid Subnet number" -ForegroundColor Red
        }
    } else {
        Write-Host "Please enter a numerical value" -ForegroundColor Red
    }
}
$selectedSubnet = $subnets[$selectedSubnetIndex]

# Prompt for region and resource group
$region = Read-Host "Enter the Azure region (e.g., southafricanorth)"
$resourceGroupName = Read-Host "Enter the name of the Resource Group"

# Create NSG
$nsgName = Read-Host "Enter a name for the Network Security Group"
$nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -Location $region

# Define NSG rule to block inbound HTTP traffic
$httpRule = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "BlockHTTP" -Description "Block Outbound HTTP traffic" -Access Deny -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix "Internet" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 80

# Define NSG rule to block inbound HTTPS traffic
$httpsRule = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "BlockHTTPS" -Description "Block Outbound HTTPS traffic" -Access Deny -Protocol Tcp -Direction Outbound -Priority 101 -SourceAddressPrefix "Internet" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 443

# Update the NSG
$nsg | Set-AzNetworkSecurityGroup

# Associate NSG with the selected subnet
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $selectedVNet -Name $selectedSubnet.Name -AddressPrefix $selectedSubnet.AddressPrefix -NetworkSecurityGroup $nsg
$selectedVNet | Set-AzVirtualNetwork

Write-Host "NSG and rules to block HTTP and HTTPS traffic have been created and associated with the subnet." -ForegroundColor Green