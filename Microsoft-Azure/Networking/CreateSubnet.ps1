$VirtualNetwork = Get-AzVirtualNetwork -Name 'Packt-Script' -ResourceGroupName 'Packt-Networking-Script'
Add-AzVirtualNetworkSubnetConfig -Name FrontEnd -AddressPrefix 10.11.0.0/24 -VirtualNetwork $VirtualNetwork
$VirtualNetwork | Set-AzVirtualNetwork