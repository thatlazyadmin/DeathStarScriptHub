Param(
    [Parameter(Mandatory)]
    [string]$NewCategoryName
)

# Permanent banner
Write-Host "========================================"
Write-Host "   Device Category Management Script    "
Write-Host "========================================"

# Change assign device category based on the device ID
# author: Remy Kuster
# website: www.iamsysadmin.eu
# Version: 2.0
# Added parameters so the script doesn't have to be changed every time

# This script allows you to change the category of an Intune managed device.
# Usage: Assign-device-category.ps1 -NewCategoryName [Value]

$ErrorActionPreference = "Stop"

$moduleName = "Microsoft.Graph.Intune"
if (-not (Get-Module -Name $moduleName)) {
    try {
        Write-Host "Module $moduleName not detected, installing module $moduleName"
        Install-Module $moduleName -Scope CurrentUser -Force -AllowClobber
        Write-Host "Module $moduleName installed"
    } catch {
        Write-Error "Failed to install $moduleName. Please close any instances using this module and try again."
        Write-Host "Script will exit!"
        pause
        Exit
    }
} else {
    Write-Host "Module $moduleName detected, no install needed"
}

# Authenticate
try {
    Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All" -ErrorAction Stop -NoWelcome
} catch {
    Write-Host "An error occurred during authentication:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}

$ErrorActionPreference = "Continue"

# Get the new category ID
try {
    $NewCategoryID = (Get-MgDeviceManagementDeviceCategory | Where-Object DisplayName -EQ $NewCategoryName | Select-Object -ExpandProperty Id)
    if (-not $NewCategoryID) {
        throw "Category '$NewCategoryName' not found."
    }
} catch {
    Write-Host "Error finding the new category:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}

# Prompt for Device ID
$DeviceID = Read-Host -Prompt 'Enter Device ID'

# Function to change the device category, with error handling
function Change-DeviceCategory {
    param(
        [Parameter(Mandatory)]
        [string]$DeviceID,
        [Parameter(Mandatory)]
        [string]$NewCategoryID
    )

    $body = @{
        "deviceCategory" = "https://graph.microsoft.com/v1.0/deviceManagement/deviceCategories/$NewCategoryID"
    }

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID" -Body ($body | ConvertTo-Json -Compress)
        Write-Host "Category of device $DeviceID changed successfully to $NewCategoryID" -ForegroundColor Green
    } catch {
        Write-Host "An error occurred during the category update:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "Request Body: $(ConvertTo-Json -Compress $body)" -ForegroundColor Yellow
        Write-Host "Request URL: https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID" -ForegroundColor Yellow
        pause
        exit
    }
}

# Check if the new category isn't already assigned to the device
try {
    $DeviceCategoryCurrent = (Get-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceID | Select-Object -ExpandProperty DeviceCategoryDisplayName)
    if ($NewCategoryName -eq $DeviceCategoryCurrent) {
        Write-Host "Category $NewCategoryName is already assigned to device: $DeviceID" -ForegroundColor Red
    } else {
        Write-Host "Category $NewCategoryName is NOT assigned to device: $DeviceID" -ForegroundColor Yellow
        Write-Host "Adding category $NewCategoryName to device: $DeviceID" -ForegroundColor Yellow
        Change-DeviceCategory -DeviceID $DeviceID -NewCategoryID $NewCategoryID

        # Check if the assignment of the new category is completed
        do {
            $DeviceCategoryCurrent = (Get-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceID | Select-Object -ExpandProperty DeviceCategoryDisplayName)
            Write-Host "Please wait!" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        } until ($DeviceCategoryCurrent -eq $NewCategoryName)

        Write-Host "Category of device $DeviceID is changed to $NewCategoryName" -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking the current category of the device:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}
