# Script Name: Export-DKIMRecords-EXO.ps1
# Description: Connects to Exchange Online, retrieves all DKIM records, checks the DKIM status, and exports the results to a CSV file.
# Created by: Shaun Hardneck
# Blog: www.thatlazyadmin.com

# Ensure the Exchange Online PowerShell module is installed
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
}

# Import the Exchange Online Management module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -ShowProgress $true

# Retrieve all DKIM records
Write-Host "Retrieving DKIM records..." -ForegroundColor Yellow
$dkimRecords = Get-DkimSigningConfig | Select-Object Domain, Status, Selector1CNAME, Selector2CNAME, Enabled

# Check if any DKIM records were retrieved
if ($dkimRecords -eq $null -or $dkimRecords.Count -eq 0) {
    Write-Host "No DKIM records found." -ForegroundColor Yellow
    Disconnect-ExchangeOnline -Confirm:$false
    exit
}

# Process DKIM records
$dkimStatusResults = foreach ($record in $dkimRecords) {
    $dkimStatus = if ($record.Enabled) { "Passed" } else { "Failed" }

    [PSCustomObject]@{
        Domain        = $record.Domain
        Status        = $dkimStatus
        Selector1CNAME = $record.Selector1CNAME
        Selector2CNAME = $record.Selector2CNAME
        Enabled       = $record.Enabled
    }
}

# Export the results to a CSV file
$outputPath = "$PSScriptRoot\DKIM_Status_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$dkimStatusResults | Export-Csv -Path $outputPath -NoTypeInformation

# Disconnect from Exchange Online
Write-Host "Disconnecting from Exchange Online..." -ForegroundColor Red
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "DKIM records have been exported to $outputPath" -ForegroundColor Green