<#
.SYNOPSIS
    This script verifies if the Microsoft 365 audit log search is enabled using Microsoft Graph PowerShell.
    It connects to Microsoft Graph, retrieves the list of users, and checks for non-member (guest) users.
    If nothing is returned, it means there are no guest users in the tenant.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Microsoft Graph using the provided scope "User.Read.All".
    2. Retrieves the list of all users along with their UserType and UserPrincipalName properties.
    3. Filters the users to identify non-member (guest) users.
    4. Displays the list of non-member users and the total count of non-member users found.
    5. Exports the list of non-member users to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Verify-GuestUsers.ps1
    This example runs the script to verify if the Microsoft 365 audit log search is enabled and checks for guest users.
#>

# Import required modules
# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Verify Microsoft 365 audit log search and check for guest users
try {
    $nonMemberUsers = Get-MgUser -All -Property UserType, UserPrincipalName | Where-Object { $_.UserType -ne "Member" }
    $totalCount = $nonMemberUsers.Count

    if ($totalCount -gt 0) {
        Write-Host "Non-member users found: $totalCount" -ForegroundColor Green
        $nonMemberUsers | Format-Table UserPrincipalName, UserType

        # Export to CSV
        $currentDate = Get-Date -Format "yyyyMMdd"
        $fileName = "NonMemberUsers_$currentDate.csv"
        $nonMemberUsers | Export-Csv -Path $fileName -NoTypeInformation
        Write-Host "Exported non-member users to $fileName" -ForegroundColor Green
    } else {
        Write-Host "No non-member (guest) users found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to retrieve user information. Please ensure you have the necessary permissions." -ForegroundColor Red
}