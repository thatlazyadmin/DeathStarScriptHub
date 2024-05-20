$ErrorActionPreference = "SilentlyContinue"

# Permanent banner
Write-Host "==========================================="
Write-Host "           Update Intune Device Category   "
Write-Host "==========================================="

# Install and import Microsoft.Graph and Microsoft.Graph.Intune modules if not already installed
function Import-ModuleWithProgress {
    param (
        [string]$moduleName
    )

    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        Write-Host "Installing $moduleName module..." -ForegroundColor Yellow
        Install-Module $moduleName -Scope CurrentUser -Force
        Write-Host "$moduleName module installed." -ForegroundColor Green
    } else {
        Write-Host "$moduleName module already installed." -ForegroundColor Green
    }

    Import-Module $moduleName
    Write-Host "$moduleName module imported." -ForegroundColor Green
}

Import-ModuleWithProgress -moduleName "Microsoft.Graph"
Import-ModuleWithProgress -moduleName "Microsoft.Graph.Intune"

# Ensure the user is authenticated and connected to Microsoft Graph
Try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "Group.Read.All", "Directory.Read.All", "DeviceManagementManagedDevices.ReadWrite.All"
    Write-Host "Connected to Microsoft Graph." -ForegroundColor Green
} Catch {
    Write-Host "Failed to connect to Microsoft Graph:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

# Color functions to give Write-Output color
function Green {
    process { Write-Host $_ -ForegroundColor Green }
}

function Red {
    process { Write-Host $_ -ForegroundColor Red }
}

function Yellow {
    process { Write-Host $_ -ForegroundColor Yellow }
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
    
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID/deviceCategory/`$ref"

    Try {
        Invoke-MgGraphRequest -Method PUT -Uri $uri -Body ($body | ConvertTo-Json) -ContentType "application/json"
        Write-Host "Successfully changed the category for device: $DeviceID" -ForegroundColor Green
    } Catch {
        if ($_.Exception.Message -like "*User is not authorized to perform this operation*") {
            Write-Host "User is not authorized to perform this operation on device: $DeviceID!" -ForegroundColor Red
            Write-Host "Please check the permissions of the account and try again." -ForegroundColor Red
        } else {
            Write-Host "An error occurred while changing the device category:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}

# Function to get devices in a group
function Get-GroupDevices {
    param (
        [string]$GroupObjectId
    )

    # Retrieve group members
    Try {
        $groupMembers = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$GroupObjectId/members"
    } Catch {
        Write-Host "Failed to retrieve group members:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return @()
    }

    # Filter the devices from the group members
    $devices = $groupMembers.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.device' }

    if ($devices.Count -eq 0) {
        Write-Host "No devices found in the specified group." -ForegroundColor Red
        return @()
    } else {
        Write-Host "Devices in the group:" -ForegroundColor Green
        $devices | ForEach-Object {
            Write-Host "Device ID: $($_.id), Device Display Name: $($_.displayName)" -ForegroundColor Green
        }
        return $devices
    }
}

# Function to get all managed devices in Intune
function Get-ManagedDevices {
    Try {
        $managedDevices = Get-MgDeviceManagementManagedDevice -All
        return $managedDevices
    } Catch {
        Write-Host "Failed to retrieve managed devices:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return @()
    }
}

# Main script logic
do {
    # Prompt for Group Object ID
    $groupObjectId = Read-Host "Enter the Group Object ID (or type 'exit' to quit)"

    if ($groupObjectId -ne 'exit') {
        # List devices in the specified group
        $GroupDevices = Get-GroupDevices -GroupObjectId $groupObjectId

        if ($GroupDevices.Count -gt 0) {
            # Get all managed devices
            $ManagedDevices = Get-ManagedDevices

            if ($ManagedDevices.Count -eq 0) {
                Write-Host "No managed devices found in Intune." -ForegroundColor Red
                continue
            }

            # Get available categories
            $Categories = Get-MgDeviceManagementDeviceCategory | Select-Object DisplayName, Id
            $CategoryList = @()

            Write-Host -ForegroundColor Yellow "-----------------------------------"
            Write-Host -ForegroundColor Yellow "|      Available Categories       |"
            Write-Host -ForegroundColor Yellow "-----------------------------------"

            $Categories | ForEach-Object {
                $CategoryList += $_
                $index = $CategoryList.Count
                Write-Host "$index. $($_.DisplayName)" -ForegroundColor Yellow
            }

            $CategoryIndex = Read-Host -Prompt 'Enter the number corresponding to the category to assign'
            if ($CategoryIndex -notmatch '^\d+$' -or $CategoryIndex -le 0 -or $CategoryIndex -gt $CategoryList.Count) {
                Write-Host "Invalid selection, please run the script again and choose a valid number." -ForegroundColor Red
                pause
                exit
            }

            $SelectedCategory = $CategoryList[$CategoryIndex - 1]
            $NewCategoryID = $SelectedCategory.Id
            $NewCategory = $SelectedCategory.DisplayName

            foreach ($Device in $GroupDevices) {
                $DeviceID = $Device.id
                $DeviceName = $Device.displayName

                # Find the device in managed devices
                $managedDevice = $ManagedDevices | Where-Object { $_.Id -eq $DeviceID }
                if ($managedDevice) {
                    $DeviceCategoryCurrent = $managedDevice.DeviceCategoryDisplayName

                    if ($NewCategory -eq "$DeviceCategoryCurrent") {
                        Write-Host "Category $NewCategory is already assigned to device: $DeviceName." -ForegroundColor Red
                        continue
                    }

                    Write-Host "Changing category for managed device: $DeviceName ($DeviceID)" -ForegroundColor Yellow
                    Change-DeviceCategory -DeviceID $DeviceID -NewCategoryID $NewCategoryID

                    # Check if the assignment of the new category is completed
                    $Success = $false
                    $Attempts = 0
                    do {
                        Start-Sleep -Seconds 10
                        Try {
                            $DeviceCategoryCurrent = (Get-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceID).DeviceCategoryDisplayName
                        } Catch {
                            Write-Host "Failed to retrieve updated category for device: $DeviceID" -ForegroundColor Red
                            Write-Host $_.Exception.Message -ForegroundColor Red
                            continue
                        }
                        if ($DeviceCategoryCurrent -eq $NewCategory) {
                            $Success = $true
                            Write-Host "Category of $DeviceName is changed to $NewCategory" -ForegroundColor Green
                        } else {
                            Write-Host "Please wait, assigning category to $DeviceName... (Attempt $($Attempts + 1))" -ForegroundColor Yellow
                            $Attempts++
                        }
                    } until ($Success -or $Attempts -ge 6)  # Retry up to 6 times

                    if (-not $Success) {
                        Write-Host "Failed to change category for device: $DeviceName after multiple attempts." -ForegroundColor Red
                    }
                } else {
                    Write-Host "Device $DeviceName with ID $DeviceID is not found in managed devices." -ForegroundColor Red
                }
            }

            Write-Host "Category assignment completed for all devices in the group with ID $groupObjectId." -ForegroundColor Green
        }
    }

} while ($groupObjectId -ne 'exit')

Write-Host "Script execution completed."
