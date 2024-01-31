# Connect to Azure account
Connect-AzAccount

# Get all available subscriptions
$subscriptions = Get-AzSubscription

# Display available subscriptions in orange and prompt for selection
if ($subscriptions.Count -eq 0) {
    Write-Host "No Azure subscriptions are available." -ForegroundColor Red
    exit
}
Write-Host "Available Azure Subscriptions:" -ForegroundColor DarkYellow
for ($i = 0; $i -lt $subscriptions.Count; $i++) {
    Write-Host "$($i + 1): $($subscriptions[$i].Name) - $($subscriptions[$i].Id)" -ForegroundColor DarkYellow
}
while ($true) {
    $selectedSubscriptionIndex = Read-Host "Select a subscription by entering a number (1-$($subscriptions.Count))"
    if ($selectedSubscriptionIndex -match '^\d+$' -and [int]$selectedSubscriptionIndex -gt 0 -and [int]$selectedSubscriptionIndex -le $subscriptions.Count) {
        $selectedSubscription = $subscriptions[[int]$selectedSubscriptionIndex - 1]
        Write-Host "You have selected the subscription: $($selectedSubscription.Name)" -ForegroundColor Green
        Set-AzContext -SubscriptionId $selectedSubscription.Id
        break
    } else {
        Write-Host "Invalid selection. Please enter a number between 1 and $($subscriptions.Count)." -ForegroundColor Red
    }
}

# Variables
$location = "southafricanorth"
$today = Get-Date -Format "yyyyMMdd"
$resourceGroupName = "thatlazyadminLab-$today"
$virtualNetworkName = "thatlazyadminVNet-$today"
$subnetName = "thatlazyadminSubnet"
$nsgName = "thatlazyadminNSG-$today"
$adminUsername = "adminuser"
$adminPassword = ConvertTo-SecureString "Password123!" -AsPlainText -Force
$vmSize = "Standard_B1s"
$image = "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest"
$openPorts = @(80, 3389)

# Create a new resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create NSG and rules
$nsgRule1 = New-AzNetworkSecurityRuleConfig -Name "BlockPort443" -Access "Deny" -Protocol "Tcp" -Direction "Inbound" -Priority 100 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 443
$nsgRule2 = New-AzNetworkSecurityRuleConfig -Name "BlockPort80" -Access "Deny" -Protocol "Tcp" -Direction "Inbound" -Priority 110 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 80
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName -SecurityRules $nsgRule1, $nsgRule2

# Wait for NSG to be fully provisioned
Start-Sleep -Seconds 10

# Create a virtual network
$vnet = New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16"

# Create a subnet and associate it with the NSG
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24"
$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet
$vnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg
$vnet | Set-AzVirtualNetwork

# Output Virtual Network and Subnet details
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }
Write-Host "Virtual Network '$virtualNetworkName' with address range '$($vnet.AddressSpace.AddressPrefixes)' has been created." -ForegroundColor Green
Write-Host "Subnet '$subnetName' with address range '$($subnet.AddressPrefix)' has been associated with NSG '$nsgName'." -ForegroundColor Green

# Wait for virtual network and subnet to be fully provisioned
Start-Sleep -Seconds 30

# Create VMs and install Web Server
$vmNames = @("vm1-lazylab$(Get-Date -Format 'ddMM')", "vm2-lazylab$(Get-Date -Format 'ddMM')")
foreach ($vmName in $vmNames) {
    $newVm = New-AzVm -ResourceGroupName $resourceGroupName -Name $vmName -Location $location -Image $image -VirtualNetworkName $virtualNetworkName -SubnetName $subnetName -SecurityGroupName $nsgName -OpenPorts $openPorts -Size $vmSize -Credential (New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword))
    
    # Wait for VM to be fully provisioned
    Start-Sleep -Seconds 30
    
    # Install Web Server on the VM
    $scriptString = 'Install-WindowsFeature -Name Web-Server -IncludeManagementTools'
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptString $scriptString
}

# Output summary
Write-Host "Lab environment deployment complete." -ForegroundColor Green