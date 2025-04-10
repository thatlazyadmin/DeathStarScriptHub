# Set Variables
$SubscriptionId = "6052118b-adbb-4504-a41a-e8e1121163fe"
$ResourceGroup = "rg-az-monitoring-uks"
$WorkspaceName = "Monster-LA"

# Get Azure Access Token for Log Analytics Query API
$accessToken = (Get-AzAccessToken -ResourceUrl "https://api.loganalytics.io").Token

# Define API Endpoint (Log Analytics Query API)
$apiUrl = "https://api.loganalytics.io/v1/workspaces/$WorkspaceName/query"

# Log Analytics Query to Fetch Table Size & Last Ingestion Time
$body = @{
    "query" = @"
    union Heartbeat, Syslog, SecurityEvent
    | summarize TotalSize = sum(_BilledSize), LastIngestion = max(TimeGenerated) by Type
    "@
} | ConvertTo-Json -Depth 3

# Call API using Invoke-RestMethod
$response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
} -Body $body

# Display Results
if ($response.tables) {
    $tableResults = $response.tables.rows | ForEach-Object {
        [PSCustomObject]@{
            TableName       = $_[0]
            TotalSizeGB     = "{0:N2}" -f ($_[1] / 1GB)
            LastIngestedTime = $_[2]
        }
    }
    $tableResults | Format-Table -AutoSize
} else {
    Write-Host "❌ No data found. Check permissions or workspace settings." -ForegroundColor Red
}
