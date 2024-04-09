<#
.SYNOPSIS
Exports Microsoft Teams users' details including allocated telephone numbers to a CSV file.

.DESCRIPTION
This script connects to Microsoft Teams using the Teams PowerShell Module, retrieves all users who are enabled for Teams,
and exports selected details including display name, user principal name, email address, and telephone number to a CSV file.
Note: The 'TelephoneNumber' field may not accurately reflect the Teams-specific telephone number without further integration with Microsoft Graph API.

.EXAMPLE
PS> .\ExportTeamsUsers.ps1

This command runs the script, exports the users' details to "TeamsUsersWithTelephoneNumbers.csv".

.NOTES
Version:        1.0
Author:         Shaun Hardneck
Blog:           www.thatlazyadmin.com
#>

# Ensure the MicrosoftTeams module is installed and imported
if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module -Name MicrosoftTeams -Force -AllowClobber
}
Import-Module MicrosoftTeams

try {
    # Prompt for credentials
    Write-Host "Enter your Office 365 admin credentials" -ForegroundColor Cyan

    # Connect to Microsoft Teams
    Connect-MicrosoftTeams

    # Retrieve Teams-enabled users with an assigned telephone number and select specified properties
    $teamsUsersDetails = Get-CsOnlineUser | Where-Object { $_.LineUri -ne $null } | Select-Object DisplayName, UserPrincipalName, SipProxyAddress, OnlineVoiceRoutingPolicy, LineUri, AccountEnabled, AccountType

    # Check if users are found
    if ($teamsUsersDetails.Count -eq 0) {
        Write-Host "No users with an assigned telephone number were found." -ForegroundColor Red
    }
    else {
        # Export to CSV
        $csvPath = "TeamsUserDetails.csv"
        $teamsUsersDetails | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Export completed successfully. File saved to: $csvPath" -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Ensure the session is disconnected properly
    Disconnect-MicrosoftTeams
}