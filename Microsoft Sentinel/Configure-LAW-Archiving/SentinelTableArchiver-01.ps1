# Import the necessary modules
#Import-Module Az -ErrorAction SilentlyContinue

# Function to authenticate and select a subscription
function Select-Subscription {
    Write-Host "Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount -WarningAction SilentlyContinue | Out-Null

    $subscriptions = Get-AzSubscription
    $counter = 1
    $subscriptions | ForEach-Object { Write-Host "$counter. $($_.Name) ($($_.SubscriptionId))" -ForegroundColor Yellow; $counter++ }
    
    $subscriptionNumber = Read-Host "Enter the number of the subscription to use"
    $selectedSubscription = $subscriptions[$subscriptionNumber - 1]
    Set-AzContext -SubscriptionId $selectedSubscription.SubscriptionId -WarningAction SilentlyContinue | Out-Null

    Write-Host "Selected subscription: $($selectedSubscription.Name)" -ForegroundColor Green
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
    $workspaces | ForEach-Object { Write-Host "$counter. $($_.ResourceGroupName) - $($_.Name)" -ForegroundColor Yellow; $counter++ }
    
    $workspaceNumber = Read-Host "Enter the number of the workspace to use"
    $selectedWorkspace = $workspaces[$workspaceNumber - 1]

    $resourceGroupName = $selectedWorkspace.ResourceGroupName
    $workspaceName = $selectedWorkspace.Name
    Write-Host "Selected workspace: $workspaceName in resource group: $resourceGroupName" -ForegroundColor Green

    Write-Host "`nEnter retention options (in days):" -ForegroundColor Cyan
    Write-Host "1. Retention: Number of days data is retained for interactive queries." -ForegroundColor Yellow
    Write-Host "   Example: 30" -ForegroundColor White
    Write-Host "2. Total Retention: Total number of days data is retained (including archived data)." -ForegroundColor Yellow
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
    Write-Host "`nOperation completed. Returning to start..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
}
