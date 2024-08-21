<#
.SYNOPSIS
    Enables mailbox auditing for all Resource Mailboxes, Public Folder Mailboxes, and DiscoverySearch Mailboxes in the organization.

.DESCRIPTION
    This script, created by Shaun Hardneck, automatically searches for all Resource Mailboxes, Public Folder Mailboxes, 
    and DiscoverySearch Mailboxes in the organization. It checks if auditing is enabled for each mailbox and applies 
    the setting to enable auditing if it is not already configured. It also includes an option to connect to the GCC environment.

.NOTES
    Author: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Created on: [Date]
    Version: 1.0
    Contact: Shaun@thatlazyadmin.com
#>

# Import Exchange Online module if not already imported
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement

# Prompt for environment selection
$environment = Read-Host "Enter the environment (Commercial, GCC)"

switch ($environment.ToLower()) {
    "gcc" {
        Connect-ExchangeOnline -UserPrincipalName user@domain.com -Environment AzureUSGovernment -ShowProgress $true
    }
    "commercial" {
        Connect-ExchangeOnline -ShowProgress $true
    }
    default {
        Write-Host "Invalid environment selection. Please choose either 'Commercial' or 'GCC'." -ForegroundColor Red
        exit
    }
}

# Retrieve all relevant mailboxes
$allMailboxes = Get-Mailbox -RecipientTypeDetails ResourceMailbox, PublicFolderMailbox, DiscoveryMailbox

foreach ($mailbox in $allMailboxes) {
    $auditEnabled = (Get-Mailbox -Identity $mailbox.Identity).AuditEnabled

    if (-not $auditEnabled) {
        Write-Host "Enabling auditing for mailbox: $($mailbox.DisplayName)" -ForegroundColor Yellow
        Set-Mailbox -Identity $mailbox.Identity -AuditEnabled $true
    } else {
        Write-Host "Auditing already enabled for mailbox: $($mailbox.DisplayName)" -ForegroundColor Green
    }
}

# Disconnect Exchange Online session
Disconnect-ExchangeOnline -Confirm:$false
