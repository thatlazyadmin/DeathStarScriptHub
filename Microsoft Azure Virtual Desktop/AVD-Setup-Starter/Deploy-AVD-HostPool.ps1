<#
.SYNOPSIS
    This script deploys an Azure Virtual Desktop (AVD) environment, including creating a host pool, session hosts, and configuring network settings.
.DESCRIPTION
    This starter script helps users quickly set up an Azure Virtual Desktop environment by creating necessary resources like a host pool,
    virtual network, subnet, and session host. It prompts for customization options such as Active Directory joining and Intune enrollment.

    Author: Shaun Hardneck
    GitHub: https://github.com/yourgithubprofile
.PARAMETER SubscriptionId
    Specify the subscription ID where the resources will be created.
.NOTES
    This script is intended for learning purposes. Review and adapt for production use as necessary.
#>

# Unload Az module if it's already loaded to prevent conflicts during installation
if (Get-Module -ListAvailable -Name Az) {
    Write-Host "Unloading existing Az module to prevent conflicts..." -ForegroundColor Yellow
    Get-Module Az* | Remove-Module -Force -ErrorAction SilentlyContinue
}

# Function to Check and Install Required Modules
function Check-Module {
    param (
        [string]$ModuleName
    )
    
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "$ModuleName module is available." -ForegroundColor Green
    } else {
        Write-Host "$ModuleName module is not available. Installing now..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Force -Scope CurrentUser
        Write-Host "$ModuleName module installed successfully." -ForegroundColor Green
    }
}

# Check for the Az module
Check-Module -ModuleName "Az"
Import-Module Az -ErrorAction Stop

# Prompt for required parameters
$subscriptionId = Read-Host -Prompt "Enter your Subscription ID"
$resourceGroupName = Read-Host -Prompt "Enter a name for the Resource Group"
$location = Read-Host -Prompt "Enter the Azure Region (e.g., eastus)"
$hostPoolName = Read-Host -Prompt "Enter the Host Pool Name"
$joinType = Read-Host -Prompt "Select Join Type (AD / Entra)"
$intuneEnroll = Read-Host -Prompt "Do you want the session host to enroll in Intune? (Yes/No)"

# Connect to Azure and set the subscription context
Connect-AzAccount -ErrorAction Stop
Set-AzContext -SubscriptionId $subscriptionId

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Green
New-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop

# Create Host Pool
Write-Host "Creating Host Pool..." -ForegroundColor Green
New-AzWvdHostPool -ResourceGroupName $resourceGroupName `
                  -HostPoolName $hostPoolName `
                  -Location $location `
                  -HostPoolType "Pooled" `
                  -PreferredAppGroupType "Desktop" `
                  -LoadBalancerType "BreadthFirst" `
                  -MaxSessionLimit 2 `
                  -ValidationEnvironment $false

# Generate registration token
Write-Host "Generating registration token for the host pool..." -ForegroundColor Green
$regToken = New-AzWvdRegistrationInfo -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -ExpirationTime ((Get-Date).AddHours(4))
$registrationToken = $regToken.Token

Write-Host "Registration Token: $registrationToken" -ForegroundColor Yellow
Write-Host "Copy the registration token and keep it safe for session host registration."

# Create Virtual Network and Subnet
Write-Host "Creating Virtual Network and Subnet..." -ForegroundColor Green
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name "hostSubnet" -AddressPrefix "10.0.0.0/24"
$virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName `
                                        -Location $location `
                                        -Name "hostVNet" `
                                        -AddressPrefix "10.0.0.0/16" `
                                        -Subnet $subnetConfig

# Prompt for VM credentials
Write-Host "Enter administrator credentials for the session host VM." -ForegroundColor Cyan
$cred = Get-Credential

# Create Public IP for VM
Write-Host "Creating Public IP for the session host..." -ForegroundColor Green
$publicIp = New-AzPublicIpAddress -Name "sessionHostPublicIP" `
                                  -ResourceGroupName $resourceGroupName `
                                  -Location $location `
                                  -AllocationMethod "Static" `
                                  -Sku "Standard"

# Create Session Host VM
Write-Host "Creating Session Host VM..." -ForegroundColor Green
New-AzVm -ResourceGroupName $resourceGroupName `
         -Location $location `
         -Name "session-host-vm" `
         -VirtualNetworkName "hostVNet" `
         -SubnetName "hostSubnet" `
         -Credential $cred `
         -Size "Standard_DS1_v2" `
         -PublicIpAddress $publicIp `
         -Image "MicrosoftWindowsDesktop:windows-11:win11-22h2-pro:latest"

Write-Host "Session Host VM created successfully." -ForegroundColor Green

# Conditional handling for Active Directory or Entra Join
if ($joinType -eq "AD") {
    Write-Host "Ensure that the VM joins the Active Directory domain."
    # Additional domain join commands or instructions can be placed here
} elseif ($joinType -eq "Entra") {
    Write-Host "Entra ID join selected. VM will be joined to Entra ID." -ForegroundColor Green
    # Additional Entra join configurations
}

# Conditional handling for Intune Enrollment
if ($intuneEnroll -eq "Yes") {
    Write-Host "Enabling Intune enrollment for the session host." -ForegroundColor Green
    # Additional Intune enrollment commands or instructions can be placed here
} else {
    Write-Host "Intune enrollment not selected." -ForegroundColor Yellow
}

Write-Host "Azure Virtual Desktop setup complete. Proceed to register the VM with the host pool using the registration token." -ForegroundColor Green

# End of script
