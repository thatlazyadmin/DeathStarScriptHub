# Script Name: Get-ExchangeOnlineDKIMRecords.ps1
# Description: Connects to Exchange Online, retrieves all DKIM records, and exports them to a CSV file.
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

# Export the results to a CSV file
$outputPath = "$PSScriptRoot\DKIM_Records_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$dkimRecords | Select-Object Domain, Enabled, CnameHostName, CnameTextValue, Identity | Export-Csv -Path $outputPath -NoTypeInformation

# Disconnect from Exchange Online
Write-Host "Disconnecting from Exchange Online..."
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "DKIM records have been exported to $outputPath"
