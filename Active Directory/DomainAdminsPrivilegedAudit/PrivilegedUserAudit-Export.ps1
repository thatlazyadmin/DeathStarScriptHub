<#
.SYNOPSIS
    PrivilegedGroupAudit-Export.ps1 - Audits and exports details of privileged users within specified domain groups, including their last logon times and nested group memberships.
.DESCRIPTION
    This script queries specified administrative groups within a domain to gather and export a consolidated list of users with elevated privileges. It includes each user's last logon time, domain, and group memberships.
    Ideal for security audits and monitoring privileged access across multiple domains in Active Directory.
.PARAMETER Domain
    The DNS name of the domain to query.
.NOTES
    Created By: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    This script requires the Active Directory module and appropriate permissions to read from Active Directory.
.EXAMPLE
    PowerShell.exe -File PrivilegedGroupAudit-Export.ps1 -Domain "child.domain.com"
    Runs the script to generate a CSV report on privileged users in the specified domain.
#>

param (
    [string]$Domain
)

# Import Active Directory Module
Import-Module ActiveDirectory

# Define the privileged groups to check
$privilegedGroups = @("Domain Admins", "Administrators")  # Adjusted to reflect available groups

# Collect unique privileged users from the defined groups
$privilegedUsers = @()
foreach ($group in $privilegedGroups) {
    try {
        # Fetching members including nested group members
        Write-Host "Querying group: $group in domain: $Domain"
        $members = Get-ADGroup -Identity $group -Server $Domain | Get-ADGroupMember -Recursive -Server $Domain
        
        foreach ($member in $members) {
            $typeIndicator = if ($member.objectClass -eq 'group') {"(Group)"} else {""}
            Write-Host "Found member: $($member.Name) $typeIndicator"
            # Avoid duplicates and gather additional user info
            if (-not ($privilegedUsers | Where-Object {$_.SamAccountName -eq $member.SamAccountName})) {
                $userInfo = Get-ADUser -Identity $member.SamAccountName -Server $Domain -Properties DisplayName, UserPrincipalName, LastLogonDate, DistinguishedName, MemberOf
                $privilegedUsers += $userInfo
            }
        }
    } catch {
        Write-Host "Could not retrieve members from group: $group in domain: $Domain. Error: $_"
    }
}

# Define the date stamp for the filename
$dateStamp = (Get-Date -Format "yyyyMMdd")

# Define path for export with date and domain included
$exportPath = "PrivilegedUsers-${Domain}-$dateStamp.csv"

# Export the results to a CSV file
$privilegedUsers | Select-Object DisplayName, UserPrincipalName, LastLogonDate, @{Name="Domain"; Expression={$_.DistinguishedName.split(',')[2].Split('=')[1]}}, @{Name="MemberOf";Expression={$_.MemberOf -join ';'}} | Export-Csv -Path $exportPath -NoTypeInformation

# Display a message when the export is complete
Write-Host "Export complete. Check the file $exportPath in the current directory." -ForegroundColor Green