<#
.SYNOPSIS
    This script retrieves all guest accounts in an Azure AD tenant and adds them to a specified security group.
    
.DESCRIPTION
    The script connects to Microsoft Graph, retrieves all guest accounts, and prompts the user for a security group name.
    It then adds each guest account to the specified security group and provides feedback for each addition.

    Script Name: Add-GuestAccountsToSecurityGroup
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com

.NOTES
    Author: Shaun Hardneck
    Date: 2024-07-31
    Version: 1.2

    Prerequisites:
    - Microsoft.Graph module
    - Necessary permissions to manage users and groups in Azure AD

    This script uses the Microsoft Graph API to perform operations.

.EXAMPLE
    .\Add-GuestAccountsToSecurityGroup.ps1

    This example connects to Microsoft Graph, retrieves all guest accounts, and adds them to the specified security group.
#>

# Uncomment the following section if the Microsoft.Graph module is not installed

# Install Microsoft.Graph module if not already installed
#if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
#    Install-Module -Name Microsoft.Graph -Force
#}

# Import the module
# Import-Module Microsoft.Graph

# Function to get guest accounts and add them to a security group
function Add-GuestsToSecurityGroup {
    # Disconnect any existing session to ensure a fresh login
    Disconnect-MgGraph
    
    # Connect to Microsoft Graph and force a new login prompt
    Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All" -NoWelcome

    # Get all guest accounts
    $guestAccounts = Get-MgUser -Filter "userType eq 'Guest'" -All

    if ($guestAccounts.Count -eq 0) {
        Write-Host "No guest accounts found." -ForegroundColor Yellow
        return
    }

    # Display guest accounts
    Write-Host "Guest accounts found:" -ForegroundColor Cyan
    $guestAccounts | ForEach-Object { Write-Host $_.UserPrincipalName -ForegroundColor Green }

    # Prompt for the security group name
    $groupName = Read-Host -Prompt "Enter the name of the security group"

    # Get the security group
    $group = Get-MgGroup -Filter "displayName eq '$groupName'"

    if ($group -eq $null) {
        Write-Host "Security group '$groupName' not found." -ForegroundColor Red
        return
    }

    # Add each guest account to the security group
    foreach ($guest in $guestAccounts) {
        # Add user to group
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $guest.Id
        Write-Host "Added $($guest.UserPrincipalName) to $groupName" -ForegroundColor Green
    }

    Write-Host "All guest accounts have been added to the security group '$groupName'." -ForegroundColor Cyan
}

# Call the function
Add-GuestsToSecurityGroup
