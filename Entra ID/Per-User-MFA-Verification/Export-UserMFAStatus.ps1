<#
.SYNOPSIS
    This script retrieves the per-user MFA status for each user in Microsoft 365 and exports the results to a CSV file with a current date stamp.

    Created by: Shaun Hardneck
    Contact: Shaun@hardneck.co.za
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Microsoft Graph using the provided credentials.
    2. Retrieves the MFA status for each user.
    3. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Export-UserMFAStatus.ps1
    This example runs the script to retrieve per-user MFA status and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that MFA status for all users is regularly reviewed, enhancing the security posture of the organization.
#>

# Ensure the Microsoft Graph module is installed and updated
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Force -AllowClobber
} else {
    Write-Host "Updating Microsoft.Graph module..." -ForegroundColor Yellow
    Update-Module -Name Microsoft.Graph
}

# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All" -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to get MFA status for each user
function Get-UserMFAStatus {
    try {
        $users = Get-MgUser -All -Property "UserPrincipalName, DisplayName"
        $results = @()

        foreach ($user in $users) {
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id
            $mfaEnabled = $authMethods | Where-Object { $_.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.strongAuthenticationMethod" }
            $mfaStatus = if ($mfaEnabled) { "Enabled" } else { "Disabled" }

            $results += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                DisplayName       = $user.DisplayName
                MFAStatus         = $mfaStatus
            }
        }

        $totalCount = $results.Count

        if ($totalCount -gt 0) {
            Write-Host "MFA status retrieved for $totalCount users." -ForegroundColor Green
            $results | Format-Table UserPrincipalName, DisplayName, MFAStatus

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "UserMFAStatus_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported MFA status to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No users found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve MFA status. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Get-UserMFAStatus