<#
.SYNOPSIS
M365AdminRoleLicenseChecker.ps1 - Audits Microsoft 365 Admin role assignments using Microsoft Graph.

.DESCRIPTION
This script aids Microsoft 365 administrators in auditing admin role assignments across Microsoft 365 environments. It leverages Microsoft Graph to enumerate admin roles, identify assigned users, and outputs a detailed report.

.KEY FEATURES
- Enumerates Microsoft 365 Admin roles and identifies assigned users.
- Exports findings to CSV for administrative use.

.AUTHOR
Shaun Hardneck - Security Architect and Consultant
Blog: wwww.thatlazyadmin.com
GitHub Repo: https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main
#>

# Ensure the Microsoft Graph PowerShell SDK is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
#Import-Module Microsoft.Graph

Write-Host "Microsoft 365 Admin Role Checker script is starting..." -ForegroundColor Cyan

# Connect to Microsoft Graph and suppress welcome message
Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome

# Get all Microsoft 365 admin roles
$adminRoles = Get-MgDirectoryRole -All

$results = @()

foreach ($role in $adminRoles) {
    # Retrieve role members
    try {
        $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All
    } catch {
        Write-Host "Could not retrieve members for role $($role.DisplayName): $_" -ForegroundColor Red
        continue
    }

    if ($roleMembers.Count -gt 0) {
        foreach ($member in $roleMembers) {
            $user = Get-MgUser -UserId $member.Id
            $results += [PSCustomObject]@{
                'Username'     = $user.UserPrincipalName
                'DisplayName'  = $user.DisplayName
                'Role'         = $role.DisplayName
            }
        }
    } else {
        $results += [PSCustomObject]@{
            'Username'     = "No assigned user"
            'DisplayName'  = "N/A"
            'Role'         = $role.DisplayName
        }
    }
}

# Display results on screen
$results | Format-Table -AutoSize

# Export results to CSV
$results | Export-Csv -Path 'Microsoft365AdminRolesAndUsers.csv' -NoTypeInformation

Write-Host "Microsoft 365 Admin Role Checker script has completed." -ForegroundColor Green

# Disconnect from Microsoft Graph
Disconnect-MgGraph
