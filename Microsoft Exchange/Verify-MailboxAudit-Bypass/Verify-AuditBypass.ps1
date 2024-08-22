<#
.SYNOPSIS
    This script verifies if audit bypass is enabled on any mailbox in Microsoft 365 and exports the results to a CSV file if any are found.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Checks if audit bypass is enabled on any mailbox.
    3. Exports the results to a CSV file if any mailboxes with audit bypass enabled are found.

.PARAMETER None

.EXAMPLE
    .\Verify-AuditBypass.ps1
    This example runs the script to verify if audit bypass is enabled on any mailbox and export the results to a CSV file if any are found.

.NOTES
    This script is necessary to ensure that audit bypass is not enabled on any mailbox, enhancing the security and compliance posture of the organization.
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

# Function to verify audit bypass settings
function Verify-AuditBypass {
    try {
        $mailboxes = Get-MailboxAuditBypassAssociation -ResultSize Unlimited
        $bypassEnabled = $mailboxes | Where-Object { $_.AuditBypassEnabled -eq $true }
        
        if ($bypassEnabled.Count -gt 0) {
            Write-Host "Mailboxes with Audit Bypass enabled found." -ForegroundColor Red
            $bypassEnabled | Format-Table Name, AuditBypassEnabled

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "AuditBypassEnabled_$currentDate.csv"
            $bypassEnabled | Select-Object Name, AuditBypassEnabled | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No mailboxes with Audit Bypass enabled." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to retrieve audit bypass settings. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Verify-AuditBypass