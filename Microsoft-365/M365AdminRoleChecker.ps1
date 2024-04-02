<#
.SYNOPSIS
M365AdminRoleLicenseChecker.ps1 - Audits Microsoft 365 Admin role assignments and license status using Microsoft Graph.

.DESCRIPTION
Authored by Shaun Hardneck (thatLazyAdmin), this script aids Microsoft 365 administrators and security architects in auditing admin role assignments and user licensing status across Microsoft 365 environments. It leverages Microsoft Graph to enumerate admin roles, identify assigned users, and check their licensing status, outputting a detailed report.

.KEY FEATURES
- Utilizes Microsoft Graph for comprehensive data access.
- Enumerates Microsoft 365 Admin roles and assigned users.
- Checks and reports on user licensing status.
- Exports findings to CSV for administrative use.

.AUTHOR
Shaun Hardneck - thatLazyAdmin
Blog: www.thatlazyadmin.com

#>

# Ensure the Microsoft Graph PowerShell SDK is installed
# Install-Module Microsoft.Graph -Scope CurrentUser

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All", "User.Read.All"

# Get all directory roles
$adminRoles = Get-MgDirectoryRole | Where-Object { $_.DisplayName -like "*admin*" }

# Initialize results array
$results = @()

foreach ($role in $adminRoles) {
    # Get members of each role
    $roleMembers = Get-MgDirectoryRoleMember -RoleId $role.Id | Get-MgUser

    foreach ($member in $roleMembers) {
        # Determine if the user is licensed
        $licenses = Get-MgUserLicenseDetail -UserId $member.Id
        $isLicensed = $null -ne $licenses -and $licenses.Count -gt 0

        # Create and add result to array
        $result = [PSCustomObject]@{
            Username     = $member.UserPrincipalName
            DisplayName  = $member.DisplayName
            RoleAssigned = $role.DisplayName
            IsLicensed   = $isLicensed
        }

        $results += $result
    }
}

# Output and export results
$results | Format-Table Username, DisplayName, RoleAssigned, IsLicensed
$results | Export-Csv -Path "Microsoft365AdminRolesAndUsers.csv" -NoTypeInformation

Write-Host "Export completed. Find the results in 'Microsoft365AdminRolesAndUsers.csv'."
Disconnect-MgGraph