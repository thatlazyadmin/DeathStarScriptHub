<#
.SYNOPSIS
This script manages the archive time period for Log Analytics tables in Microsoft Sentinel and can also list tables based on their type (Basic or Analytics).
It handles authentication, lists and selects subscriptions and workspaces, updates table archive periods, provides detailed outputs, and logs errors to a file.

.CREATED BY
Shaun Hardneck - ThatLazyAdmin
Blog: www.thatlazyadmin.com

.DESCRIPTION
The script ensures Azure authentication, handles multiple subscriptions by allowing the user to select one, lists all tables in a selected workspace, categorizes them into Basic or Analytics logs, and updates archive periods based on user selection. Detailed information about each operation is displayed and logged.
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

# Main menu options
Write-Host "Select an operation:"
Write-Host "1. Update Retention Settings for Tables"
Write-Host "2. List Tables by Type (Basic or Analytics Logs)"
$operationChoice = Read-Host "Enter your choice (1 or 2)"

# Execute based on choice
switch ($operationChoice) {
    "1" {
        # Retrieve all tables in the selected workspace
        $tables = Get-AzOperationalInsightsTable -ResourceGroupName $selectedWorkspace.ResourceGroupName -WorkspaceName $selectedWorkspace.Name

        # Categorize tables as Basic or Analytics
        $basicTables = @()
        $analyticsTables = @()
        foreach ($table in $tables) {
            if ($table.TableName -like "*Basic*") { # Adjust the condition based on actual naming conventions
                $basicTables += $table
            } else {
                $analyticsTables += $table
            }
        }

        # Display categories and ask user for choice
        Write-Host "Select the type of logs to modify:"
        Write-Host "1. Basic Logs"
        Write-Host "2. Analytics Logs"
        $logTypeChoice = Read-Host "Enter your choice (1 for Basic Logs, 2 for Analytics Logs)"
        
        # Apply the choice
        $selectedTables = @()
        switch ($logTypeChoice) {
            "1" { $selectedTables = $basicTables }
            "2" { $selectedTables = $analyticsTables }
            default {
                Write-Host "Invalid selection" -ForegroundColor Red
                exit
            }
        }

        # Get archive period and update selected tables
        $archivePeriod = Read-Host "Enter the Archive Period in days (enter a positive number, one of the allowed full-year values, or 'default' to reset)"
        foreach ($table in $selectedTables) {
            try {
                # Checking if modification is applicable
                if ($table.Plan -eq 'Basic' -and $table.TableName -notlike "*Basic*") {
                    Write-Host "Skipping ${table.TableName}: Retention settings are immutable on the Basic Logs plan." -ForegroundColor Yellow
                    continue
                }

                # Apply the default or specific retention settings
                if ($archivePeriod -eq "default") {
                    # Placeholder values for demonstration; dynamically retrieve actual defaults if available
                    $defaultRetentionInDays = 30
                    $defaultTotalRetentionInDays = 730
                    Update-AzOperationalInsightsTable -ResourceGroupName $selectedWorkspace.ResourceGroupName `
                                                      -WorkspaceName $selectedWorkspace.Name `
                                                      -TableName $table.TableName `
                                                      -RetentionInDays $defaultRetentionInDays `
                                                      -TotalRetentionInDays $defaultTotalRetentionInDays
                    Write-Host "Reset ${table.TableName} to workspace default retention settings" -ForegroundColor Green
                } else {
                    $retentionInDays = 30
                    $totalRetention = $archivePeriod
                    Update-AzOperationalInsightsTable -ResourceGroupName $selectedWorkspace.ResourceGroupName `
                                                      -WorkspaceName $selectedWorkspace.Name `
                                                      -TableName $table.TableName `
                                                      -RetentionInDays $retentionInDays `
                                                      -TotalRetentionInDays $totalRetention
                    Write-Host "Updated ${table.TableName}: RetentionInDays=$retentionInDays, TotalRetentionInDays=$totalRetention" -ForegroundColor Green
                }
            } catch {
                $ErrorMessage = $_.Exception.Message
                $ErrorDetails = "$($_.InvocationInfo.MyCommand): $ErrorMessage"
                Add-Content -Path "error_log.txt" -Value $ErrorDetails
            }
        }
    }
    "2" {
        # Display table types
        Write-Host "Basic Logs Tables:"
        $basicTables | ForEach-Object { Write-Host $_.TableName -ForegroundColor Cyan }
        Write-Host "Analytics Logs Tables:"
        $analyticsTables | ForEach-Object { Write-Host $_.TableName -ForegroundColor Cyan }
    }
    default {
        Write-Host "Invalid selection" -ForegroundColor Red
        exit
    }
}
