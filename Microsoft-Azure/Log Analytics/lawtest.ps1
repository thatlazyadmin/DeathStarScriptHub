# Connect to Azure
Connect-AzAccount

# Select the correct subscription
$subscriptionId = "6052118b-adbb-4504-a41a-e8e1121163fe" # <- UPDATE if needed
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

# Verify the current subscription is set
$context = Get-AzContext
if ($context.Subscription.Id -ne $subscriptionId) {
    Write-Host "ERROR: Failed to switch to the correct subscription!" -ForegroundColor Red
    exit
}

Write-Host "Using Subscription: $($context.Subscription.Name) ($subscriptionId)" -ForegroundColor Green

# Get all Log Analytics Workspaces in the selected subscription
$workspaces = Get-AzOperationalInsightsWorkspace

# Validate if workspaces exist
if ($workspaces.Count -eq 0) {
    Write-Host "No Log Analytics Workspaces found in subscription: $subscriptionId" -ForegroundColor Yellow
    exit
}

# Create an output array
$results = @()

# Loop through each workspace
foreach ($workspace in $workspaces) {
    $workspaceName = $workspace.Name
    $workspaceId = $workspace.CustomerId  # FIXED: This is the correct ID

    Write-Host "Processing Workspace: $workspaceName" -ForegroundColor Cyan

    # KQL Query to get table sizes and last write time
    $query = @"
    union withsource=TableName *
    | summarize TableSizeGB=sum(_BilledSize)/1024/1024/1024, LastWriteTime=max(TimeGenerated)
    by TableName
    | order by TableSizeGB desc
"@

    # Run the query
    try {
        $queryResults = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $query

        if ($queryResults.Results.Count -eq 0) {
            Write-Host "No data available for workspace: $workspaceName" -ForegroundColor Yellow
        } else {
            foreach ($row in $queryResults.Results) {
                $results += [PSCustomObject]@{
                    SubscriptionID = $subscriptionId
                    WorkspaceName = $workspaceName
                    TableName = $row.TableName
                    TableSizeGB = [math]::Round($row.TableSizeGB, 2)
                    LastWriteTime = $row.LastWriteTime
                }
            }
        }
    }
    catch {
        Write-Host "Error retrieving data for workspace: $workspaceName" -ForegroundColor Red
        Write-Output "Error: $_" | Out-File -Append -FilePath "LogAnalytics_Error.log"
    }
}

# Export results to CSV
$csvPath = ".\LogAnalyticsWorkspaceSizes_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Export completed: $csvPath" -ForegroundColor Green
