# Authenticate to Microsoft Defender for Cloud
# You need to replace <your_tenant_id>, <your_client_id>, and <your_client_secret> with your actual values
$tenantId = "<your_tenant_id>"
$clientId = "<your_client_id>"
$clientSecret = "<your_client_secret>"

$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$body = @{
    client_id     = $clientId
    scope         = "https://securitycenter.onmicrosoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body
$accessToken = $response.access_token

# Define the parameters for the Defender for Cloud API call
$apiUrl = "https://api.securitycenter.microsoft.com/api/compliancereports"
$subscriptionId = "<your_subscription_id>"
$resourceGroupName = "<your_resource_group_name>"
$reportName = "CIS_V2"

# Define the columns to export
$columns = "exportedTimestamp,complianceStandard,complianceControl,complianceControlName,controlState,subscriptionId,subscriptionName,resourceGroup,resourceType,resourceName,resourceId,recommendationId,recommendationName,recommendationDisplayName,description,remediationSteps,severity,resourceState,notApplicableReason,azurePortalRecommendationLink"

# Create the request headers with the access token
$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = 'application/json'
}

# Construct the request URL
$requestUrl = "$apiUrl/$subscriptionId/reports/$reportName?api-version=2021-01-01&$columns"

# Send the request to Microsoft Defender for Cloud API
$response = Invoke-RestMethod -Uri $requestUrl -Headers $headers -Method Get

# Output the response
$response
