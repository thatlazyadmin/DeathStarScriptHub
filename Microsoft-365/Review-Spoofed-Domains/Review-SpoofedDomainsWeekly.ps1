<#
.SYNOPSIS
    This script reviews spoofed domains by connecting to Exchange Online and retrieving spoof intelligence insights for the last 7 days.

    Created by: Shaun Hardneck
    Contact: Shaun@hardneck.co.za
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves spoof intelligence insights for the last 7 days.
    3. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Review-SpoofedDomainsWeekly.ps1
    This example runs the script to review spoofed domains and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that spoofed domains are being reviewed weekly, providing an additional layer of email security.
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

# Function to review spoofed domains
function Review-SpoofedDomains {
    try {
        $insights = Get-SpoofIntelligenceInsight -ErrorAction Stop
        $results = @()

        foreach ($insight in $insights) {
            $results += [PSCustomObject]@{
                SpoofedUser           = $insight.SpoofedUser
                SendingInfrastructure = $insight.SendingInfrastructure
                MessageCount          = $insight.MessageCount
                LastSeen              = $insight.LastSeen
                SpoofType             = $insight.SpoofType
                Action                = $insight.Action
            }
        }

        $totalCount = $results.Count

        if ($totalCount -gt 0) {
            Write-Host "Spoof intelligence insights retrieved for the last 7 days." -ForegroundColor Green
            $results | Format-Table SpoofedUser, SendingInfrastructure, MessageCount, LastSeen, SpoofType, Action

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "SpoofedDomainsReport_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported spoof intelligence insights to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No spoof intelligence insights found for the last 7 days." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve spoof intelligence insights. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Review-SpoofedDomains