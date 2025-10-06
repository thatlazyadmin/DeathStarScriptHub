# 1️⃣ CONNECT TO AZURE WITH THE CORRECT TENANT
Write-Host "🔵 Connecting to Azure..." -ForegroundColor Cyan
$ErrorActionPreference = "Stop"

# Define correct Tenant ID (Change this to your actual Tenant ID)
$tenantId = "f8a9f5a5-fbb5-4c50-9f67-84b1899a9f74"  
$subscriptionId = "6052118b-adbb-4504-a41a-e8e1121163fe"

try {
    Disconnect-AzAccount -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # Manually authenticate with correct Tenant ID
    Connect-AzAccount -TenantId $tenantId -UseDeviceAuthentication -ErrorAction Stop
}
catch {
    Write-Host "❌ ERROR: Authentication failed. Please manually run 'Connect-AzAccount'." -ForegroundColor Red
    exit
}

# 2️⃣ FORCE SET SUBSCRIPTION & TENANT
Write-Host "🔄 Switching to Subscription: $subscriptionId ..." -ForegroundColor Yellow
Set-AzContext -SubscriptionId $subscriptionId -TenantId $tenantId | Out-Null

# VERIFY SUBSCRIPTION SWITCH
$context = Get-AzContext
if ($context.Subscription.Id -ne $subscriptionId) {
    Write-Host "❌ ERROR: Subscription did not switch correctly. Stopping script." -ForegroundColor Red
    exit
}
Write-Host "✅ Subscription switched to: $($context.Subscription.Name) ($subscriptionId)" -ForegroundColor Green

# 3️⃣ ACQUIRE AZURE ACCESS TOKEN FOR REST API
try {
    Write-Host "🔑 Acquiring Azure Access Token for REST API..." -ForegroundColor Cyan
    $tokenResponse = Get-AzAccessToken -ResourceUrl "https://management.azure.com" -TenantId $tenantId -ErrorAction Stop
    $token = $tokenResponse.Token

    if (-not $token) {
        throw "Failed to acquire valid access token."
    }
}
catch {
    Write-Host "❌ ERROR: Failed to acquire an Azure access token. Authentication problem." -ForegroundColor Red
    exit
}

Write-Host "✅ Token acquired successfully." -ForegroundColor Green

# 4️⃣ FETCH LOG ANALYTICS WORKSPACES
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.OperationalInsights/workspaces?api-version=2021-12-01"

try {
    Write-Host "📡 Fetching Log Analytics Workspaces..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

    if ($response.value.Count -eq 0) {
        Write-Host "⚠️ No Log Analytics Workspaces found in this subscription!" -ForegroundColor Yellow
        exit
    }

    Write-Host "✅ Retrieved Log Analytics Workspaces Successfully!" -ForegroundColor Green
    $response.value | Format-Table Name, Id, Location, CustomerId, Tags -AutoSize
}
catch {
    Write-Host "❌ ERROR: Failed to retrieve Log Analytics Workspaces." -ForegroundColor Red
    Write-Output "Error: $_" | Out-File -Append -FilePath "LogAnalytics_Error.log"
}
