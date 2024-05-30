$ErrorActionPreference = "Stop"

# First install PowerShell module Microsoft.Graph.Intune if not detected
$moduleName = "Microsoft.Graph.Intune"
if (-not (Get-Module -Name $moduleName)) {
    try {
        Write-Host "Module $moduleName not detected, installing module $moduleName"
        Install-Module $moduleName -Scope CurrentUser -Force
        Write-Host "Module $moduleName installed"
    } catch {
        Write-Error "Failed to install $moduleName"
        Write-Host "Script will exit!"
        pause
        Exit
    }
} else {
    Write-Host "Module $moduleName detected, no install needed"
}

# Authenticate
try {
    Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All" -ErrorAction Stop
} catch {
    Write-Host "An error occurred during authentication:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}

# Function to change the device category, with error handling
function Change-DeviceCategory {
    param(
        [Parameter(Mandatory)]
        [string]$DeviceID,
        [Parameter(Mandatory)]
        [string]$NewCategoryID
    )

    $body = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/deviceManagement/deviceCategories/$NewCategoryID"
    }
    
    try {
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID/deviceCategory/\$ref" -Body ($body | ConvertTo-Json -Compress)
        Write-Host "Category of device $DeviceID changed successfully to $NewCategoryID" -ForegroundColor Green
    } catch {
        Write-Host "An error occurred during the category update:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        pause
        exit
    }
}

# Prompt for Device ID
$DeviceID = Read-Host -Prompt 'Enter Device ID'

# Get the currently assigned category
try {
    $Device = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceID
    $DeviceCategoryCurrent = $Device.DeviceCategoryDisplayName
    Write-Host "Current category of device $DeviceID is $DeviceCategoryCurrent" -ForegroundColor Green
} catch {
    Write-Host "Device not found or error fetching device details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}

# Get available categories
try {
    $Categories = Get-MgDeviceManagementDeviceCategory | Select-Object -ExpandProperty DisplayName
    Write-Host -ForegroundColor Yellow "-----------------------------------"
    Write-Host -ForegroundColor Yellow "|      Available Categories       |"
    Write-Host -ForegroundColor Yellow "-----------------------------------"
    $Categories | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    Write-Host
} catch {
    Write-Host "Error fetching categories:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}

# Prompt for new category
do {
    $NewCategory = Read-Host -Prompt "Enter the category to assign to the device"
    $CategoryExists = Get-MgDeviceManagementDeviceCategory | Where-Object { $_.DisplayName -eq $NewCategory }

    if (-not $CategoryExists) {
        Write-Host "Category: $NewCategory doesn't exist, please enter an available category" -ForegroundColor Red
    } else {
        Write-Host "Category: $NewCategory exists, continue changing category on device" -ForegroundColor Green
    }
} until ($CategoryExists)

$NewCategoryID = $CategoryExists.Id

# Change the device category
Change-DeviceCategory -DeviceID $DeviceID -NewCategoryID $NewCategoryID

# Check if the assignment of the new category is completed
do {
    try {
        $DeviceCategoryCurrent = (Get-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceID).DeviceCategoryDisplayName
        Write-Host "Please wait!" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    } catch {
        Write-Host "Error checking the updated category:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        pause
        exit
    }
} until ($DeviceCategoryCurrent -eq $NewCategory)

Write-Host "Category of $DeviceID is changed to $NewCategory" -ForegroundColor Green
pause
