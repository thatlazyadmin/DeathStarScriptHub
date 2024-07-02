<#
.SYNOPSIS
    DomainAdminsPrivilegedAudit-Export.ps1 - Audits and exports details of privileged users within specified domain groups, including their last logon times.
.DESCRIPTION
    This script queries administrative groups like Domain Admins and Administrators within a specified domain to gather and export a consolidated list of users with elevated privileges. It includes each user's last logon time, domain, and group memberships.
    Ideal for security audits and monitoring privileged access across multiple domains in Active Directory.
.PARAMETER Domain
    The DNS name of the domain to query.
.NOTES
    Created By: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    This script requires the Active Directory module and appropriate permissions to read from Active Directory.
.EXAMPLE
    PowerShell.exe -File DomainAdminsPrivilegedAudit-Export.ps1 -Domain "child.domain.com"
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
        # Fetching members using the working approach
        Write-Host "Querying group: $group"
        $members = Get-ADGroup -Identity $group | Get-ADGroupMember -Recursive
        
        foreach ($member in $members) {
            $typeIndicator = if ($member.objectClass -eq 'group') {"(Group)"} else {""}
            Write-Host "Found member: $($member.Name) $typeIndicator"
            # Avoid duplicates and gather additional user info
            if (-not ($privilegedUsers | Where-Object {$_.SamAccountName -eq $member.SamAccountName})) {
                $userInfo = Get-ADUser -Identity $member.SamAccountName -Properties LastLogonDate, DistinguishedName, MemberOf
                $privilegedUsers += $userInfo
            }
        }
    } catch {
        Write-Host "Could not retrieve members from group: $group. Error: $_"
    }
}

# Define the date stamp for the filename
$dateStamp = (Get-Date -Format "yyyyMMdd")

# Export the results to a CSV file with a date stamp
$fileName = "PrivilegedUsers-$dateStamp.csv"
$privilegedUsers | Select-Object Name, SamAccountName, DistinguishedName, LastLogonDate, @{Name="Domain"; Expression={$_.DistinguishedName.split(',')[2].Split('=')[1]}}, @{Name="MemberOf";Expression={$_.MemberOf -join ';'}} | Export-Csv -Path $fileName -NoTypeInformation

# Display a message when the export is complete
Write-Host "Export complete. Check the file $fileName in the current directory." -ForegroundColor Green
