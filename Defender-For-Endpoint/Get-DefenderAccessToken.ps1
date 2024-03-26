# Your Azure AD details
$TenantId = "<TenantId>" # Replace with your Azure AD Tenant ID
$ClientId = "<ClientId>" # Replace with your Application (Client) ID
$ClientSecret = "<ClientSecret>" # Replace with your Client Secret
$Scope = "https://api.securitycenter.windows.com/.default" # Scope for Microsoft Defender for Endpoint API

# Token endpoint
$TokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

# Prepare the body for the token request
$Body = @{
    client_id = $ClientId
    scope = $Scope
    client_secret = $ClientSecret
    grant_type = "client_credentials"
}

# Send the POST request
$Response = Invoke-RestMethod -Uri $TokenUrl -Method Post -Body $Body -ContentType "application/x-www-form-urlencoded"

# Access token
$Token = $Response.access_token

# Output the access token
Write-Host "Access Token: $Token"
