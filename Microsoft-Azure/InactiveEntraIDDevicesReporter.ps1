# Import the required module
# Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Device.Read.All"

# Calculate the date 60 days ago
$thresholdDate = (Get-Date).AddDays(-60)

# Retrieve devices
$devices = Get-MgDevice

# Filter devices based on ApproximateLastSignInDateTime
$filteredDevices = $devices | Where-Object { $_.ApproximateLastSignInDateTime -and ($_.ApproximateLastSignInDateTime -lt $thresholdDate) }

# Prepare data for export
$exportData = foreach ($device in $filteredDevices) {
    # Handle null or empty Manufacturer and Model
    $manufacturer = if ([string]::IsNullOrWhiteSpace($device.Manufacturer)) { "Unknown" } else { $device.Manufacturer }
    $model = if ([string]::IsNullOrWhiteSpace($device.Model)) { "Unknown" } else { $device.Model }

    # Create a custom object for each device using New-Object
    $properties = @{
        DeviceId = $device.Id
        DisplayName = $device.DisplayName
        OperatingSystem = $device.OperatingSystem
        OperatingSystemVersion = $device.OperatingSystemVersion
        IsCompliant = $device.IsCompliant
        IsManaged = $device.IsManaged
        Manufacturer = $manufacturer
        Model = $model
        TrustType = $device.TrustType
        ApproximateLastSignIn = $device.ApproximateLastSignInDateTime
    }
    $obj = New-Object -TypeName PSObject -Property $properties
    
    # Output the custom object
    $obj
}

# Check if there's any data to export
if ($exportData) {
    # Export data to a CSV file
    $exportData | Export-Csv -Path "InactiveDevicesPast60Days.csv" -NoTypeInformation
    Write-Host "Inactive device information with additional details exported to InactiveDevicesPast60Days.csv"
} else {
    Write-Host "No inactive devices found past 60 days." -ForegroundColor Green
}

# Disconnect the Graph session
Disconnect-MgGraph
