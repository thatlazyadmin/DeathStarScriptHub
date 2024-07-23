<#
.SYNOPSIS
    This script ensures that only organizationally managed or approved public groups exist in Microsoft 365.
    It connects to Microsoft Graph, retrieves all groups, and checks their visibility status.
    If any groups have a 'Public' visibility status, they are displayed for review and exported to a CSV file with a date stamp.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Microsoft Graph using the provided scope "Group.Read.All".
    2. Retrieves the list of all groups and their visibility status.
    3. Filters the groups to identify those with 'Public' visibility status.
    4. Displays the list of public groups for review.
    5. Exports the list of public groups to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Check-ApprovedPublicGroups.ps1
    This example runs the script to check for public groups in Microsoft 365 and display them for review.
#>

# Import required modules
# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Check for public groups
try {
    $publicGroups = Get-MgGroup -All | Where-Object { $_.Visibility -eq "Public" } | Select-Object DisplayName, Visibility
    $totalCount = $publicGroups.Count

    if ($totalCount -gt 0) {
        Write-Host "Public groups found: $totalCount" -ForegroundColor Green
        $publicGroups | Format-Table DisplayName, Visibility

        # Export to CSV
        $currentDate = Get-Date -Format "yyyyMMdd"
        $fileName = "PublicGroups_$currentDate.csv"
        $publicGroups | Export-Csv -Path $fileName -NoTypeInformation
        Write-Host "Exported public groups to $fileName" -ForegroundColor Green
    } else {
        Write-Host "No public groups found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to retrieve group information. Please ensure you have the necessary permissions." -ForegroundColor Red
}