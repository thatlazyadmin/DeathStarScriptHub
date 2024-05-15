# ==============================================================================
# Azure Log Analytics Table Retention Update Script
# Created by: Shaun Hardneck (ThatLazyAdmin)
# Blog: www.thatlazyadmin.com
# ==============================================================================
# This script connects to Azure, allows you to select a subscription and a Log Analytics workspace,
# and sets the retention and archive duration for all tables within the workspace.
#
# Features:
# - Suppresses Azure subscription warnings
# - Silences output after selecting the subscription
# - Exports results to a CSV file
# - Returns to subscription selection after completion
#
# Retention Options:
# 1. Retention: Number of days data is retained for interactive queries.
#    Example: 30 (Interactive queries will be possible for the last 30 days of data)
# 2. Total Retention: Total number of days data is retained (including archived data).
#    Example: 730 (Data will be retained for a total of 2 years, with archived data available after the interactive retention period)
# ==============================================================================

# Import the necessary modules
# Import-Module Az -ErrorAction SilentlyContinue

# Permanent banner
function Show-Banner {
    Clear-Host
    Write-Host "============================================" -ForegroundColor White
    Write-Host "     Microsoft Azure Log Analytics Retention" -ForegroundColor DarkYellow
    Write-Host "============================================" -ForegroundColor White
}

# Close out banner
function Show-CloseBanner {
    Write-Host "============================================" -ForegroundColor White
    Write-Host "        Script Execution Completed!" -ForegroundColor DarkYellow
    Write-Host "============================================" -ForegroundColor White
}

# Function to authenticate and select a subscription
function Select-Subscription {
    Show-Banner
    Write-Host "Connecting to Azure..." -ForegroundColor DarkGray
    $WarningPreference = 'SilentlyContinue'
    Connect-AzAccount -WarningAction SilentlyContinue 3>&1 | Out-Null

    $subscriptions = Get-AzSubscription
    $counter = 1
    $subscriptions | ForEach-Object { Write-Host "$counter. $($_.Name) ($($_.SubscriptionId))" -ForegroundColor DarkYellow; $counter++ }
    
    $subscriptionNumber = Read-Host "Enter the number of the subscription to use"
    $selectedSubscription = $subscriptions[$subscriptionNumber - 1]
    Set-AzContext -SubscriptionId $selectedSubscription.SubscriptionId -WarningAction SilentlyContinue 3>&1 | Out-Null

    Write-Host "Selected subscription: $($selectedSubscription.Name)" -ForegroundColor DarkGray
}

# Function to list workspaces and prompt for retention value
function Update-Retention {
    $resourceGroups = Get-AzResourceGroup
    $workspaces = @()

    foreach ($rg in $resourceGroups) {
        $rgWorkspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rg.ResourceGroupName
        $workspaces += $rgWorkspaces
    }

    if ($workspaces.Count -eq 0) {
        Write-Host "No workspaces found in the selected subscription." -ForegroundColor Red
        return
    }

    $counter = 1
    $workspaces | ForEach-Object { Write-Host "$counter. $($_.ResourceGroupName) - $($_.Name)" -ForegroundColor DarkYellow; $counter++ }
    
    $workspaceNumber = Read-Host "Enter the number of the workspace to use"
    $selectedWorkspace = $workspaces[$workspaceNumber - 1]

    $resourceGroupName = $selectedWorkspace.ResourceGroupName
    $workspaceName = $selectedWorkspace.Name
    Write-Host "Selected workspace: $workspaceName in resource group: $resourceGroupName" -ForegroundColor DarkGray

    Write-Host "`nEnter retention options (in days):" -ForegroundColor Cyan
    Write-Host "1. Retention: Number of days data is retained for interactive queries." -ForegroundColor DarkYellow
    Write-Host "   Example: 30" -ForegroundColor White
    Write-Host "2. Total Retention: Total number of days data is retained (including archived data)." -ForegroundColor DarkYellow
    Write-Host "   Example: 730 (for 2 years)" -ForegroundColor White

    $retentionInDays = Read-Host "`nEnter the retention in days (e.g., 30)"
    $totalRetentionInDays = Read-Host "Enter the total retention in days (e.g., 730)"

    $tables = Get-AzOperationalInsightsTable -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName
    $results = @()
    foreach ($table in $tables) {
        Update-AzOperationalInsightsTable -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -TableName $table.Name -RetentionInDays $retentionInDays -TotalRetentionInDays $totalRetentionInDays
        Write-Host "Updated table $($table.Name) with retention $retentionInDays days and total retention $totalRetentionInDays days." -ForegroundColor Green
        $results += [PSCustomObject]@{
            TableName = $table.Name
            RetentionInDays = $retentionInDays
            TotalRetentionInDays = $totalRetentionInDays
        }
    }

    $csvPath = "$workspaceName-TableRetention.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "`nResults exported to $csvPath." -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# Main script execution loop
while ($true) {
    Select-Subscription
    Update-Retention
    Write-Host "`nOperation completed." -ForegroundColor Cyan
    Show-CloseBanner

    $choice = Read-Host "`nDo you want to restart the script or end the session? (Enter 'R' to restart or 'E' to end)"
    if ($choice -eq 'E') {
        Write-Host "Ending session..." -ForegroundColor Cyan
        break
    }
}