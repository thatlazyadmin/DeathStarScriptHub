<#
.SYNOPSIS
    This script updates the device category for all devices in a specified Azure AD group.

.DESCRIPTION
    The script authenticates an administrator interactively and retrieves the devices in a specified Azure AD group.
    It then updates the device category for each device in the group to a specified category name.

.PARAMETER tenantId
    The tenant ID of the Azure Active Directory.

.PARAMETER groupId
    The ID of the Azure AD group containing the devices to update.

.PARAMETER deviceCategoryName
    The name of the new device category to set for each device.

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Reviewed by: Marcus Burnap
#>

# Prompt for variables
$tenantId = Read-Host -Prompt "Enter your tenant ID"
$groupId = Read-Host -Prompt "Enter your group ID"
$deviceCategoryName = Read-Host -Prompt "Enter the device category name"

# Install Microsoft.Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph -Force
}

# Authenticate and get token
Connect-MgGraph -TenantId $tenantId -Scopes "GroupMember.Read.All", "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome

# Get members of the group
$membersUrl = "https://graph.microsoft.com/v1.0/groups/$groupId/members"
$membersResponse = Invoke-MgGraphRequest -Method Get -Uri $membersUrl
$members = $membersResponse.value

if ($null -eq $members -or $members.Count -eq 0) {
    Write-Output "No members found in the group or failed to retrieve members."
    Disconnect-MgGraph
    exit
}

Write-Output "Retrieved members: $($members.Count)"

# Initialize an array to keep track of updated devices
$updatedDevices = @()

# Update device category for each device
foreach ($member in $members) {
    $deviceId = $member.id
    $deviceName = $member.displayName

    Write-Output "Updating device: Name = $deviceName, ID = $deviceId"

    # Attempt to update the device category directly
    $updateUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/${deviceId}"
    $updateBody = @{
        deviceCategoryDisplayName = $deviceCategoryName
    } | ConvertTo-Json

    try {
        $updateResponse = Invoke-MgGraphRequest -Method Patch -Uri $updateUrl -Body $updateBody -ContentType "application/json"
        Write-Output "Device ${deviceName} (ID: ${deviceId}) updated successfully to category: ${deviceCategoryName}."
        $updatedDevices += @{
            Name = $deviceName
            ID = $deviceId
            NewCategory = $deviceCategoryName
        }
    } catch {
        Write-Output "Failed to update device ${deviceName} (ID: ${deviceId}): $_"
    }
}

# Output the list of updated devices
if ($updatedDevices.Count -gt 0) {
    Write-Output "The following devices have been updated:"
    $updatedDevices | ForEach-Object { Write-Output "Name: $($_.Name), ID: $($_.ID), New Category: $($_.NewCategory)" }
} else {
    Write-Output "No devices were updated."
}

# Disconnect the session
Disconnect-MgGraph
