<#
.SYNOPSIS
    This script reviews the report of users who have had their email privileges restricted due to spamming by connecting to Exchange Online and retrieving the list of blocked sender addresses.

    Created by: Shaun Hardneck
    Contact: shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves the list of blocked sender addresses.
    3. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Review-BlockedSenders.ps1
    This example runs the script to review blocked senders and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that users who have had their email privileges restricted due to spamming are reviewed and appropriate actions are taken.
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

# Function to review blocked senders
function Review-BlockedSenders {
    try {
        $blockedSenders = Get-BlockedSenderAddress -ErrorAction Stop
        $results = @()

        foreach ($sender in $blockedSenders) {
            $results += [PSCustomObject]@{
                SenderAddress    = $sender.SenderAddress
                LastBlockedTime  = $sender.LastBlockedTime
                BlockReason      = $sender.BlockReason
            }
        }

        $totalCount = $results.Count

        if ($totalCount -gt 0) {
            Write-Host "Blocked sender addresses retrieved." -ForegroundColor Green
            $results | Format-Table SenderAddress, LastBlockedTime, BlockReason

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "BlockedSendersReport_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported blocked sender addresses to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No blocked sender addresses found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve blocked sender addresses. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Review-BlockedSenders