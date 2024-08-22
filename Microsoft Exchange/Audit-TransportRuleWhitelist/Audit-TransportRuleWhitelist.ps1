<#
.SYNOPSIS
    This script verifies that no mail transport rules are whitelisting any domains in Microsoft 365. The results are exported to a CSV file if any such rules are found.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves transport rules that whitelist domains by setting the SCL (Spam Confidence Level) to -1.
    3. Exports the results to a CSV file if any such rules are found.

.PARAMETER None

.EXAMPLE
    .\Audit-TransportRuleWhitelist.ps1
    This example runs the script to audit transport rules and verify that no domains are whitelisted. Results are exported to a CSV file if any such rules are found.

.NOTES
    This script is necessary to ensure that no transport rules are configured to whitelist domains, enhancing the security and compliance posture of the organization.
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

# Function to audit transport rules for whitelisted domains
function Audit-TransportRuleWhitelist {
    try {
        $transportRules = Get-TransportRule | Where-Object {($_.SetScl -eq -1 -and $_.SenderDomainIs -ne $null)}
        $whitelistedDomains = @()
        
        foreach ($rule in $transportRules) {
            foreach ($domain in $rule.SenderDomainIs) {
                $whitelistedDomains += [PSCustomObject]@{
                    RuleName      = $rule.Name
                    SenderDomain  = $domain
                }
            }
        }

        if ($whitelistedDomains.Count -gt 0) {
            Write-Host "Transport rules with whitelisted domains found." -ForegroundColor Red
            $whitelistedDomains | Format-Table RuleName, SenderDomain

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "WhitelistedDomainsTransportRules_$currentDate.csv"
            $whitelistedDomains | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No transport rules with whitelisted domains found." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to retrieve transport rules. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Audit-TransportRuleWhitelist