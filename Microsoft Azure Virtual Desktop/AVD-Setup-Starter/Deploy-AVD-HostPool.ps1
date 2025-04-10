<#
.SYNOPSIS
    Deploys Azure Virtual Desktop (AVD) environment including a host pool, workspace, application group, user assignments, and a Windows 11 VM with Microsoft 365.
.DESCRIPTION
    This script helps deploy AVD in Azure by creating required resources and configurations, including a Windows 11 VM for AVD sessions.

    Author: Shaun Hardneck
    GitHub: https://github.com/thatlazyadmin
.PARAMETER SubscriptionId
    Specify the subscription ID where resources will be created.
.NOTES
    Please review and adapt for production as necessary.
#>

# Set Error Log File
$logFilePath = Join-Path -Path (Get-Location) -ChildPath "AVD_Deployment_Log.txt"
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Function to Log Errors
function Log-Error {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "$timestamp - $Message"
    Add-Content -Path $logFilePath -Value $fullMessage
}

# Suppress Progress and Information Messages for Cleaner Output
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

# Function to Check and Import Required Module
function Check-Module {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "$ModuleName module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Force -Scope CurrentUser -ErrorAction Stop 2>> $logFilePath
    }
    Import-Module $ModuleName -ErrorAction Stop 2>> $logFilePath
}

# Check for Az Modules
Check-Module -ModuleName "Az"
Check-Module -ModuleName "Az.DesktopVirtualization"

# Set User Prompts
$subscriptionId = Read-Host -Prompt "Enter your Subscription ID"
$resourceGroupName = Read-Host -Prompt "Enter a name for the Resource Group"
$location = Read-Host -Prompt "Enter the Azure Region (e.g., eastus)"
$hostPoolName = Read-Host -Prompt "Enter the Host Pool Name"
$workspaceName = Read-Host -Prompt "Enter the Workspace Name"
$appGroupName = Read-Host -Prompt "Enter the Application Group Name"
$maxSessionLimit = Read-Host -Prompt "Enter Max Session Limit for Host Pool (integer value)"
$assignUser = Read-Host -Prompt "Enter the UPN of the user to assign to Application Group"

# Connect to Azure and set the subscription context
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
Connect-AzAccount -ErrorAction Stop 2>> $logFilePath
Set-AzContext -SubscriptionId $subscriptionId 2>> $logFilePath

# Create Resource Group if it doesn't exist
Write-Host "Ensuring Resource Group exists..." -ForegroundColor Green
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop 2>> $logFilePath | Out-Null
    Write-Host "Resource Group '$resourceGroupName' created." -ForegroundColor Green
} else {
    Write-Host "Resource Group '$resourceGroupName' already exists." -ForegroundColor Yellow
}

# Create Host Pool with Standard Management
Write-Host "Creating Host Pool..." -ForegroundColor Green
$hostPoolParameters = @{
    Name                   = $hostPoolName
    ResourceGroupName      = $resourceGroupName
    HostPoolType           = 'Pooled'
    LoadBalancerType       = 'BreadthFirst'
    PreferredAppGroupType  = 'Desktop'
    MaxSessionLimit        = [int]$maxSessionLimit
    Location               = $location
}

try {
    New-AzWvdHostPool @hostPoolParameters 2>> $logFilePath | Out-Null
    Write-Host "Host Pool '$hostPoolName' created successfully." -ForegroundColor Green
} catch {
    Log-Error "Error creating Host Pool: $_"
    exit
}

# Create Workspace
Write-Host "Creating Workspace..." -ForegroundColor Green
$workspaceParameters = @{
    Name              = $workspaceName
    ResourceGroupName = $resourceGroupName
    Location          = $location
}

try {
    New-AzWvdWorkspace @workspaceParameters 2>> $logFilePath | Out-Null
    Write-Host "Workspace '$workspaceName' created successfully." -ForegroundColor Green
} catch {
    Log-Error "Error creating Workspace: $_"
    exit
}

# Create Application Group for Host Pool
Write-Host "Creating Application Group..." -ForegroundColor Green
$hostPoolId = (Get-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $resourceGroupName -ErrorAction Stop).Id
$appGroupParameters = @{
    Name                 = $appGroupName
    ResourceGroupName    = $resourceGroupName
    ApplicationGroupType = 'Desktop'
    HostPoolArmPath      = $hostPoolId
    Location             = $location
}

try {
    New-AzWvdApplicationGroup @appGroupParameters 2>> $logFilePath | Out-Null
    Write-Host "Application Group '$appGroupName' created successfully." -ForegroundColor Green
} catch {
    Log-Error "Error creating Application Group: $_"
    exit
}

# Add Application Group to Workspace
Write-Host "Associating Application Group with Workspace..." -ForegroundColor Green
$appGroupId = (Get-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $resourceGroupName -ErrorAction Stop).Id
Update-AzWvdWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -ApplicationGroupReference $appGroupId 2>> $logFilePath | Out-Null
Write-Host "Application Group associated with Workspace." -ForegroundColor Green

# Retrieve Object ID of User or Group for Role Assignment
Write-Host "Retrieving Object ID for user '$assignUser'..." -ForegroundColor Cyan
try {
    $principalId = (Get-AzADUser -UserPrincipalName $assignUser -ErrorAction Stop).Id
} catch {
    Log-Error "Error retrieving Principal ID for user '$assignUser': $_"
    Write-Host "Failed to retrieve Principal ID. Please check user UPN." -ForegroundColor Red
    exit
}

# Assign User to Application Group
Write-Host "Assigning user '$assignUser' to Application Group..." -ForegroundColor Green
$userParameters = @{
    PrincipalId           = $principalId
    RoleDefinitionName    = 'Desktop Virtualization User'
    Scope                 = $appGroupId
}

try {
    New-AzRoleAssignment @userParameters 2>> $logFilePath | Out-Null
    Write-Host "User '$assignUser' assigned to Application Group successfully." -ForegroundColor Green
} catch {
    Log-Error "Error assigning user to Application Group: $_"
}

# Create Windows 11 Session Host VM with Microsoft 365
Write-Host "Creating Windows 11 VM with Microsoft 365..." -ForegroundColor Cyan
$vmName = "AVD-Win11-SessionHost"
$publicIpName = "$vmName-PublicIP"
$nicName = "$vmName-NIC"
$vnetName = "hostVNet"
$subnetName = "hostSubnet"

# Create Public IP for VM
$publicIp = New-AzPublicIpAddress -Name $publicIpName `
                                  -ResourceGroupName $resourceGroupName `
                                  -Location $location `
                                  -AllocationMethod "Static" `
                                  -Sku "Standard" 2>> $logFilePath | Out-Null

# Create NIC for VM
$nic = New-AzNetworkInterface -Name $nicName `
                              -ResourceGroupName $resourceGroupName `
                              -Location $location `
                              -SubnetId (Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName).Subnets[0].Id `
                              -PublicIpAddressId $publicIp.Id 2>> $logFilePath | Out-Null

# Set VM Specs
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_D2s_v3" |
            Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (Get-Credential) |
            Set-AzVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-11" -Skus "win11-22h2-pro" -Version "latest" |
            Set-AzVMOSDisk -DiskSizeInGB 128 -CreateOption FromImage |
            Add-AzVMNetworkInterface -Id $nic.Id

# Create the VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig 2>> $logFilePath | Out-Null
Write-Host "Windows 11 VM with Microsoft 365 created successfully." -ForegroundColor Green

# Reset Output Preferences
$ProgressPreference = 'Continue'
$InformationPreference = 'Continue'
$WarningPreference = 'Continue'
$ErrorActionPreference = 'Continue'

Write-Host "Azure Virtual Desktop environment setup is complete." -ForegroundColor Cyan
Write-Host "All errors and warnings have been logged to $logFilePath" -ForegroundColor Yellow