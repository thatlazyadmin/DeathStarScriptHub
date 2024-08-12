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
Write-Host "Connecting to Exchange Online..."
$UserCredential = Get-Credential
Connect-ExchangeOnline -UserPrincipalName $UserCredential.UserName -ShowProgress $true

# Retrieve all DKIM records
Write-Host "Retrieving DKIM records..."
$dkimRecords = Get-DkimSigningConfig

# Create a custom object to hold the DKIM status
$dkimStatusResults = foreach ($record in $dkimRecords) {
    $dkimStatus = if ($record.Enabled) { "Passed" } else { "Failed" }
    [PSCustomObject]@{
        Domain          = $record.Domain
        Enabled         = $record.Enabled
        CnameHostName1  = $record.CnameHostName
        CnameTextValue1 = $record.CnameTextValue
        CnameHostName2  = $record.CnameHostName.Replace("selector1", "selector2")
        CnameTextValue2 = $record.CnameTextValue.Replace("selector1", "selector2")
        Status          = $dkimStatus
    }
}

# Export the results to a CSV file
$outputPath = "$PSScriptRoot\DKIM_Status_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$dkimStatusResults | Export-Csv -Path $outputPath -NoTypeInformation

# Disconnect from Exchange Online
Write-Host "Disconnecting from Exchange Online..."
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "DKIM records have been exported to $outputPath"