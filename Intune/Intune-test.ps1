# Variables
$tenantId = "your-tenant-id"
$clientId = "your-client-id"
$clientSecret = "your-client-secret"
$scope = "https://graph.microsoft.com/.default"
$groupId = "your-group-id"
$deviceCategoryName = "your-device-category-name"
 
# Get access token
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = $scope
}
$response = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $response.access_token
 
# Get devices in the group
$membersUrl = "https://graph.microsoft.com/beta/groups/$groupId/members"
$headers = @{
    Authorization = "Bearer $token"
}
$membersResponse = Invoke-RestMethod -Method Get -Uri $membersUrl -Headers $headers
$members = $membersResponse.value
 
# Filter only devices
$deviceIds = $members | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.managedDevice' } | Select-Object -ExpandProperty id
 
# Update device category for each device
foreach ($deviceId in $deviceIds) {
    $updateUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId"
    $updateBody = @{
        deviceCategoryDisplayName = $deviceCategoryName
    } | ConvertTo-Json
 
    $updateResponse = Invoke-RestMethod -Method Patch -Uri $updateUrl -Headers $headers -Body $updateBody -ContentType "application/json"
 
    if ($updateResponse -eq $null) {
        Write-Output "Device $deviceId updated successfully."
    } else {
        Write-Output "Failed to update device $deviceId: $updateResponse"
    }
}