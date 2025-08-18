# Dummy VNet, Subnets, Route Tables, and Routes Creation Script
# Created for Testing Documentation Script

# Variables - Change these as needed
$SubscriptionId = "6052118b-adbb-4504-a41a-e8e1121163fe"  # Change this to your subscription ID
$ResourceGroup = "rg-lab-networking"
$Location = "UKSouth"
$VNetName = "lab-VNet"
$SubnetNames = @("Subnet-A", "Subnet-B", "Subnet-C") # List of subnets to create
$BaseSubnetPrefix = "172.16" # Base subnet prefix (172.x.x.x)
$NumberOfRouteTables = 2
$NumberOfRoutesPerTable = 20

# Connect to Azure and Set Subscription
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
Connect-AzAccount
Set-AzContext -SubscriptionId $SubscriptionId

# Ensure Resource Group Exists
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Resource Group: $ResourceGroup" -ForegroundColor Green
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}

# Create Virtual Network and Subnets
Write-Host "Creating Virtual Network: $VNetName" -ForegroundColor Green
$AddressSpace = "$BaseSubnetPrefix.0.0/16"
$SubnetConfigs = @()

# Generate valid subnet prefixes
for ($i = 0; $i -lt $SubnetNames.Count; $i++) {
    $SubnetPrefix = "$BaseSubnetPrefix.$(($i+1)).0/24"
    Write-Host "Adding Subnet: $($SubnetNames[$i]) with Address Prefix: $SubnetPrefix" -ForegroundColor Yellow
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetNames[$i] -AddressPrefix $SubnetPrefix
    $SubnetConfigs += $SubnetConfig
}

# Create VNet with Subnets
$VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VNetName -AddressPrefix $AddressSpace -Subnet $SubnetConfigs

# Create Dummy Route Tables and Routes
for ($i = 1; $i -le $NumberOfRouteTables; $i++) {
    $RouteTableName = "DummyRouteTable-$i"
    
    if (-not (Get-AzRouteTable -ResourceGroupName $ResourceGroup -Name $RouteTableName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating Route Table: $RouteTableName" -ForegroundColor Green
        $RouteTable = New-AzRouteTable -ResourceGroupName $ResourceGroup -Location $Location -Name $RouteTableName
    } else {
        $RouteTable = Get-AzRouteTable -ResourceGroupName $ResourceGroup -Name $RouteTableName
    }

    # Adding Dummy Routes
    for ($j = 1; $j -le $NumberOfRoutesPerTable; $j++) {
        $RouteName = "DummyRoute-$i-$j"
        $AddressPrefix = "$BaseSubnetPrefix.$(($j+10)).0/24"
        $NextHopType = "VirtualAppliance"
        $NextHopIpAddress = "172.16.0.4"

        Write-Host "Adding Route: $RouteName to $RouteTableName" -ForegroundColor Yellow
        Add-AzRouteConfig -Name $RouteName -AddressPrefix $AddressPrefix -NextHopType $NextHopType -NextHopIpAddress $NextHopIpAddress -RouteTable $RouteTable | Set-AzRouteTable
    }

    # Associate Route Table with First Subnet
    $FirstSubnet = $VNet.Subnets[0]
    Write-Host "Associating $RouteTableName with $($FirstSubnet.Name)" -ForegroundColor Cyan
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $FirstSubnet.Name -AddressPrefix $FirstSubnet.AddressPrefix -RouteTableId $RouteTable.Id
    $VNet | Set-AzVirtualNetwork
}

Write-Host "Dummy VNet, Subnets, Route Tables, and Routes Created Successfully!" -ForegroundColor Green