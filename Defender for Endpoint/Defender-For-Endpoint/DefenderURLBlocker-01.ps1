function Get-AccessToken {
    $TenantId = "<TenantId>"
    $ClientId = "<ClientId>"
    $ClientSecret = "<ClientSecret>"
    $Resource = "https://api.securitycenter.windows.com" # The resource URL
    $TokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    $Body = @{
        grant_type    = "client_credentials"
        resource      = $Resource
        client_id     = $ClientId
        client_secret = $ClientSecret
    }
    $Response = Invoke-RestMethod -Method Post -Uri $TokenEndpoint -Body $Body -ContentType "application/x-www-form-urlencoded"
    return $Response.access_token
}

function Add-BlockedUrl {
    param([string]$Url)
    $apiUrl = "https://api.securitycenter.windows.com/api/indicators" # Correct API endpoint

    $AccessToken = Get-AccessToken
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }

    $body = @{
        action = "AlertAndBlock"
        indicatorValue = $Url
        indicatorType = "Url"
        title = "Blocked URL: $Url"
        description = "This URL was blocked via PowerShell script"
        severity = "High"
    }

    $json = $body | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $json
        Write-Host "Successfully added website to blocked list: $Url" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to add website to blocked list: $_" -ForegroundColor Red
    }
}
