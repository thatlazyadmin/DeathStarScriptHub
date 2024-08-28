<#
.SYNOPSIS
    This script queries Active Directory for all inactive user accounts and exports the relevant information to a CSV file.

.DESCRIPTION
    The script identifies inactive user accounts in Active Directory by checking the 'LastLogonDate' attribute. 
    Accounts that have not logged on for more than 90 days are considered inactive.
    The script exports the following information about the inactive accounts: 
    - SamAccountName
    - DisplayName
    - EmailAddress
    - LastLogonDate
    - AccountEnabled
    - DistinguishedName

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Date: August 2024

#>

# Banner
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     Inactive AD Accounts Report Script   " -ForegroundColor Cyan
Write-Host "     Created by: Shaun Hardneck           " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Import Active Directory module
Import-Module ActiveDirectory

# Define the number of days of inactivity to consider an account inactive
$daysInactive = 90

# Calculate the date threshold for inactivity
$dateThreshold = (Get-Date).AddDays(-$daysInactive)

# Query Active Directory for inactive user accounts
$inactiveAccounts = Get-ADUser -Filter {LastLogonDate -lt $dateThreshold} -Properties SamAccountName, DisplayName, EmailAddress, LastLogonDate, Enabled, DistinguishedName | 
    Select-Object SamAccountName, DisplayName, EmailAddress, @{Name="LastLogonDate";Expression={[datetime]::FromFileTime($_.LastLogonDate)}}, Enabled, DistinguishedName

# Export the results to a CSV file
$outputFile = "InactiveADAccounts_$((Get-Date).ToString('yyyyMMdd_HHmmss')).csv"
$inactiveAccounts | Export-Csv -Path $outputFile -NoTypeInformation

# Display the output file location
Write-Host "Inactive accounts report has been exported to $outputFile" -ForegroundColor Green