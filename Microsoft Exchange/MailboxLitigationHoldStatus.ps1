<#
.SYNOPSIS
This script connects to Exchange Online and retrieves all mailboxes, checking each for litigation hold status.
It then exports the findings to a CSV file, indicating whether litigation hold is enabled for each mailbox.

.DESCRIPTION
The script makes use of the Get-Mailbox and Get-MailboxLitigationHold cmdlets to fetch mailbox details and their litigation hold status, respectively.
The results are then compiled into a custom PowerShell object and exported to a CSV file named "MailboxLitigationHoldStatus.csv".
This tool is particularly useful for administrators needing to audit the litigation hold status of mailboxes in their organization.

.NOTES
Version:        1.0
Author:         Shaun Hardneck (ThatLazyAdmin)
Blog  :         www.thatlazyadmin.com
Dependencies:   PowerShell V2 and above, Exchange Online Management Shell
Usage:          PowerShell -ExecutionPolicy RemoteSigned -File ./this_script_name.ps1

.EXAMPLE
.\ExportLitigationHoldStatus.ps1
#>

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan

Connect-ExchangeOnline

# Fetch all mailboxes and check for litigation hold status
Write-Host "Retrieving mailboxes and litigation hold status..." -ForegroundColor DarkYellow
$mailboxes = Get-Mailbox -ResultSize Unlimited
$mailboxStatuses = @()

foreach ($mailbox in $mailboxes) {
    $litigationHoldEnabled = $null -ne $mailbox.LitigationHoldEnabled
    $mailboxStatus = New-Object PSObject -Property @{
        UserPrincipalName     = $mailbox.UserPrincipalName
        DisplayName           = $mailbox.DisplayName
        LitigationHoldEnabled = $litigationHoldEnabled
    }
    $mailboxStatuses += $mailboxStatus
}

# Export to CSV
$csvPath = "./MailboxLitigationHoldStatus.csv"
$mailboxStatuses | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Export completed. File saved at: $csvPath" -ForegroundColor Green

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
