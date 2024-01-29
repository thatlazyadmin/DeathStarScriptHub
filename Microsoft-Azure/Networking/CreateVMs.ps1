$ResourceGroupName = "packt-demo"
$location = "westeurope"
$vmName = "packtdemoVM"
$NumberOfServers= 2

New-AzResourceGroup -Name $ResourceGroupName -Location $location

$i=1

Do

{

Get-AzAvailabilitySet $vmName"set1" -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    New-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $vmName"set1" -Location $location -Sku aligned -PlatformFaultDomainCount 2
}
else
{
    # Availability Set exist
}

New-AzVm -ResourceGroupName $ResourceGroupName -Name $vmName"-0"$i -Location $location -VirtualNetworkName $vmName"-Vnet" -SubnetName $vmName"-subnet"  -AvailabilitySetName $vmName"set1" -SecurityGroupName $vmName"-nsg" -PublicIpAddressName $vmName"-IP-"$i -OpenPorts 80,443,3389

} While (($i=$I+1) -le $NumberOfServers)