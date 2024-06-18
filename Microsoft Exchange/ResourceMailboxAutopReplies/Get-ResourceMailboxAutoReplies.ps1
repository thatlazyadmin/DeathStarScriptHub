<#
.SYNOPSIS
    Retrieves the automatic reply settings for resource mailboxes in Exchange Online.
.DESCRIPTION
    Retrieves and displays the automatic reply settings for all resource mailboxes within an Exchange Online environment,
    and outputs the information to a CSV file. The script was created by Shaun Hardneck and further details can be
    found on www.thatlazyadmin.com.
.NOTES
    File Name: Get-EXOResourceMailboxAutoReplies.ps1
    Author: Shaun Hardneck
    Blog: www.thatlazyadmin.com
#>

# Import the Exchange Online module
# Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline -ShowProgress $true

# Function to get automatic reply settings
function Get-AutoReplySettings {
    Write-Host "Retrieving resource mailboxes..." -ForegroundColor Cyan
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox" -or $_.RecipientTypeDetails -eq "EquipmentMailbox"}

    $autoReplyInfo = @()

    foreach ($mailbox in $mailboxes) {
        Write-Host "Processing mailbox: $($mailbox.DisplayName)" -ForegroundColor Yellow
        $settings = Get-MailboxAutoReplyConfiguration -Identity $mailbox.Identity

        $infoObject = New-Object PSObject -Property @{
            DisplayName = $mailbox.DisplayName
            AutoReplyState = $settings.AutoReplyState
            InternalMessage = $settings.InternalMessage
            ExternalMessage = $settings.ExternalMessage
        }

        $autoReplyInfo += $infoObject
    }

    return $autoReplyInfo
}

# Retrieve auto reply settings and export to CSV
Write-Host "Retrieving auto-reply settings..." -ForegroundColor Cyan
$autoReplySettings = Get-AutoReplySettings
$autoReplySettings | Export-Csv -Path "ResourceMailboxAutoReplies.csv" -NoTypeInformation

Write-Host "Script execution completed. The auto-reply settings have been exported to 'ResourceMailboxAutoReplies.csv'." -ForegroundColor Green

# Disconnect from Exchange Online
Write-Host "Disconnecting from Exchange Online..." -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Disconnected from Exchange Online." -ForegroundColor Green