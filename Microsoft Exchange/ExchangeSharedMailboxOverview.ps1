<#
.SYNOPSIS
    Retrieves and exports details of shared Exchange Online mailboxes with sizes between 50GB and 99GB.
    
.DESCRIPTION
    This PowerShell script connects to Exchange Online to list shared mailboxes within specific size ranges and exports the results to CSV.
    Includes error handling for null values and conversion issues.

.AUTHOR
    Shaun Hardneck - ThatLazyAdmin
    Blog: www.thatlazyadmin.com

.EXAMPLE
    PS> .\ExchangeSharedMailboxOverview.ps1

.NOTES
    Version: 1.2
    Created: Shaun Hardneck
#>

# Function to convert size to GB
function ConvertTo-GB ($size) {
    $bytes = [regex]::Match($size, '(\d+)').Value
    $factor = switch -Regex ($size) {
        "MB" { 1MB }
        "GB" { 1GB }
        "TB" { 1TB }
        default { 1KB }
    }
    [int]($bytes / $factor)
}

# Connect to Exchange Online
Connect-ExchangeOnline

# Retrieve all shared mailboxes and filter by size
Write-Host "Retrieving shared mailboxes with size between 50GB and 99GB..." -ForegroundColor DarkCyan
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Where-Object {
    $_.ProhibitSendQuota -ne $null -and
    (ConvertTo-GB $_.ProhibitSendQuota) -gt 50 -and
    (ConvertTo-GB $_.ProhibitSendQuota) -lt 99
}

if ($sharedMailboxes -ne $null) {
    $sharedMailboxes | Format-Table DisplayName, PrimarySmtpAddress, ProhibitSendQuota

    # Export filtered shared mailboxes to CSV
    $exportPath = ".\FilteredSharedMailboxes.csv"
    $sharedMailboxes | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Filtered shared mailboxes exported to CSV at $exportPath." -ForegroundColor DarkMagenta
} else {
    Write-Host "No shared mailboxes found within the specified size range."
}

# Option to export all mailboxes to CSV
$allExportPath = ".\AllMailboxes.csv"
$confirmation = Read-Host "Do you want to export all mailboxes to CSV? (Y/N)"
if ($confirmation -eq 'Y') {
    $allMailboxes = Get-Mailbox -ResultSize Unlimited
    if ($allMailboxes -ne $null) {
        $allMailboxes | Export-Csv -Path $allExportPath -NoTypeInformation
        Write-Host "All mailboxes exported to CSV at $allExportPath." -ForegroundColor DarkGreen
    } else {
        Write-Host "No mailboxes found to export." -ForegroundColor DarkRed
    }
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false