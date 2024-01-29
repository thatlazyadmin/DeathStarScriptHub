$vnet = Get-AzVirtualNetwork -Name ‘Packt-Script’ -ResourceGroupName ‘Packt-Networking-Script’
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name BackEnd
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName ‘Packt-Networking-Script’ -Name ‘nsg1’
$subnet.NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet
