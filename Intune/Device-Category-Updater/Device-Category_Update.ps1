# Install the necessary PowerShell module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    #Install-Module -Name Microsoft.Graph -AllowClobber -Scope CurrentUser -Force
}

# Import the Microsoft Graph module
#Import-Module Microsoft.Graph

# Function to connect to Microsoft Graph
function Connect-Graph {
    $scopes = "DeviceManagementManagedDevices.ReadWrite.All"
    Connect-MgGraph -Scopes $scopes
}

# Function to set the device category
function Set-DeviceCategory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeviceID,
        [Parameter(Mandatory=$true)]
        [string]$DeviceCategoryID
    )

    # Check if connected to Microsoft Graph and connect if not
    if (-not (Get-MgContext)) {
        Connect-Graph
    }

    Write-Host "Attempting to set device category for device: $DeviceID to category ID: $DeviceCategoryID"

    # Correct the endpoint and method according to documentation
    $url = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID"

    $body = @{
        deviceCategory = @{
            id = $DeviceCategoryID
        }
    } | ConvertTo-Json

    try {
        $response = Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $body -ContentType "application/json"
        if ($response.StatusCode -eq 204) {
            Write-Host "Device category updated successfully for device: $DeviceID"
        } else {
            Write-Host "Failed to assign device category. Response status: $($response.StatusCode)"
            Write-Host "Response content: $($response.Content)"
        }
    } catch {
        Write-Host "Failed to assign device category. Error: $($_.Exception.Message)"
    }
}

# Main script execution
try {
    $deviceID = Read-Host -Prompt 'Enter the Device ID'
    $deviceCategoryID = Read-Host -Prompt 'Enter the Device Category ID'
    Set-DeviceCategory -DeviceID $deviceID -DeviceCategoryID $deviceCategoryID
} catch {
    Write-Host "An error occurred: $_"
}