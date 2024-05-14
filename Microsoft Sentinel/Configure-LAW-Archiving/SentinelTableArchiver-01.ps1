<#
.SYNOPSIS
This script manages the archive time period for Log Analytics tables in Microsoft Sentinel.
It handles authentication, lists and selects subscriptions and workspaces, updates table archive periods, and provides detailed outputs with color.
Errors are logged to a file, and details of updates are exported to a CSV file.

.CREATED BY
Shaun Hardneck - ThatLazyAdmin
Blog: www.thatlazyadmin.com

.DESCRIPTION
The script ensures Azure authentication, handles multiple subscriptions by allowing the user to select one, and updates archive periods for Log Analytics tables within the selected workspace. Detailed information about each update is displayed, and warning messages are suppressed. Errors are logged, and updates are summarized in a CSV file.
#>

# Authenticate and connect to Azure
$WarningPreference = 'SilentlyContinue'
Connect-AzAccount -WarningAction SilentlyContinue

# Get and list subscriptions
$subscriptions = Get-AzSubscription
$index = 0
$subscriptions | ForEach-Object { $index++; Write-Host "$index. $($_.Name)" -ForegroundColor Cyan }
$selectedSubscriptionIndex = Read-Host "Select a subscription by number (1-$index)"
$selectedSubscription = $subscriptions[$selectedSubscriptionIndex - 1]
Set-AzContext -SubscriptionId $selectedSubscription.Id -WarningAction SilentlyContinue

# Get and list Log Analytics Workspaces
$workspaces = Get-AzOperationalInsightsWorkspace
if ($workspaces.Count -eq 0) {
    Write-Host "No Log Analytics Workspaces found in the selected subscription." -ForegroundColor Red
    exit
}
$index = 0
$workspaces | ForEach-Object { $index++; Write-Host "$index. $($_.Name)" -ForegroundColor Cyan }
$selectedWorkspaceIndex = Read-Host "Select a Log Analytics Workspace by number (1-$index)"
$selectedWorkspace = $workspaces[$selectedWorkspaceIndex - 1]

# Initialize list to hold table update details
$tableUpdateDetails = @()

# Display allowed retention values message
Write-Host "NOTE: To reset to workspace default settings, type 'default'. For new settings, allowed total retention values are: [4-730], 1095, 1460, 1826, 2191, 2556, 2922, 3288, 3653, 4018, 4383 days." -ForegroundColor Yellow

# Menu for log type selection
$logType = Read-Host "Choose Log Type (1 for Basic Logs, 2 for Analytics Logs)"
$tables = @()
switch ($logType) {
    "1" { $tables = @('SecurityEvent', 'Syslog', 'AzureMetrics') } # Example tables for Basic Logs
    "2" { $tables = @('AppAvailabilityResults', 'AppBrowserTimings', 'AppDependencies', 'AppExceptions', 'AppEvents', 'AppMetrics', 'AppPageViews', 'AppPerformanceCounters', 'AppRequests', 'AppSystemEvents', 'AppTraces') } # Example tables for Analytics Logs
    default { Write-Host "Invalid selection" -ForegroundColor Red; exit }
}

# Get archive period and update tables
$archivePeriod = Read-Host "Enter the Archive Period in days (enter a positive number, one of the allowed full-year values, or 'default' to reset)"
foreach ($table in $tables) {
    try {
        # Retrieve current table details
        $tableDetails = Get-AzOperationalInsightsTable -ResourceGroupName $selectedWorkspace.ResourceGroupName -WorkspaceName $selectedWorkspace.Name -TableName $table
        if ($tableDetails.Plan -eq 'Basic') {
            Write-Host "Skipping ${table}: Retention settings are immutable on the Basic Logs plan." -ForegroundColor Yellow
            continue
        }

        if ($archivePeriod -eq "default") {
            $defaultRetentionInDays = 30  # Placeholder for workspace default interactive retention days
            $defaultTotalRetentionInDays = 730  # Placeholder for workspace default total retention days
            Update-AzOperationalInsightsTable -ResourceGroupName $selectedWorkspace.ResourceGroupName `
                                              -WorkspaceName $selectedWorkspace.Name `
                                              -TableName $table `
                                              -RetentionInDays $defaultRetentionInDays `
                                              -TotalRetentionInDays $defaultTotalRetentionInDays
            Write-Host "Reset ${table} to workspace default retention settings" -ForegroundColor Green
            $tableUpdateDetails += [PSCustomObject]@{
                TableName = $table
                RetentionInDays = $defaultRetentionInDays
                TotalRetentionInDays = $defaultTotalRetentionInDays
                WorkspaceName = $selectedWorkspace.Name
            }
        } else {
            $retentionInDays = 30 # Default retention period for interactive use
            $totalRetention = $archivePeriod # Directly use input since valid values are specific
            Update-AzOperationalInsightsTable -ResourceGroupName $selectedWorkspace.ResourceGroupName `
                                              -WorkspaceName $selectedWorkspace.Name `
                                              -TableName $table `
                                              -RetentionInDays $retentionInDays `
                                              -TotalRetentionInDays $totalRetention
            Write-Host "Updated ${table}: RetentionInDays=$retentionInDays, TotalRetentionInDays=$totalRetention, WorkspaceName=$($selectedWorkspace.Name)" -ForegroundColor Green
            $tableUpdateDetails += [PSCustomObject]@{
                TableName = $table
                RetentionInDays = $retentionInDays
                TotalRetentionInDays = $totalRetention
                WorkspaceName = $selectedWorkspace.Name
            }
        }
    } catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorDetails = "$($_.InvocationInfo.MyCommand): $ErrorMessage"
        Add-Content -Path "error_log.txt" -Value $ErrorDetails
    }
}

# Export the table update details to a CSV file
$tableUpdateDetails | Export-Csv -Path "TableUpdateDetails.csv" -NoTypeInformation

Write-Host "All selected tables have been updated successfully." -BackgroundColor Green -ForegroundColor Black