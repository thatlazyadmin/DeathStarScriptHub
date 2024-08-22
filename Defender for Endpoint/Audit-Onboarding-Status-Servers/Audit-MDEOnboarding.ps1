# Script Name: Audit-MDEOnboarding.ps1
# Created by: Shaun Hardneck
# Description: This script audits all devices from Microsoft Defender for Endpoint to check if they have been onboarded.
#              The results are exported to a CSV file showing device name, OS, OS version, IP address, device type, onboarded status, EDR status, and exposure level.

# Uncomment the lines below to install the Microsoft.Graph module if not already installed
# if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
#     Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
# }

# Uncomment the line below to import the Microsoft.Graph module
# Import-Module Microsoft.Graph -ErrorAction Stop

# Function to connect to Microsoft Graph
function Connect-MicrosoftGraph {
    Write-Host "Please sign in to your Microsoft Graph account..."
    Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "SecurityEvents.Read.All"
}

# Connect to Microsoft Graph
Connect-MicrosoftGraph

# Get all devices from Microsoft Defender for Endpoint
Write-Host "Fetching device data from Microsoft Defender for Endpoint..."
$devices = Get-MgDeviceManagementManagedDevice -All

# Check if we retrieved any devices
if ($devices.Count -eq 0) {
    Write-Host -ForegroundColor Red "No devices found in Microsoft Defender for Endpoint."
    exit
}

Write-Host "Total devices retrieved: $($devices.Count)"

# Initialize an array to store the results
$results = @()

foreach ($device in $devices) {
    Write-Host "Processing Device Name: $($device.DeviceName), OS: $($device.OperatingSystem), Device Type: $($device.DeviceType), Exposure Level: $($device.ExposureLevel)"

    # Get IP address
    $ipAddress = $device.IpAddress
    if ($null -eq $ipAddress) {
        $ipAddress = "N/A"
    }

    # Determine device type based on the OS platform
    $deviceType = $device.OsPlatform
    switch ($deviceType) {
        "Windows10", "Windows11" { $deviceType = "Workstation" }
        "WindowsServer" { $deviceType = "Server" }
        "iOS", "Android" { $deviceType = "Mobile" }
        default { $deviceType = "Unknown" }
    }

    # Get exposure level from device properties
    $exposureLevel = $device.ExposureLevel
    if (-not $exposureLevel) {
        $exposureLevel = "Unknown"
    }

    # Create a custom object for the result
    $result = [PSCustomObject]@{
        DeviceName    = $device.DeviceName
        OS            = $device.OperatingSystem
        OSVersion     = $device.OsVersion
        IPAddress     = $ipAddress
        DeviceType    = $deviceType
        Onboarded     = if ($device.ComplianceState -eq "compliant") { "Yes" } else { "No" }
        EDRStatus     = if ($device.EdrEnabled -eq $true) { "Enabled" } else { "Disabled" }
        ExposureLevel = $exposureLevel
    }

    # Add the result to the array
    $results += $result


# Export the results to a CSV file
$csvPath = "MDE_Onboarding_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host -ForegroundColor Green "Audit completed. Results exported to $csvPath"
Write-Host -ForegroundColor Cyan "Device Name" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "OS" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "OS Version" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "IP Address" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "Device Type" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "Onboarded" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "EDR Status" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Cyan "Exposure Level"
foreach ($result in $results) {
    Write-Host -ForegroundColor Yellow "$($result.DeviceName)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.OS)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.OSVersion)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.IPAddress)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.DeviceType)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.Onboarded)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.EDRStatus)" -NoNewline; Write-Host " | " -NoNewline; Write-Host -ForegroundColor Yellow "$($result.ExposureLevel)"
}