# Banner
Write-Host "================================================="
Write-Host "       Entra ID Device Group Member Copier       "
Write-Host "        Script Name: Copy-EntraIDDeviceGroupMembers.ps1        "
Write-Host "            Created by: Shaun Hardneck            "
Write-Host "           www.thatlazyadmin.com                  "
Write-Host "================================================="

# Synopsis
<#
.SYNOPSIS
    This script copies members from one Entra ID (Azure AD) device group to another.
    
.DESCRIPTION
    The Copy-EntraIDDeviceGroupMembers.ps1 script prompts the user to input the names of a source and a destination 
    Entra ID (Azure AD) device group. It then retrieves all members from the source group and adds them to the 
    destination group. The script handles errors gracefully and informs the user of any issues encountered during the process.
    
.NOTES
    Created by: Shaun Hardneck
    Website: www.thatlazyadmin.com
    
.REQUIREMENTS
    - AzureAD PowerShell module
    - Appropriate permissions to read and modify group memberships in Entra ID (Azure AD)
    
.EXAMPLE
    PS> .\Copy-EntraIDDeviceGroupMembers.ps1
    This will prompt for the source and destination group names and perform the copy operation.
#>

# Import the AzureAD module
# Import-Module AzureAD

# Login to Azure AD
Write-Host "Logging in to Azure AD..."
Connect-AzureAD

# Function to get group by name
function Get-GroupByName {
    param (
        [string]$GroupName
    )
    $group = Get-AzureADGroup -All $true | Where-Object { $_.DisplayName -eq $GroupName }
    if (-not $group) {
        Write-Host "Group '$GroupName' not found." -ForegroundColor Red
        exit
    }
    return $group
}

# Prompt for the source and destination group names
$sourceGroupName = Read-Host "Enter the name of the source group"
$destinationGroupName = Read-Host "Enter the name of the destination group"

# Get the source and destination groups
$sourceGroup = Get-GroupByName -GroupName $sourceGroupName
$destinationGroup = Get-GroupByName -GroupName $destinationGroupName

# Get the members of the source group
Write-Host "Retrieving members from the source group..."
$sourceGroupMembers = Get-AzureADGroupMember -ObjectId $sourceGroup.ObjectId -All $true

# Add members to the destination group
foreach ($member in $sourceGroupMembers) {
    try {
        Write-Host "Adding member $($member.DisplayName) to the destination group..."
        Add-AzureADGroupMember -ObjectId $destinationGroup.ObjectId -RefObjectId $member.ObjectId
    } catch {
        Write-Host "Failed to add member $($member.DisplayName). Error: $_" -ForegroundColor Red
    }
}

Write-Host "Completed copying members from '$sourceGroupName' to '$destinationGroupName'."