$vnet = Get-AzVirtualNetwork -ResourceGroupName 'Packt-Networking-Script' -Name 'Packt-Script'
Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.11.2.0/27 -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork
$gwpip = New-AzPublicIpAddress -Name VNet1GWIP -ResourceGroupName 'Packt-Networking-Script' -Location 'westeurope' -AllocationMethod Dynamic

$vnet = Get-AzVirtualNetwork -ResourceGroupName 'Packt-Networking-Script' -Name 'Packt-Script'
$subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id
New-AzVirtualNetworkGateway -Name VNet1GW -ResourceGroupName 'Packt-Networking-Script' -Location 'westeurope' -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1
