<#
.SYNOPSIS
    This script audits transport rules in Microsoft 365 to ensure no emails are redirected to external domains. The results are exported to a CSV file if any such rules are found.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves transport rules that are redirecting email.
    3. Verifies that none of the redirect addresses belong to external domains.
    4. Exports the results to a CSV file if any external redirects are found.

.PARAMETER None

.EXAMPLE
    .\Audit-TransportRules.ps1
    This example runs the script to audit transport rules and verify that no emails are redirected to external domains. Results are exported to a CSV file if any such rules are found.

.NOTES
    This script is necessary to ensure that no transport rules are configured to redirect emails to external domains, enhancing the security and compliance posture of the organization.
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

# Function to audit transport rules
function Audit-TransportRules {
    try {
        $transportRules = Get-TransportRule | Where-Object { $_.RedirectMessageTo -ne $null }
        $externalRedirects = @()
        
        foreach ($rule in $transportRules) {
            foreach ($address in $rule.RedirectMessageTo) {
                if ($address -notlike "*@yourdomain.com") {
                    $externalRedirects += [PSCustomObject]@{
                        RuleName           = $rule.Name
                        RedirectAddress    = $address
                    }
                }
            }
        }

        if ($externalRedirects.Count -gt 0) {
            Write-Host "Transport rules with external redirects found." -ForegroundColor Red
            $externalRedirects | Format-Table RuleName, RedirectAddress

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "ExternalRedirectTransportRules_$currentDate.csv"
            $externalRedirects | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No transport rules with external redirects found." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to retrieve transport rules. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Audit-TransportRules