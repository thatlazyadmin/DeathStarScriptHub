<#
.SYNOPSIS
    Log Analytics Tables Retention Export Script

.DESCRIPTION
    This PowerShell script connects to Microsoft Azure, allows the user to select a subscription and a Log Analytics workspace, and then provides the option to list tables based on either the Basic Table Plan or Analytics Table Plan. It retrieves and exports detailed information about each table's retention settings, including the table name, plan, default workspace retention period, total retention period, and calculated archive retention period.

.CREATED BY
    Shaun Hardneck (ThatLazyAdmin)

.BLOG
    www.thatlazyadmin.com

.FEATURES
    - Connects to Microsoft Azure using `Connect-AzAccount`.
    - Lists all available Azure subscriptions and allows the user to select one.
    - Lists all Log Analytics workspaces within the selected subscription.
    - Provides a menu to choose between Basic Table Plan and Analytics Table Plan.
    - Retrieves detailed information about the tables' retention settings.
    - Calculates the archive retention period.
    - Exports the results to a CSV file named `LogAnalyticsTables.csv`.

.USAGE
    1. Run the script in PowerShell.
    2. Follow the prompts to log in to your Azure account.
    3. Select the desired subscription by entering the corresponding number.
    4. Select the desired Log Analytics workspace by entering the corresponding number.
    5. Choose the log type by entering `1` for Basic Table Plan or `2` for Analytics Table Plan.
    6. The script will retrieve the relevant table information and export it to `LogAnalyticsTables.csv`.

.EXAMPLE OUTPUT
    The exported CSV file will contain the following columns:
    - TableName: The name of the Log Analytics table.
    - Plan: The plan type (Basic or Analytics).
    - RetentionInDays: The default retention period for the workspace.
    - TotalRetentionInDays: The total retention period for the table.
    - ArchiveRetentionInDays: The calculated archive retention period.

.NOTES
    This script requires the Azure PowerShell module to be installed and the user to have appropriate permissions to access the Azure resources.
#>

# Suppress Azure subscription warning
$WarningPreference = "SilentlyContinue"

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
Connect-AzAccount

# Get the list of subscriptions
$subscriptions = Get-AzSubscription
$subscriptions | ForEach-Object { Write-Host "$($_.SubscriptionId): $($_.Name)" -ForegroundColor Yellow }

# Select a subscription
for ($i = 0; $i -lt $subscriptions.Count; $i++) {
    Write-Host "$($i + 1): $($subscriptions[$i].Name)" -ForegroundColor Green
}
$subscriptionIndex = Read-Host "Enter the number corresponding to the subscription you want to use"
$selectedSubscription = $subscriptions[$subscriptionIndex - 1]
Set-AzContext -SubscriptionId $selectedSubscription.SubscriptionId

# Get the list of Log Analytics workspaces in the selected subscription
$workspaces = Get-AzOperationalInsightsWorkspace
for ($i = 0; $i -lt $workspaces.Count; $i++) {
    Write-Host "$($i + 1): $($workspaces[$i].Name)" -ForegroundColor Green
}

# Select a Log Analytics workspace
$workspaceIndex = Read-Host "Enter the number corresponding to the Log Analytics workspace you want to use"
$selectedWorkspace = $workspaces[$workspaceIndex - 1]

# Menu to select Basic Table Plan or Analytics Table Plan
$logType = @"
1: Basic Table Plan
2: Analytics Table Plan
"@
Write-Host $logType -ForegroundColor Yellow
$logTypeSelection = Read-Host "Enter the number corresponding to the log type you want to select"

# Function to get tables based on log type
Function Get-LogAnalyticsTables {
    param (
        [string]$resourceGroupName,
        [string]$workspaceName,
        [string]$logType
    )

    $tables = Get-AzOperationalInsightsTable -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName

    if ($logType -eq '1') {
        $filteredTables = $tables | Where-Object { $_.Plan -eq 'Basic' }
    } elseif ($logType -eq '2') {
        $filteredTables = $tables | Where-Object { $_.Plan -eq 'Analytics' }
    } else {
        Write-Host "Invalid selection" -ForegroundColor Red
        return
    }

    $filteredTables | ForEach-Object {
        [PSCustomObject]@{
            TableName = $_.Name
            Plan = $_.Plan
            RetentionInDays = $_.RetentionInDays
            TotalRetentionInDays = $_.TotalRetentionInDays
            ArchiveRetentionInDays = $_.TotalRetentionInDays - $_.RetentionInDays
        }
    } | Export-Csv -Path "LogAnalyticsTables.csv" -NoTypeInformation
    Write-Host "The results have been exported to LogAnalyticsTables.csv" -ForegroundColor Cyan
}

# Call the function with the selected log type
Get-LogAnalyticsTables -resourceGroupName $selectedWorkspace.ResourceGroupName -workspaceName $selectedWorkspace.Name -logType $logTypeSelection
