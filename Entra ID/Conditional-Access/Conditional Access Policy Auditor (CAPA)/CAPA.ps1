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

# Suppress Progress and Information Messages
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

# Function to Check if Required Modules are Installed
function Check-Module {
    param (
        [string]$ModuleName
    )

    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "$ModuleName module is already available and loaded." -ForegroundColor Green
    } else {
        Write-Host "$ModuleName module is not available. Attempting installation..." -ForegroundColor Yellow
        try {
            Install-Module -Name $ModuleName -Force -Scope CurrentUser -ErrorAction Stop
            Write-Host "$ModuleName module installed successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to install $ModuleName module. Please close all other PowerShell sessions and retry." -ForegroundColor Red
            exit
        }
    }
}

# Check if Az Module is Installed
Check-Module -ModuleName "Az"
Import-Module Az -ErrorAction Stop

# Begin User Prompt Section
Write-Host "Welcome to the Azure Virtual Desktop Setup Script" -ForegroundColor Cyan
Write-Host "Please follow the prompts to configure your Azure Virtual Desktop environment." -ForegroundColor Cyan

# Prompt for required parameters with validation
$subscriptionId = Read-Host -Prompt "Enter your Subscription ID"
$resourceGroupName = Read-Host -Prompt "Enter a name for the Resource Group"
$location = Read-Host -Prompt "Enter the Azure Region (e.g., eastus)"
$hostPoolName = Read-Host -Prompt "Enter the Host Pool Name"

# Provide options for Join Type and validate the input
$joinType = ""
while ($joinType -notin @("AD", "Entra")) {
    $joinType = Read-Host -Prompt "Select Join Type (AD for Active Directory / Entra for Entra ID)"
    if ($joinType -notin @("AD", "Entra")) {
        Write-Host "Invalid input. Please enter 'AD' or 'Entra'." -ForegroundColor Red
    }
}

# Provide options for Intune Enrollment and validate the input
$intuneEnroll = ""
while ($intuneEnroll -notin @("Yes", "No")) {
    $intuneEnroll = Read-Host -Prompt "Do you want the session host to enroll in Intune? (Yes/No)"
    if ($intuneEnroll -notin @("Yes", "No")) {
        Write-Host "Invalid input. Please enter 'Yes' or 'No'." -ForegroundColor Red
    }
}

# Connect to Azure and set the subscription context
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
Connect-AzAccount -ErrorAction Stop
Set-AzContext -SubscriptionId $subscriptionId

# Create or Validate Resource Group
Write-Host "Ensuring Resource Group exists..." -ForegroundColor Green
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop | Out-Null
    Write-Host "Resource Group '$resourceGroupName' created in $location." -ForegroundColor Green
} else {
    Write-Host "Resource Group '$resourceGroupName' already exists." -ForegroundColor Yellow
}

# Create Host Pool with specified parameters
Write-Host "Creating Host Pool..." -ForegroundColor Green
New-AzWvdHostPool -ResourceGroupName $resourceGroupName `
                  -HostPoolName $hostPoolName `
                  -Location $location `
                  -HostPoolType "Pooled" `
                  -PreferredAppGroupType "Desktop" `
                  -LoadBalancerType "BreadthFirst" `
                  -MaxSessionLimit 2 `
                  -ValidationEnvironment $false

# Generate registration token for the host pool
Write-Host "Generating registration token for the host pool..." -ForegroundColor Green
try {
    $regToken = New-AzWvdRegistrationInfo -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -ExpirationTime ((Get-Date).AddHours(4))
    $registrationToken = $regToken.Token
    Write-Host "Registration Token: $registrationToken" -ForegroundColor Yellow
} catch {
    Write-Host "Failed to generate the registration token. Please check if the Host Pool was created successfully." -ForegroundColor Red
    exit
}

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
} elseif ($joinType -eq "Entra") {
    Write-Host "Entra ID join selected. VM will be joined to Entra ID." -ForegroundColor Green
}

# Conditional handling for Intune Enrollment
if ($intuneEnroll -eq "Yes") {
    Write-Host "Enabling Intune enrollment for the session host." -ForegroundColor Green
} else {
    Write-Host "Intune enrollment not selected." -ForegroundColor Yellow
}

Write-Host "Azure Virtual Desktop setup complete. Proceed to register the VM with the host pool using the registration token." -ForegroundColor Green

# Reset Preferences
$ProgressPreference = 'Continue'
$InformationPreference = 'Continue'

# End of script
