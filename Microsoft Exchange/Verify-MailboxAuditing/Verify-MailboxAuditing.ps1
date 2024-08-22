<#
.SYNOPSIS
    This script verifies mailbox auditing is enabled and configured for all mailboxes in Microsoft 365 and exports the results to a CSV file with a current date stamp.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves mailbox auditing settings for all mailboxes.
    3. Verifies that all required audit actions are configured for Admin, Delegate, and Owner roles.
    4. Exports the results to a CSV file with a current date stamp.
    5. The output includes UserPrincipalName, AuditEnabled, AuditAdmin, AuditDelegate, and AuditOwner properties.

.PARAMETER None

.EXAMPLE
    .\Verify-MailboxAuditing.ps1
    This example runs the script to verify mailbox auditing settings and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that mailbox auditing is properly enabled and configured for all mailboxes, enhancing the security and compliance posture of the organization.
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

$AdminActions = @(
    "ApplyRecord", "Copy", "Create", "FolderBind", "HardDelete", "Move", 
    "MoveToDeletedItems", "SendAs", "SendOnBehalf", "SoftDelete", "Update", 
    "UpdateCalendarDelegation", "UpdateFolderPermissions", "UpdateInboxRules"
)

$DelegateActions = @(
    "ApplyRecord", "Create", "FolderBind", "HardDelete", "Move", 
    "MoveToDeletedItems", "SendAs", "SendOnBehalf", "SoftDelete", "Update", 
    "UpdateFolderPermissions", "UpdateInboxRules"
)

$OwnerActions = @(
    "ApplyRecord", "Create", "HardDelete", "MailboxLogin", "Move", 
    "MoveToDeletedItems", "SoftDelete", "Update", "UpdateCalendarDelegation", 
    "UpdateFolderPermissions", "UpdateInboxRules"
)

function VerifyActions {
    param (
        [string]$type,
        [array]$actions,
        [array]$auditProperty,
        [string]$mailboxName
    )
    $missingActions = @()
    $actionCount = 0
    foreach ($action in $actions) {
        if ($auditProperty -notcontains $action) {
            $missingActions += "Failure: Audit action '$action' missing from $type"
            $actionCount++
        }
    }
    if ($actionCount -eq 0) {
        Write-Host "[$mailboxName]: $type actions are verified." -ForegroundColor Green
    } else {
        Write-Host "[$mailboxName]: $type actions are not all verified." -ForegroundColor Red
        foreach ($missingAction in $missingActions) {
            Write-Host " $missingAction" -ForegroundColor Red
        }
    }
}

# Function to verify mailbox auditing settings
function Verify-MailboxAuditing {
    $mailboxes = Get-EXOMailbox -PropertySets Audit,Minimum -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -eq "UserMailbox" }
    $results = @()

    foreach ($mailbox in $mailboxes) {
        Write-Host "--- Now assessing [$($mailbox.UserPrincipalName)] ---"
        if ($mailbox.AuditEnabled) {
            Write-Host "[$($mailbox.UserPrincipalName)]: AuditEnabled is true" -ForegroundColor Green
        } else {
            Write-Host "[$($mailbox.UserPrincipalName)]: AuditEnabled is false" -ForegroundColor Red
        }

        VerifyActions -type "AuditAdmin" -actions $AdminActions -auditProperty $mailbox.AuditAdmin -mailboxName $mailbox.UserPrincipalName
        VerifyActions -type "AuditDelegate" -actions $DelegateActions -auditProperty $mailbox.AuditDelegate -mailboxName $mailbox.UserPrincipalName
        VerifyActions -type "AuditOwner" -actions $OwnerActions -auditProperty $mailbox.AuditOwner -mailboxName $mailbox.UserPrincipalName

        $results += [PSCustomObject]@{
            UserPrincipalName = $mailbox.UserPrincipalName
            AuditEnabled      = $mailbox.AuditEnabled
            AuditAdmin        = ($mailbox.AuditAdmin -join ', ')
            AuditDelegate     = ($mailbox.AuditDelegate -join ', ')
            AuditOwner        = ($mailbox.AuditOwner -join ', ')
        }
    }

    # Export to CSV
    $currentDate = Get-Date -Format "yyyyMMdd"
    $fileName = "AuditSettings_$currentDate.csv"
    $results | Export-Csv -Path $fileName -NoTypeInformation
    Write-Host "Exported mailbox auditing settings to $fileName" -ForegroundColor Green
}

# Execute the function
Verify-MailboxAuditing