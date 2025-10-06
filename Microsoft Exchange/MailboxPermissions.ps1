<#
.SYNOPSIS
    This script exports all mailbox permissions from Exchange Online.
.DESCRIPTION
    The script retrieves all assigned permissions (Full Access, Send As, Send on Behalf) 
    for each mailbox and exports the data to a CSV file.
.AUTHOR
    Shaun Hardneck | www.thatlazyadmin.com
.NOTES
    Requires Exchange Online PowerShell module.
    Ensure the user running this script has the necessary permissions.
#>

# Banner
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "      Exchange Online - Export Mailbox Permissions" -ForegroundColor Yellow
Write-Host "      Script by: Shaun Hardneck | www.thatlazyadmin.com" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Ensure Exchange Online Module is Installed
if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Exchange Online module not found. Installing..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Force -AllowClobber
}

# Import Exchange Online Module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
try {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    Connect-ExchangeOnline -ErrorAction Stop
} catch {
    Write-Host "Error: Unable to connect to Exchange Online. Please check your credentials." -ForegroundColor Red
    $_ | Out-File -Append -FilePath "error_log.txt"
    exit
}

# Output File
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = ".\Mailbox_Permissions_$timestamp.csv"

# Array to store results
$results = @()

# Get all mailboxes
Write-Host "Fetching all mailboxes..." -ForegroundColor Green
$mailboxes = Get-Mailbox -ResultSize Unlimited

foreach ($mailbox in $mailboxes) {
    $mailboxName = $mailbox.PrimarySmtpAddress

    # Get Full Access Permissions
    $fullAccess = Get-MailboxPermission -Identity $mailboxName | Where-Object { $_.AccessRights -contains "FullAccess" -and $_.User -notlike "NT AUTHORITY\SELF" }
    foreach ($perm in $fullAccess) {
        $results += [PSCustomObject]@{
            Mailbox     = $mailboxName
            Permission  = "Full Access"
            AssignedTo  = $perm.User
            AssignedBy  = $perm.IsInherited -eq $false ? "Direct Assignment" : "Inherited"
        }
    }

    # Get Send As Permissions
    $sendAs = Get-RecipientPermission -Identity $mailboxName | Where-Object { $_.AccessRights -contains "SendAs" -and $_.Trustee -notlike "NT AUTHORITY\SELF" }
    foreach ($perm in $sendAs) {
        $results += [PSCustomObject]@{
            Mailbox     = $mailboxName
            Permission  = "Send As"
            AssignedTo  = $perm.Trustee
            AssignedBy  = "Direct Assignment"
        }
    }

    # Get Send on Behalf Permissions
    $sendOnBehalf = (Get-Mailbox -Identity $mailboxName).GrantSendOnBehalfTo
    foreach ($user in $sendOnBehalf) {
        $results += [PSCustomObject]@{
            Mailbox     = $mailboxName
            Permission  = "Send on Behalf"
            AssignedTo  = $user
            AssignedBy  = "Direct Assignment"
        }
    }
}

# Export to CSV
if ($results.Count -gt 0) {
    Write-Host "Exporting results to $csvFile" -ForegroundColor Green
    $results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
    Write-Host "Export completed successfully!" -ForegroundColor Cyan
} else {
    Write-Host "No mailbox permissions found!" -ForegroundColor Red
}

# Disconnect from Exchange Online
Write-Host "Disconnecting from Exchange Online..." -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Script execution completed." -ForegroundColor Green
