<#
.SYNOPSIS
SharedInsight365 - M365 File Sharing Audit Tool
Author: Shaun Hardneck | www.thatlazyadmin.com
Last Updated: 2025-07-18

.DESCRIPTION
This script audits file sharing events in Microsoft 365 across SharePoint and OneDrive and exports the findings.
It highlights who shared what, with whom, from where, and how.
#>

Clear-Host

# === Banner ===
Write-Host "=== SharedInsight365 | M365 File Sharing Audit Tool ===" -ForegroundColor Cyan

# === Module Check ===
$modules = @("Microsoft.Graph.Authentication", "ExchangeOnlineManagement")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "[INFO] Installing $module..." -ForegroundColor Yellow
        Install-Module $module -Force -Scope CurrentUser
    } else {
        Write-Host "[INFO] $module available" -ForegroundColor Green
    }
}

# === Connections ===
Write-Host "[INFO] Connecting to Microsoft Graph..." -ForegroundColor Green
Connect-MgGraph -Scopes "AuditLog.Read.All" | Out-Null

Write-Host "[INFO] Connecting to Exchange Online..." -ForegroundColor Green
Connect-ExchangeOnline -ShowBanner:$false | Out-Null

# === Date Range Selection ===
Write-Host ""
Write-Host "Select audit log search range:" -ForegroundColor Yellow
Write-Host "1. Last 30 days"
Write-Host "2. Last 90 days"
Write-Host "3. All (up to 180 days max)"
$choice = Read-Host "Enter choice (1–3)"

switch ($choice) {
    "1" { $startDate = (Get-Date).AddDays(-30) }
    "2" { $startDate = (Get-Date).AddDays(-90) }
    "3" { $startDate = (Get-Date).AddDays(-180) }
    default {
        Write-Host "[ERROR] Invalid selection. Exiting..." -ForegroundColor Red
        exit
    }
}
$endDate = Get-Date
Write-Host "`n[INFO] Auditing from $startDate to $endDate" -ForegroundColor Cyan

# === Run Unified Audit Log Search ===
Write-Host "[INFO] Running audit log search..." -ForegroundColor Green

$results = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate `
    -Operations FileShared,SharingSet,SharingInvitationCreated,AnonymousLinkCreated `
    -ResultSize 5000

if (-not $results) {
    Write-Host "[WARN] No results found for the selected range." -ForegroundColor Yellow
    exit
}

# === Parse & Format Results ===
$parsedResults = $results | ForEach-Object {
    $data = $_.AuditData | ConvertFrom-Json

    $target = if ($data.TargetUserOrGroupName -match '^SLinkClaim') {
        "Shared Link Recipient (Unidentified)"
    } elseif ($data.TargetUserOrGroupName -eq "Limited Access System Group") {
        "Anonymous Access (Limited Access)"
    } else {
        $data.TargetUserOrGroupName
    }

    [PSCustomObject]@{
        TimeStamp    = $_.CreationDate                      # When the event occurred
        InitiatedBy  = $_.UserIds                           # Who shared the file
        Operation    = $_.Operations                        # Type of sharing (e.g. SharingSet, FileShared)
        TargetUser   = $target                              # Who received the file (mapped for readability)
        FileName     = $data.ObjectId                       # Full path to file shared
        SiteUrl      = $data.SiteUrl                        # SharePoint/OneDrive site URL
        SourceIP     = $data.ClientIP                       # IP used during sharing
        UserAgent    = $data.UserAgent                      # Browser/OS/device string
    }
}

# === Export ===
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\SharedInsight365_Report_$timestamp.xlsx"

$parsedResults | Export-Excel -Path $exportPath -AutoSize -BoldTopRow -WorksheetName "File Sharing Audit" `
    -TableName "AuditLogs" -Title "SharedInsight365 - File Sharing Audit Log" -TitleBold -FreezeTopRow

    # === Add column explanation as a second worksheet ===
$columnInfo = @(
    [PSCustomObject]@{ Column = "TimeStamp";   Description = "Date and time when the sharing action was recorded." },
    [PSCustomObject]@{ Column = "InitiatedBy"; Description = "The user who initiated the file share or created the link." },
    [PSCustomObject]@{ Column = "Operation";   Description = "The type of action performed (e.g. FileShared, SharingSet, etc.)." },
    [PSCustomObject]@{ Column = "TargetUser";  Description = "The recipient of the share – could be a user, group, or anonymous link." },
    [PSCustomObject]@{ Column = "FileName";    Description = "The full path/URL of the file that was shared." },
    [PSCustomObject]@{ Column = "SiteUrl";     Description = "The SharePoint or OneDrive site where the file is located." },
    [PSCustomObject]@{ Column = "SourceIP";    Description = "The IP address from which the action originated." },
    [PSCustomObject]@{ Column = "UserAgent";   Description = "The browser or application used during the sharing action." }
)

# Append the explanation worksheet
$columnInfo | Export-Excel -Path $exportPath -WorksheetName "Column Reference" -AutoSize -TableName "FieldDescriptions" -FreezeTopRow
Write-Host "[INFO] Column reference added to 'Column Reference' worksheet." -ForegroundColor Green

Write-Host "[SUCCESS] Export complete: $exportPath" -ForegroundColor Cyan
