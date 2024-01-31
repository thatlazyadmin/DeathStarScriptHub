$VirtualNetwork = Get-AzVirtualNetwork -Name 'Packt-Script' -ResourceGroupName 'Packt-Networking-Script'
$FrontEnd = Add-AzVirtualNetworkSubnetConfig -Name FrontEnd -AddressPrefix 10.11.0.0/24 -VirtualNetwork $VirtualNetwork
$BackEnd = Add-AzVirtualNetworkSubnetConfig -Name BackEnd -AddressPrefix 10.11.1.0/24 -VirtualNetwork $VirtualNetwork
$VirtualNetwork | Set-AzVirtualNetwork