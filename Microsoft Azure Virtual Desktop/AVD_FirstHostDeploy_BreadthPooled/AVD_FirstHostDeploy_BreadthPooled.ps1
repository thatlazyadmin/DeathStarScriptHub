# Synopsis
# This script deploys an Azure Virtual Desktop environment with the first session host.
# It prompts for the Azure subscription, creates a new resource group, and deploys the session host with Breadth-first load balancing, pooled host type, and a max session limit of 10.
# Created by: Shaun Hardneck

# Clear the console
Clear-Host

# Add color functions
function Write-Color {
    param (
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Message
    $Host.UI.RawUI.ForegroundColor = $oldColor
}

# Suppress Azure module warnings
$WarningPreference = "SilentlyContinue"

# Header note for AVD regions
Write-Color "Note: Azure Virtual Desktop resources are only available in the following regions:" -Color Yellow
Write-Color "centralindia, uksouth, ukwest, japaneast, japanwest, australiaeast, canadaeast, canadacentral, northeurope, westeurope, eastus, eastus2, westus, westus2, westus3, northcentralus, southcentralus, westcentralus, centralus" -Color Cyan

# Connect to Azure
Write-Color "Connecting to Azure..." -Color Cyan
# This will automatically ask for login and subscription selection if multiple subscriptions exist
Connect-AzAccount -WarningAction SilentlyContinue

# Get the current context to avoid re-selecting the subscription
$currentContext = Get-AzContext

# Display the selected subscription
Write-Color "Using Subscription: $($currentContext.Subscription.Name)" -Color Yellow

# Prompt for Resource Group Name
$resourceGroupName = Read-Host "Enter the new Resource Group name"

# Prompt for location and ensure the location supports AVD (Azure Virtual Desktop)
$location = Read-Host "Enter the location for the new Resource Group (e.g., EastUS, WestEurope, EastUS2)"
$validLocations = @('centralindia', 'uksouth', 'ukwest', 'japaneast', 'japanwest', 'australiaeast', 'canadaeast', 'canadacentral', 'northeurope', 'westeurope', 'eastus', 'eastus2', 'westus', 'westus2', 'westus3', 'northcentralus', 'southcentralus', 'westcentralus', 'centralus')

# Check if the chosen location is valid
if (-not $validLocations -contains $location.ToLower()) {
    Write-Color "Invalid location '$location'. Using default location 'eastus2'." -Color Red
    $location = 'eastus2'
}

# Create new Resource Group
Write-Color "Creating new Resource Group '$resourceGroupName' in location '$location'..." -Color Cyan
New-AzResourceGroup -Name $resourceGroupName -Location $location -WarningAction SilentlyContinue

Write-Color "Resource Group '$resourceGroupName' created successfully!" -Color Green

# Fetch available Virtual Networks in the selected subscription
$vnetList = Get-AzVirtualNetwork -WarningAction SilentlyContinue

# Display available Virtual Networks for selection
if ($vnetList.Count -eq 0) {
    Write-Color "No Virtual Networks found in the selected subscription." -Color Red
    exit
}

Write-Color "Available Virtual Networks:" -Color Cyan
for ($i = 0; $i -lt $vnetList.Count; $i++) {
    Write-Color "[$i] $($vnetList[$i].Name) in Resource Group: $($vnetList[$i].ResourceGroupName)" -Color Green
}

# Prompt user to select a Virtual Network
$vnetSelection = Read-Host "Select the Virtual Network by entering the corresponding number"
$selectedVnet = $vnetList[$vnetSelection]

# Fetch available Subnets from the selected Virtual Network
$subnetList = $selectedVnet.Subnets

# Display available Subnets for selection
if ($subnetList.Count -eq 0) {
    Write-Color "No Subnets found in the selected Virtual Network." -Color Red
    exit
}

Write-Color "Available Subnets:" -Color Cyan
for ($i = 0; $i -lt $subnetList.Count; $i++) {
    Write-Color "[$i] $($subnetList[$i].Name)" -Color Green
}

# Prompt user to select a Subnet
$subnetSelection = Read-Host "Select the Subnet by entering the corresponding number"
$selectedSubnet = $subnetList[$subnetSelection].Id  # Correctly fetch Subnet ID

# Prompt for AVD Host Pool Name
$hostPoolName = Read-Host "Enter the Host Pool name"

# Prompt for Session Host VM Name
$vmName = Read-Host "Enter the Session Host VM Name"

# Prompt for VM Admin Credentials
$adminUsername = Read-Host "Enter the Admin Username for the VM"
$adminPassword = Read-Host "Enter the Admin Password for the VM" -AsSecureString

# Set the max session limit to 10, load balancing to Breadth-first, and host type to pooled
$maxSessions = 10
$loadBalancingAlgorithm = "BreadthFirst"
$hostPoolType = "Pooled"
$preferredAppGroupType = "Desktop"  # Options: "Desktop" for full desktop or "RailApplications" for remote apps
$personalDesktopAssignmentType = "Automatic"  # Only used if HostPoolType is "Personal", automatically assigns a VM

# Confirm before proceeding
Write-Color "The session host will be created with the following settings:" -Color Yellow
Write-Color "Host Pool Name: $hostPoolName" -Color Yellow
Write-Color "Max Sessions: $maxSessions" -Color Yellow
Write-Color "Load Balancing Algorithm: $loadBalancingAlgorithm" -Color Yellow
Write-Color "Host Pool Type: $hostPoolType" -Color Yellow
Write-Color "Preferred App Group Type: $preferredAppGroupType" -Color Yellow
Write-Color "Selected Virtual Network: $($selectedVnet.Name)" -Color Yellow
Write-Color "Selected Subnet: $selectedSubnet" -Color Yellow
$confirmation = Read-Host "Do you want to proceed? (Y/N)"
if ($confirmation -ne "Y") {
    Write-Color "Operation cancelled." -Color Red
    exit
}

# Create the Host Pool
Write-Color "Creating Azure Virtual Desktop Host Pool..." -Color Cyan
New-AzWvdHostPool -ResourceGroupName $resourceGroupName `
    -Name $hostPoolName `
    -Location $location `
    -MaxSessionLimit $maxSessions `
    -LoadBalancerType $loadBalancingAlgorithm `
    -HostPoolType $hostPoolType `
    -PreferredAppGroupType $preferredAppGroupType `
    -WarningAction SilentlyContinue

Write-Color "Host Pool '$hostPoolName' created successfully!" -Color Green

# Create Session Host VM
Write-Color "Creating Session Host VM..." -Color Cyan

# Create the network interface
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName `
    -Name "$vmName-nic" `
    -Location $location `
    -SubnetId $selectedSubnet `
    -WarningAction SilentlyContinue

# Create the VM config
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_D2_v3" `
    | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, $adminPassword)) `
    | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "windows-10" -Skus "21h1-pro" -Version "latest" `
    | Add-AzVMNetworkInterface -Id $nic.Id

# Deploy the VM
New-AzVM -ResourceGroupName $resourceGroupName `
    -Location $location `
    -VM $vmConfig -WarningAction SilentlyContinue

Write-Color "Session Host VM '$vmName' created successfully!" -Color Green

# Success message
Write-Color "Azure Virtual Desktop environment deployed successfully!" -Color Green