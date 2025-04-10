# Define Required Variables
$tenantId = "f"   # Replace with your Azure Tenant ID
$clientId = "2"   # Replace with your App Registration Client ID
$clientSecret = "q"   # Replace with your Client Secret Value

# Retrieve Subscription ID dynamically if not provided
if (-not $subscriptionId -or $subscriptionId -eq "" -or $subscriptionId -eq "<YourCorrectSubscriptionID>") {
    Write-Host "🔹 Retrieving Azure Subscription ID..." -ForegroundColor Yellow
    $subscriptionId = (Get-AzSubscription | Select-Object -ExpandProperty SubscriptionId | Select-Object -First 1)
    if (-not $subscriptionId) {
        Write-Host "❌ Error: No valid subscription found. Ensure you are logged in and have access." -ForegroundColor Red
        exit
    }
}

Write-Host "✅ Using Subscription ID: $subscriptionId" -ForegroundColor Cyan

# Azure Management Resource for Authentication
$resource = "https://management.azure.com/"

# Function to Get Azure Access Token
Function Get-AzureAccessToken {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        resource      = $resource
    }

    # Request Token from Azure AD
    $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" `
        -ContentType "application/x-www-form-urlencoded" -Body $body -ErrorAction Stop

    # Return Access Token
    return $tokenResponse.access_token
}

# Retrieve Access Token
$accessToken = Get-AzureAccessToken
Write-Host "✅ Access Token Retrieved Successfully" -ForegroundColor Green

# API Endpoint for Listing Log Analytics Workspaces
$apiVersion = "2022-10-01"
$workspaceUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.OperationalInsights/workspaces?api-version=$apiVersion"

# Headers for API Request
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

# Invoke API Request
try {
    $response = Invoke-RestMethod -Method Get -Uri $workspaceUri -Headers $headers -ErrorAction Stop
    Write-Host "✅ Log Analytics Workspaces Retrieved Successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error retrieving Log Analytics Workspaces: $_" -ForegroundColor Red
    exit
}

# Debug: Print Raw API Response
Write-Host "🔹 Raw API Response:" -ForegroundColor Yellow
Write-Output $response | ConvertTo-Json -Depth 10

# Process and Format Data for Export
if ($response.value.Count -gt 0) {
    Write-Host "✅ Processing Workspace Data..." -ForegroundColor Green

    # Extract Workspace Details
    $workspaceData = $response.value | ForEach-Object {
        [PSCustomObject]@{
            Name          = $_.name
            ResourceGroup = ($_.id -split "/")[4]
            Location      = $_.location
            WorkspaceId   = $_.properties.customerId
            Sku          = $_.properties.sku.name
            RetentionInDays = $_.properties.retentionInDays
            ProvisioningState = $_.properties.provisioningState
        }
    }

    # Ensure Export Directory Exists
    $exportPath = "C:\Softlib\7.Github\DeathStarScriptHub\Microsoft-Azure\Log Analytics\Workspaces.csv"
    if (!(Test-Path -Path (Split-Path -Path $exportPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $exportPath -Parent) -Force
    }

    # Export to CSV
    $workspaceData | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "✅ Log Analytics Workspaces Exported to: $exportPath" -ForegroundColor Cyan
} else {
    Write-Host "⚠ No Log Analytics Workspaces Found." -ForegroundColor Yellow
}
