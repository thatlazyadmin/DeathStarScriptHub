# Script Name: Check-DMARCRecords.ps1
# Created by: [Your Name]
# Description: This script checks the public DMARC records for a specified domain
#              and reports on the policy (quarantine or reject). It also provides
#              notes on what is needed to comply with best practices.

function Get-DMARCRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    try {
        $dnsRecord = (Resolve-DnsName -Name "_dmarc.$Domain" -Type TXT -ErrorAction Stop).Strings
        $dmarcRecord = $dnsRecord | Select-String -Pattern "^v=DMARC1"

        if ($dmarcRecord) {
            $dmarcRecord = $dmarcRecord -replace '"', ''
            Write-Host "DMARC Record for $Domain $dmarcRecord" -ForegroundColor Green
            
            if ($dmarcRecord -match "p=(\w+)") {
                $policy = $matches[1]
                Write-Host "DMARC Policy: $policy" -ForegroundColor Yellow

                switch ($policy) {
                    "reject" { Write-Host "Note: The domain is set to 'reject'. This complies with best practices for maximum protection." -ForegroundColor Green }
                    "quarantine" { Write-Host "Note: The domain is set to 'quarantine'. Consider updating to 'reject' for stricter enforcement." -ForegroundColor Yellow }
                    default { Write-Host "Note: The DMARC policy is not set to 'quarantine' or 'reject'. Please review the DMARC policy." -ForegroundColor Red }
                }
            } else {
                Write-Host "DMARC Policy not found in the record. Please review the DMARC configuration." -ForegroundColor Red
            }
        } else {
            Write-Host "No DMARC record found for $Domain." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error: Unable to resolve DMARC record for $Domain. Please ensure the domain is correct and try again." -ForegroundColor Red
    }
}

# Main Script Execution
$domain = Read-Host "Enter the domain to check DMARC record"
Get-DMARCRecord -Domain $domain