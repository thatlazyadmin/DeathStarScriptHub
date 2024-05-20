# Permanent banner
Write-Host "==========================================="
Write-Host "           Microsoft Graph Group Devices           "
Write-Host "==========================================="

# Install and import Microsoft.Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
#Import-Module Microsoft.Graph

# Function to get devices in a group
function Get-GroupDevices {
    param (
        [string]$GroupObjectId
    )

    # Connect to Microsoft Graph if not already connected
    $graphConnection = Get-MgUser -UserId "me" -ErrorAction SilentlyContinue
    if (-not $graphConnection) {
        Connect-MgGraph -Scopes "Group.Read.All", "Directory.Read.All"
    }

    # Retrieve group members
    $groupMembers = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$GroupObjectId/members"

    # Filter the devices from the group members
    $devices = $groupMembers.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.device' }

    if ($devices.Count -eq 0) {
        Write-Host "No devices found in the specified group."
    } else {
        Write-Host "Devices in the group:"
        $devices | ForEach-Object {
            Write-Host "Device ID: $($_.id), Device Display Name: $($_.displayName)"
        }
    }
}

# Main script logic
do {
    # Prompt for Group Object ID
    $groupObjectId = Read-Host "Enter the Group Object ID (or type 'exit' to quit)"

    if ($groupObjectId -ne 'exit') {
        # List devices in the specified group
        Get-GroupDevices -GroupObjectId $groupObjectId
    }

} while ($groupObjectId -ne 'exit')

Write-Host "Script execution completed."
