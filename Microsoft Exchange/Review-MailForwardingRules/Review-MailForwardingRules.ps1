<#
.SYNOPSIS
    This script reviews mail forwarding rules, user delegates, and SMTP forwarding policies in Microsoft 365 and exports the results to CSV files.

    Created by: Shaun Hardneck
    Contact: shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves all user mailboxes.
    3. Checks inbox rules for forwarding, redirecting, and deleting messages.
    4. Retrieves mailbox delegate permissions.
    5. Retrieves SMTP forwarding settings.
    6. Exports the results to separate CSV files for further review and auditing.

.PARAMETER None

.EXAMPLE
    .\Review-MailForwardingRules.ps1
    This example runs the script to review mail forwarding rules, user delegates, and SMTP forwarding policies and export the results to CSV files.

.NOTES
    This script is necessary to ensure that mail forwarding rules, user delegates, and SMTP forwarding policies are properly reviewed and audited to enhance the security and compliance posture of the organization.
#>

# Import required modules
# Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

# Connect to Exchange Online
try {
    Connect-ExchangeOnline -ShowProgress $true
    Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Exchange Online. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Retrieve all user mailboxes
$allUsers = Get-User -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | Where-Object { $_.AccountDisabled -eq $false }

# Initialize arrays for inbox rules, delegates, and SMTP forwarding
$UserInboxRules = @()
$UserDelegates = @()

# Check inbox rules and delegates for each user
foreach ($User in $allUsers) {
    Write-Host "Checking inbox rules and delegates for user: $($User.UserPrincipalName)"
    
    $UserInboxRules += Get-InboxRule -Mailbox $User.UserPrincipalName | Select-Object Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage | Where-Object { ($_.ForwardTo -ne $null) -or ($_.ForwardAsAttachmentTo -ne $null) -or ($_.RedirectTo -ne $null) }

    $UserDelegates += Get-MailboxPermission -Identity $User.UserPrincipalName | Where-Object { ($_.IsInherited -ne $true) -and ($_.User -notlike "*SELF*") }
}

# Retrieve SMTP forwarding settings
$SMTPForwarding = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, ForwardingAddress, ForwardingSMTPAddress, DeliverToMailboxAndForward | Where-Object { $_.ForwardingSMTPAddress -ne $null }

# Export results to CSV files
$currentDate = Get-Date -Format "yyyyMMdd"
$inboxRulesFileName = "MailForwardingRulesToExternalDomains_$currentDate.csv"
$delegatesFileName = "MailboxDelegatePermissions_$currentDate.csv"
$smtpForwardingFileName = "MailboxSMTPForwarding_$currentDate.csv"

$UserInboxRules | Export-Csv -Path $inboxRulesFileName -NoTypeInformation
$UserDelegates | Export-Csv -Path $delegatesFileName -NoTypeInformation
$SMTPForwarding | Export-Csv -Path $smtpForwardingFileName -NoTypeInformation

Write-Host "Exported inbox rules to $inboxRulesFileName" -ForegroundColor Green
Write-Host "Exported mailbox delegate permissions to $delegatesFileName" -ForegroundColor Green
Write-Host "Exported SMTP forwarding settings to $smtpForwardingFileName" -ForegroundColor Green