<#
.SYNOPSIS
    This script checks the DMARC records for a list of Exchange Online domains and ensures they meet specific criteria.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Checks the DMARC records for a predefined list of domains.
    2. Ensures that the record exists and meets the specified criteria.
    3. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Check-DmarcRecords.ps1
    This example runs the script to check DMARC records for all specified domains and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that DMARC records are properly configured for all domains, providing an additional layer of email security.
#>

# Define the list of domains to check
$domains = @("barrange.co.za", "drillcorp.co.za", "drillcorpafrica.com","drilltechservices.co.za","geoserve.co.za","geoservesa.co.za","masterdrill.co.za","masterdrilling.co.za","masterdrilling.com","thekalaharisands.com","masterdrilling.mail.onmicrosoft.com","masterdrilling.onmicrosoft.com")

# Function to check DMARC records
function Check-DmarcRecords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Domains
    )

    $results = @()
    $validDmarcPattern = "v=DMARC1;.*(p=quarantine|p=reject);.*pct=100;.*rua=mailto:.*;.*ruf=mailto:.*;"

    foreach ($domain in $Domains) {
        try {
            $dmarcRecord = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction Stop | Select-Object -ExpandProperty Strings

            if ($dmarcRecord -match $validDmarcPattern) {
                $status = "Pass"
            } else {
                $status = "Fail"
            }

            $results += [PSCustomObject]@{
                Domain       = $domain
                DmarcRecord  = $dmarcRecord
                Status       = $status
            }
            Write-Host "Checked DMARC record for $domain" -ForegroundColor Green
        } catch {
            $results += [PSCustomObject]@{
                Domain       = $domain
                DmarcRecord  = "Not found"
                Status       = "Fail"
            }
            Write-Host "Failed to resolve DMARC record for $domain" -ForegroundColor Red
        }
    }

    $results
}

# Check DMARC records
$dmarcResults = Check-DmarcRecords -Domains $domains

# Export to CSV
if ($dmarcResults.Count -gt 0) {
    $currentDate = Get-Date -Format "yyyyMMdd"
    $fileName = "DmarcRecordsAudit_$currentDate.csv"
    $dmarcResults | Export-Csv -Path $fileName -NoTypeInformation
    Write-Host "Exported DMARC records to $fileName" -ForegroundColor Green
} else {
    Write-Host "No DMARC records found to export." -ForegroundColor Yellow
}