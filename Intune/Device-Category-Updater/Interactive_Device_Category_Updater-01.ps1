Connect-MgGraph

function Set-DeviceCategory {
    param(
        [Parameter(Mandatory)]
        [string]$DeviceID,
        [string]$DeviceCategoryID
    )

    Write-Host "Attempting to set device category for device: $DeviceID"

    # Example of updating a property that requires a complex object or correct property name
    $body = @{
        "deviceCategory" = @{  # Hypothetical structure: verify against documentation
            "id" = $DeviceCategoryID
        }
    } | ConvertTo-Json

    $url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceID"

    try {
        $response = Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $body -ContentType "application/json"
        Write-Host "Device category updated successfully for device: $DeviceID"
    } catch {
        Write-Error "Failed to update device category for device: $DeviceID. Error: $_"
    }
}

# Example usage
$deviceID = 'sec-unerd-sales-team-win-devices'  # Actual Device ID
$deviceCategoryID = 'actual-category-id'  # Actual Device Category ID

Set-DeviceCategory -DeviceID $deviceID -DeviceCategoryID $deviceCategoryID
