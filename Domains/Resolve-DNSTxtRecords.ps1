<#
.SYNOPSIS
    This script resolves the DNS TXT records for multiple domains and exports the results to a CSV file.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Resolves the DNS TXT records for a predefined list of domains.
    2. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Resolve-DnsTxtRecords.ps1
    This example runs the script, resolves the DNS TXT records for the predefined list of domains, and exports the results to a CSV file.
#>

# Define the list of domains to resolve
$domains = @("domain1", "domain.co.za","domain11.com")

# Function to resolve DNS TXT records for a list of domains
function Resolve-DnsTxtRecords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Domains
    )

    $results = @()

    foreach ($domain in $Domains) {
        try {
            $txtRecords = Resolve-DnsName -Name $domain -Type TXT -ErrorAction Stop
            foreach ($record in $txtRecords) {
                $results += [PSCustomObject]@{
                    Domain    = $domain
                    Name      = $record.Name
                    QueryType = $record.QueryType
                    TTL       = $record.TimeToLive
                    Strings   = $record.Strings -join ", "
                }
            }
            Write-Host "Successfully resolved TXT records for $domain" -ForegroundColor Green
        } catch {
            Write-Host "Failed to resolve TXT records for $domain. $_" -ForegroundColor Red
        }
    }

    $results
}

# Resolve DNS TXT records
$dnsResults = Resolve-DnsTxtRecords -Domains $domains

# Export to CSV
if ($dnsResults.Count -gt 0) {
    $currentDate = Get-Date -Format "yyyyMMdd"
    $fileName = "DnsTxtRecords_$currentDate.csv"
    $dnsResults | Export-Csv -Path $fileName -NoTypeInformation
    Write-Host "Exported DNS TXT records to $fileName" -ForegroundColor Green
} else {
    Write-Host "No DNS TXT records found to export." -ForegroundColor Yellow
}
