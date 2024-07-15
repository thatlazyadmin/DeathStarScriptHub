<#
.SYNOPSIS
This PowerShell script provides a daily health report for Active Directory, encompassing both the root and child domains. It assesses the health status of each domain and its domain controllers, compiling the information into an HTML report.

.DESCRIPTION
AD_DailyHealthCheck_ReportGenerator.ps1 checks the operational status of domain controllers within specified domains. It performs connectivity, replication, and service checks, and generates an HTML report outlining the overall health, listing any detected issues that need attention.

.NOTES
Version:        1.0
Author:         Shaun Hardneck
Creation Date:  2024-07-02
Last Updated:   2024-07-02
Blog:           www.thatlazyadmin.com

.LINK
Blog Post URL - More details can be found here

.EXAMPLE
PS> .\AD_DailyHealthCheck_ReportGenerator.ps1

This command executes the script to generate the Active Directory health report.
#>

# Load Active Directory Module
Import-Module ActiveDirectory

# Function to Check Domain Controller Health
function Get-DCHealth {
    param (
        [string]$Domain
    )
    $dcs = Get-ADDomainController -Filter * -Server $Domain
    $dcHealth = @()

    foreach ($dc in $dcs) {
        $dcStatus = @{
            Hostname = $dc.HostName
            IP       = $dc.IPv4Address
            Ping     = if (Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet) {"Successful"} else {"Failed"}
            ReplicationStatus = (Get-ADReplicationPartnerMetadata -Target $dc.HostName -Partition * | Measure-Object -Property LastReplicationSuccess -Maximum).Maximum
            ADServiceStatus = (Get-Service -Name "NTDS" -ComputerName $dc.HostName).Status
        }

        # Add to results
        $dcHealth += New-Object PSObject -Property $dcStatus
    }

    return $dcHealth
}

# Prompt for Root Domain
$rootDomain = Read-Host "Please enter the Root Domain (e.g., root.domain.com)"

# Main Script
$childDomains = Get-ADTrust -Filter "RootDomain -eq '$rootDomain'"
$htmlReport = @()

foreach ($child in $childDomains) {
    $dcHealth = Get-DCHealth -Domain $child.Name
    $healthSummary = $dcHealth | Group-Object -Property Ping | Select Name, Count
    $healthy = $healthSummary | Where-Object {$_.Name -eq "Successful"} | Select -ExpandProperty Count
    $total = $dcHealth.Count
    $errors = $total - $healthy

    $reportEntry = @{
        ChildDomain = $child.Name
        TotalDCs    = $total
        HealthyDCs  = $healthy
        Errors      = $errors
    }

    $htmlReport += New-Object PSObject -Property $reportEntry
}

# Convert to HTML
$html = $htmlReport | ConvertTo-Html -Title "Daily Active Directory Health Report" -PreContent "<h1>Active Directory Health Report</h1>" -As Table
$html | Out-File "AD_Health_Report.html"

Write-Host "Report has been generated at AD_Health_Report.html"
# Created By: Shaun Hardneck
# Blog: www.thatlazyadmin.com