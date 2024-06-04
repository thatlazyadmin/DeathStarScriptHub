<#
=========================================================================
  Script: EntraSecurityGroupCreator.ps1
  Purpose: Create Entra Security Groups based on CSV input
  Author: Shaun Hardneck
  Blog: www.thatlazyadmin.com
=========================================================================
                       __  __
                     /        \
                    |  O  O  |
                    |    >    |
                     \  --  /
=========================================================================
#>
# Function to check if a module is installed
function Check-Module {
    param (
        [Parameter(Mandatory=$true)][string]$ModuleName
    )
    return (Get-Module -ListAvailable -Name $ModuleName) -ne $null
}

# Function to prompt the user to install a module
function Prompt-InstallModule {
    param (
        [Parameter(Mandatory=$true)][string]$ModuleName
    )
    $response = Read-Host "The module '$ModuleName' is not installed. Would you like to install it? (Yes/No)"
    if ($response -eq "Yes" -or $response -eq "Y") {
        Install-Module -Name $ModuleName -Scope CurrentUser -AllowClobber -Force
    }
}

# Function to prompt the user to import a module
function Prompt-ImportModule {
    param (
        [Parameter(Mandatory=$true)][string]$ModuleName
    )
    $response = Read-Host "The module '$ModuleName' is installed. Would you like to import it? (Yes/No)"
    if ($response -eq "Yes" -or $response -eq "Y") {
        Import-Module -Name $ModuleName -Force
    }
}

# Required modules
$requiredModules = @("Microsoft.Graph.Identity.Governance", "Microsoft.Graph.Groups")

# Check and prompt for required modules
foreach ($module in $requiredModules) {
    if (-not (Check-Module -ModuleName $module)) {
        Prompt-InstallModule -ModuleName $module
    } else {
        Prompt-ImportModule -ModuleName $module
    }
}

# Silence the Microsoft Graph welcome message
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = "SilentlyContinue"

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome

# Restore the original verbose preference
$VerbosePreference = $originalVerbosePreference

# Function to create an Entra Security Group
function Create-EntraSecurityGroup {
    param (
        [Parameter(Mandatory=$true)][string]$GroupName,
        [Parameter(Mandatory=$true)][string]$Description
    )

    # Create new security group
    $groupParams = @{
        DisplayName = $GroupName
        Description = $Description
        MailEnabled = $false
        MailNickname = $GroupName.Replace(" ", "")
        SecurityEnabled = $true
        IsAssignableToRole = $false
    }
    $group = New-MgGroup @groupParams

    Write-Host "Group '$GroupName' created." -ForegroundColor Green
}

# Get the directory of the script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Read group settings from CSV file located in the same directory as the script
$csvPath = Join-Path -Path $scriptDir -ChildPath "EntraSecurityGroupsPIMSettings.csv"
$groupDetails = Import-Csv -Path $csvPath

# Create groups based on the CSV file
foreach ($detail in $groupDetails) {
    Create-EntraSecurityGroup -GroupName $detail.GroupName -Description $detail.Description
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
