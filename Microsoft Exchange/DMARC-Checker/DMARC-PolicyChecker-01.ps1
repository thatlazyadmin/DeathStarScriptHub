# Script Name: Check-DMARCCompliance.ps1
# Created by: Shaun Hardneck
# Blog: www.thatlazyadmin.com
# Email: Shaun@thatlazyadmin.com
# Description: This script checks the public DMARC, DKIM, and SPF records for a specified domain
#              and ensures all necessary records are in place to pass DMARC checks. It provides
#              a message indicating whether the domain passes DMARC checks and highlights any issues.
#              The script is designed to help organizations avoid potential email delivery problems 
#              by ensuring proper alignment and configuration of DMARC, DKIM, and SPF records.

function Get-DNSRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain,
        [string]$RecordType
    )

    try {
        $dnsRecords = (Resolve-DnsName -Name $Domain -Type $RecordType -ErrorAction Stop).Strings
        return $dnsRecords
    } catch {
        Write-Host "Error: Unable to resolve $RecordType record for $Domain. Please ensure the domain is correct." -ForegroundColor Red
        return $null
    }
}

function Get-DMARCRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    $dmarcRecord = Get-DNSRecord -Domain "_dmarc.$Domain" -RecordType "TXT"
    
    if ($dmarcRecord) {
        $dmarcRecord = $dmarcRecord -replace '"', ''
        Write-Host "DMARC Record for $Domain $dmarcRecord" -ForegroundColor Green
        
        if ($dmarcRecord -match "p=(\w+)") {
            $policy = $matches[1]
            Write-Host "DMARC Policy: $policy" -ForegroundColor Yellow
            return $policy
        } else {
            Write-Host "DMARC Policy not found in the record. Please review the DMARC configuration." -ForegroundColor Red
            return $null
        }
    } else {
        Write-Host "No DMARC record found for $Domain." -ForegroundColor Red
        return $null
    }
}

function Get-SPFRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    $spfRecord = Get-DNSRecord -Domain "$Domain" -RecordType "TXT" | Where-Object { $_ -like "v=spf1*" }
    
    if ($spfRecord) {
        Write-Host "SPF Record for $Domain $spfRecord" -ForegroundColor Green
        return $spfRecord
    } else {
        Write-Host "No SPF record found for $Domain." -ForegroundColor Red
        return $null
    }
}

function Get-DKIMRecords {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )

    # Extract DKIM records, typically named <selector>._domainkey.<domain>
    $dkimSelectors = @("*._domainkey.$Domain")
    $dkimRecords = @()

    foreach ($selector in $dkimSelectors) {
        $records = Get-DNSRecord -Domain $selector -RecordType "TXT"
        if ($records) {
            foreach ($record in $records) {
                Write-Host "DKIM Record: $record" -ForegroundColor Green
                $dkimRecords += $record
            }
        } else {
            Write-Host "No DKIM record found for selector $selector." -ForegroundColor Red
        }
    }

    return $dkimRecords
}

function Check-DMARCCompliance {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    $dmarcPolicy = Get-DMARCRecord -Domain $Domain
    $spfRecord = Get-SPFRecord -Domain $Domain
    $dkimRecords = Get-DKIMRecords -Domain $Domain

    if ($dmarcPolicy -and $spfRecord -and $dkimRecords.Count -gt 0) {
        Write-Host "`nChecking alignment between SPF, DKIM, and DMARC..." -ForegroundColor Cyan
        
        $alignmentIssues = $false

        if ($dmarcPolicy -eq "reject" -or $dmarcPolicy -eq "quarantine") {
            Write-Host "DMARC policy is correctly set to '$dmarcPolicy'." -ForegroundColor Green
        } else {
            Write-Host "DMARC policy is not set to 'reject' or 'quarantine'. Please review the policy." -ForegroundColor Yellow
            $alignmentIssues = $true
        }

        if ($spfRecord -match "$Domain") {
            Write-Host "SPF record aligns with the domain." -ForegroundColor Green
        } else {
            Write-Host "SPF record does not align with the domain." -ForegroundColor Red
            $alignmentIssues = $true
        }

        if ($dkimRecords | Where-Object { $_ -match "$Domain" }) {
            Write-Host "DKIM record aligns with the domain." -ForegroundColor Green
        } else {
            Write-Host "DKIM record does not align with the domain." -ForegroundColor Red
            $alignmentIssues = $true
        }

        if (-not $alignmentIssues) {
            Write-Host "`nAll necessary records are in place for $Domain. DMARC checks will pass, and emails will flow without issues." -ForegroundColor Green
        } else {
            Write-Host "`nThere are alignment issues with the SPF, DKIM, or DMARC records. Please review the configuration to ensure proper email flow." -ForegroundColor Red
        }
    } else {
        Write-Host "`nDMARC compliance check failed for $Domain. Please review the records and ensure all are correctly configured." -ForegroundColor Red
    }
}

# Main Script Execution
$domain = Read-Host "Enter the domain to check DMARC compliance"
Check-DMARCCompliance -Domain $domain
