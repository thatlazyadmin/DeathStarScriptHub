<#
.SYNOPSIS
Retrieves a list of all managed Intune devices using Microsoft Graph and exports the device ID, device name, and last signed-in user to a CSV file.

.DESCRIPTION
This script connects to Microsoft Graph using interactive authentication, retrieves a list of managed Intune devices, and exports the details (Device ID, Device Name, and Last Signed-In User) to a CSV file. The script displays the retrieved information in a table format and saves it to "ManagedIntuneDevices.csv".

.PARAMETER None
This script does not take any parameters. It uses interactive authentication to connect to Microsoft Graph.

.NOTES
Author: Shaun Hardneck
Blog: www.thatlazyadmin.com
Date: 2024-05-20

.EXAMPLE
.\Get-ManagedIntuneDevices.ps1

This example runs the script, prompts the user to sign in with their admin credentials, retrieves the list of managed Intune devices, and exports the details to "ManagedIntuneDevices.csv".

#>

# Permanent banner
Write-Host "-------------------------------------------" -ForegroundColor DarkYellow
Write-Host "Intune Managed Devices Retrieval Script" -ForegroundColor DarkYellow
Write-Host "-------------------------------------------" -ForegroundColor DarkYellow

# Function to connect to Microsoft Graph
function Connect-ToGraph {
    try {
        Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -NoWelcome
        Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
    } catch {
        Write-Error "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
        throw $_
    }
}

# Function to get a list of managed Intune devices
function Get-IntuneManagedDevices {
    try {
        $devices = Get-MgDeviceManagementManagedDevice
        return $devices
    } catch {
        Write-Error "Error retrieving Intune managed devices: $_" -ForegroundColor Red
        throw $_
    }
}

# Connect to Microsoft Graph
Connect-ToGraph

# Retrieve and process managed Intune devices
try {
    $devices = Get-IntuneManagedDevices
    if ($devices) {
        $deviceList = $devices | Select-Object Id, DeviceName, @{Name='LastSignedInUser'; Expression={$_.UserDisplayName}}
        $deviceList | Format-Table -AutoSize
        
        # Export to CSV
        $outputFile = "ManagedIntuneDevices.csv"
        $deviceList | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Host "Device list exported to $outputFile" -ForegroundColor Green
    } else {
        Write-Host "No managed devices found."
    }
} catch {
    Write-Error "An error occurred: $_"
}

# Return to subscription selection prompt
Write-Host "Press Enter to return to the subscription selection prompt..." -ForegroundColor DarkYellow
[void][System.Console]::ReadKey($true)
