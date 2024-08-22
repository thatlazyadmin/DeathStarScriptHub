<#
.SYNOPSIS
    This script reviews the Account Provisioning Activity report by connecting to Exchange Online, searching the unified audit log for user addition activities, and exporting the results to a CSV file.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Sets the date range to the last 7 days.
    3. Searches the unified audit log for user addition activities.
    4. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Review-AccountProvisioningActivity.ps1
    This example runs the script to review account provisioning activities and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that all user addition activities are reviewed regularly, providing an additional layer of security and compliance.
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

# Set the date range
$startDate = ((Get-date).AddDays(-7)).ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = (Get-date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Function to review account provisioning activities
function Review-AccountProvisioningActivity {
    try {
        $activities = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -RecordType UserAdmin | Where-Object { $_.Operations -eq "Add user" }
        $results = @()

        foreach ($activity in $activities) {
            $results += [PSCustomObject]@{
                CreationDate   = $activity.CreationDate
                UserId         = $activity.UserIds -join ', '
                Operation      = $activity.Operation
                ResultStatus   = $activity.ResultStatus
                RecordType     = $activity.RecordType
                OrganizationId = $activity.OrganizationId
                UserType       = $activity.UserType
            }
        }

        $totalCount = $results.Count

        if ($totalCount -gt 0) {
            Write-Host "Account provisioning activities retrieved." -ForegroundColor Green
            $results | Format-Table CreationDate, UserId, Operation, ResultStatus, RecordType, OrganizationId, UserType

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "AccountProvisioningActivity_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported account provisioning activities to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No account provisioning activities found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve account provisioning activities. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Review-AccountProvisioningActivity