<#
.SYNOPSIS
    This script audits shared mailboxes in Microsoft 365 to ensure their sign-in is blocked.
    It connects to Exchange Online and Microsoft Graph, retrieves shared mailboxes, and checks if their AccountEnabled property is set to False.
    The results are exported to a CSV file with the current date stamp.

    Created by: Shaun Hardneck
    Contact: Shaun@Thatazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Exchange Online using Connect-ExchangeOnline.
    2. Connects to Microsoft Graph using Connect-MgGraph with the required scope "Policy.Read.All".
    3. Retrieves the list of shared mailboxes.
    4. Checks the AccountEnabled property for each shared mailbox to ensure sign-in is blocked.
    5. Exports the audit results to a CSV file with the current date stamp.

.PARAMETER None

.EXAMPLE
    .\Audit-SharedMailboxes.ps1
    This example runs the script to audit shared mailboxes and export the results to a CSV file.
#>

# Import required modules
#Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Exchange Online
try {
    Connect-ExchangeOnline -ShowProgress $true
    Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Exchange Online. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "Policy.Read.All"
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Audit shared mailboxes
try {
    $sharedMailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox
    $auditResults = @()

    foreach ($mailbox in $sharedMailboxes) {
        $user = Get-MgUser -UserId $mailbox.ExternalDirectoryObjectId -Property DisplayName, UserPrincipalName, AccountEnabled
        $auditResults += [PSCustomObject]@{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            AccountEnabled    = $user.AccountEnabled
        }
    }

    $totalCount = $auditResults.Count

    if ($totalCount -gt 0) {
        Write-Host "Audit completed. Total shared mailboxes found: $totalCount" -ForegroundColor Green
        $auditResults | Format-Table DisplayName, UserPrincipalName, AccountEnabled

        # Export to CSV
        $currentDate = Get-Date -Format "yyyyMMdd"
        $fileName = "SharedMailboxesAudit_$currentDate.csv"
        $auditResults | Export-Csv -Path $fileName -NoTypeInformation
        Write-Host "Exported audit results to $fileName" -ForegroundColor Green
    } else {
        Write-Host "No shared mailboxes found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to retrieve shared mailbox information. Please ensure you have the necessary permissions." -ForegroundColor Red
}