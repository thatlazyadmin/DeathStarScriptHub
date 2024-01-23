# PowerShell Script to List All Microsoft 365 Groups with Their Visibility Status
#CreatedBy: Shaun Hardneck
#www.thatlazyadmin.com

# Function to check and install AzureAD module
function CheckAndInstallAzureADModule {
    $module = Get-Module -ListAvailable -Name AzureAD
    if (-not $module) {
        Write-Host "AzureAD module not found. Installing now..."
        Install-Module -Name AzureAD -Scope CurrentUser -Force
    }
    Write-Host "PowerShell Module AzureAD has been installed" -ForegroundColor Green
}

# Check and install AzureAD module
CheckAndInstallAzureADModule

# Import the AzureAD module
Import-Module AzureAD

# Connect to Azure AD with modern authentication
try {
    Connect-AzureAD
}
catch {
    Write-Error "Failed to connect to Azure AD. Please ensure you have the necessary permissions and MFA set up."
    return
}

# Function to get all Microsoft 365 Groups and their visibility status
function Get-M365GroupsStatus {
    try {
        $allGroups = Get-AzureADMSGroup -All $true | Where-Object { $_.GroupTypes -contains "Unified" }

        $groupList = @()
        foreach ($group in $allGroups) {
            $groupDetails = New-Object PSObject -Property @{
                GroupName = $group.DisplayName
                Visibility = $group.Visibility
            }
            $groupList += $groupDetails
        }

        return $groupList
    }
    catch {
        Write-Error "An error occurred while fetching the groups: $_"
    }
}

# Get and display the groups
$groups = Get-M365GroupsStatus
$groups | Format-Table -AutoSize

# Disconnect from Azure AD
Disconnect-AzureAD
