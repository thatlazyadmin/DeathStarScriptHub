# 1️⃣ FORCE LOGIN TO AZURE (NO CACHED CREDENTIALS)
Write-Host "🔵 Connecting to Azure..." -ForegroundColor Cyan
$ErrorActionPreference = "Stop"

try {
    # Force logout first
    Disconnect-AzAccount -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # **Use manual login instead of cached credentials**
    Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop
}
catch {
    Write-Host "❌ ERROR: Failed to authenticate. Please manually sign in with 'Connect-AzAccount'." -ForegroundColor Red
    exit
}

# 2️⃣ SET SUBSCRIPTION & VERIFY CONTEXT
$subscriptionId = "6052118b-adbb-4504-a41a-e8e1121163fe"
Write-Host "🔄 Switching to Subscription: $subscriptionId ..." -ForegroundColor Yellow
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

# VERIFY SUBSCRIPTION
$context = Get-AzContext
if ($context.Subscription.Id -ne $subscriptionId) {
    Write-Host "❌ ERROR: Subscription did not switch correctly. Stopping script." -ForegroundColor Red
    exit
}
Write-Host "✅ Subscription switched to: $($context.Subscription.Name) ($subscriptionId)" -ForegroundColor Green

# 3️⃣ GET ALL LOG ANALYTICS WORKSPACES
$workspaces = Get-AzOperationalInsightsWorkspace
if ($workspaces.Count -eq 0) {
    Write-Host "⚠️ No Log Analytics Workspaces found in this subscription!" -ForegroundColor Yellow
    exit
}

# 4️⃣ CREATE OUTPUT ARRAY
$results = @()

# 5️⃣ LOOP THROUGH WORKSPACES AND USE REST API
foreach ($workspace in $workspaces) {
    $workspaceName = $workspace.Name
    $customerId = $workspace.CustomerId
    $resourceId = $workspace.ResourceId

    Write-Host "`n📡 Checking Log Analytics Workspace: $workspaceName" -ForegroundColor Cyan
    Write-Host "➡️  CustomerId: $customerId"
    Write-Host "➡️  ResourceId: $resourceId"

    # 🔍 GET TOKEN FOR REST API AFTER PROPER AUTH
    try {
        $token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
        if (-not $token) {
            throw "Failed to acquire valid access token."
        }
    }
    catch {
        Write-Host "❌ ERROR: Failed to acquire an Azure access token. Authentication problem." -ForegroundColor Red
        continue
    }

    # 🔍 DEFINE API REQUEST
    $headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
    $uri = "https://management.azure.com$resourceId/usages?api-version=2021-12-01"

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        foreach ($usage in $response.value) {
            $results += [PSCustomObject]@{
                SubscriptionID = $subscriptionId
                WorkspaceName = $workspaceName
                TableName = $usage.name.localizedValue
                TableSizeGB = [math]::Round($usage.currentValue / 1024 / 1024 / 1024, 2)
                LastWriteTime = "No Data (REST API)"
            }
        }
        Write-Host "✅ Retrieved data for workspace: $workspaceName" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ ERROR: REST API request failed for $workspaceName." -ForegroundColor Red
        Write-Output "Error: $_" | Out-File -Append -FilePath "LogAnalytics_Error.log"
    }
}

# 6️⃣ EXPORT RESULTS TO CSV
$csvPath = ".\LogAnalyticsWorkspaceSizes_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "`n✅ Export completed: $csvPath" -ForegroundColor Green
