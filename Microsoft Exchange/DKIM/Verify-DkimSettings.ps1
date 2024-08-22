<#
.SYNOPSIS
    This script verifies that DKIM is enabled for each domain in Microsoft 365.

    Created by: Shaun Hardneck
    Company: URBANNERD CONSULTING
    Contact: hello@unerd.co.za
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves the DKIM signing configuration for each domain.
    3. Verifies that DKIM is enabled for each domain.
    4. Exports the verification results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Verify-DkimSettings.ps1
    This example runs the script to verify DKIM settings for all domains and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that DKIM is properly configured and enabled for all domains, providing an additional layer of email security.
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

# Function to verify DKIM settings
function Verify-DkimSettings {
    try {
        $dkimConfigs = Get-DkimSigningConfig -ErrorAction Stop
        $results = @()

        foreach ($config in $dkimConfigs) {
            $results += [PSCustomObject]@{
                DomainName  = $config.Domain
                Enabled     = $config.Enabled
                Status      = if ($config.Enabled) { "Enabled" } else { "Not Enabled" }
            }
        }

        $totalCount = $results.Count

        if ($totalCount -gt 0) {
            Write-Host "DKIM configuration retrieved for $totalCount domains." -ForegroundColor Green
            $results | Format-Table DomainName, Enabled, Status

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "DkimSettingsAudit_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported DKIM settings to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No DKIM configurations found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve DKIM configuration. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Verify-DkimSettings