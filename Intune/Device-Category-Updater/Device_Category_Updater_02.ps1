<#
.SYNOPSIS
    Updates the Intune device category for devices in a specified group using Azure App Registration.

.DESCRIPTION
    Uses Azure App Registration for authentication and updates the Intune device category.

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
#>

Import-Module Microsoft.Graph.Intune
Import-Module MSAL.PS

# Azure App Registration credentials
$applicationId = "92c7dedb-626a-416b-bbcc-424d559b9e59"
$tenantId = "f8a9f5a5-fbb5-4c50-9f67-84b1899a9f74"
$clientSecret = "d88d9d03-5db8-402b-8189-d17cae7d22a2"

function Connect-ToGraph {
    $token = Get-MsalToken -ClientId $applicationId -TenantId $tenantId -ClientSecret $clientSecret -Scopes "https://graph.microsoft.com/.default"
    Connect-MgGraph -AccessToken $token.AccessToken
}

function Get-UserInput {
    param ([string]$PromptMessage)
    return Read-Host -Prompt $PromptMessage
}

# Additional functions as previously described...

# Main script execution
try {
    Connect-ToGraph
    $groupName = Get-UserInput -PromptMessage "Enter the group name where devices are located:"
    $deviceCategoryName = Get-UserInput -PromptMessage "Enter the device category name:"
    $groupId = Get-GroupId -GroupName $groupName
    $devices = Get-GroupDevices -GroupId $groupId
    $deviceCategoryId = Get-DeviceCategoryId -DeviceCategoryName $deviceCategoryName
    Update-DeviceCategories -Devices $devices -DeviceCategoryName $deviceCategoryName -DeviceCategoryId $deviceCategoryId
    Write-Host "Device category update completed."
} catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
} finally {
    exit
}