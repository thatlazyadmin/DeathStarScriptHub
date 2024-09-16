# Script Name: Export-ADUserDetailsWithTimestamp.ps1
# Synopsis: This script exports Active Directory user details into a CSV file with a date and timestamp in the file name.
# Created by: Shaun Hardneck
# Blog: www.thatlazyadmin.com

# Suppress unnecessary warnings
$ErrorActionPreference = 'Stop'

# Get the current date and time for the file name (Format: yyyy-MM-dd_HH-mm-ss)
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Define the export path with a date and timestamp
$exportPath = "C:\temp\ADUserExport_$timestamp.csv"
$errorLogPath = "C:\temp\ADUsersExportErrors.txt"

# Add a banner
Write-Host "------------------------------------" -ForegroundColor Cyan
Write-Host " Exporting AD User Details" -ForegroundColor Cyan
Write-Host " Created by: Shaun Hardneck" -ForegroundColor Cyan
Write-Host " www.thatlazyadmin.com" -ForegroundColor Cyan
Write-Host "------------------------------------" -ForegroundColor Cyan

# Try-Catch block for error handling
try {
    # Fetch AD user details and export to CSV with timestamp
    Get-ADUser -filter * -Properties * | 
    Select-Object UserPrincipalName, 
                  SamAccountName, 
                  EmailAddress, 
                  employeeType, 
                  Manager, 
                  Name, 
                  Office, 
                  State, 
                  Title, 
                  Enabled, 
                  GivenName, 
                  Surname, 
                  adminCount, 
                  BadLogonCount, 
                  badPasswordTime, 
                  badPwdCount, 
                  CanonicalName, 
                  CN, 
                  DistinguishedName, 
                  extensionAttribute1, 
                  PasswordExpired, 
                  PasswordLastSet, 
                  whenChanged, 
                  whenCreated | 
    Export-Csv -Path $exportPath -NoTypeInformation -Force

    Write-Host "Export successful! Data saved to $exportPath" -ForegroundColor Green
} catch {
    # Log any errors that occur
    $_ | Out-File -FilePath $errorLogPath -Append
    Write-Host "An error occurred. Check $errorLogPath for details." -ForegroundColor Red
}

# End of script message
Write-Host "------------------------------------" -ForegroundColor Cyan
Write-Host " Script execution completed." -ForegroundColor Cyan
Write-Host "------------------------------------" -ForegroundColor Cyan