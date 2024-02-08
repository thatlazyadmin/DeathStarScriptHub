# Import the required module
# Import-Module Microsoft.Graph

# Connect to Microsoft Graph with scopes that are typically available for interactive use
Connect-MgGraph -Scopes "Device.Read.All", "Device.ReadWrite.All"

# Calculate the date 60 days ago
$thresholdDateForPurge = (Get-Date).AddDays(-60)

# Retrieve devices
$devicesForPurge = Get-MgDevice | Where-Object { $_.ApproximateLastSignInDateTime -and ($_.ApproximateLastSignInDateTime -lt $thresholdDateForPurge) }

# List devices to be purged
if ($devicesForPurge.Count -gt 0) {
    Write-Host "The following devices have not signed in for more than 60 days and are candidates for purging:" -ForegroundColor Green
    foreach ($device in $devicesForPurge) {
        Write-Host "Device ID: $($device.Id) - Display Name: $($device.DisplayName)"
    }

    # Prompt for confirmation
    Write-Host "Do you want to delete these devices from Entra ID? [Y/N]" -ForegroundColor Green
    $confirmation = Read-Host

    if ($confirmation -eq 'Y') {
        foreach ($device in $devicesForPurge) {
            # Attempt to delete device, handling potential errors or limitations
            try {
                Remove-MgDevice -DeviceId $device.Id
                Write-Host "Deleted device: $($device.DisplayName)" -ForegroundColor Red
            } catch {
                Write-Host "Failed to delete device: $($device.DisplayName). Error: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Operation cancelled by user."
    }
} else {
    Write-Host "No devices found that have not signed in for more than 60 days." -ForegroundColor Green
}

# Disconnect the Graph session
Disconnect-MgGraph