# Connect to Intune
Connect-MgGraph -Scopes "User.ReadWrite.All", "DeviceManagementManagedDevices.PrivilegedOperations.All"

# Prompt user for group name
$groupName = Read-Host "Enter the group name where machines are located"

# Get available device categories
$categories = Get-IntuneDeviceCategory

# Display categories and allow user selection
$selectedCategories = $categories | Out-GridView -Title "Select Device Categories" -PassThru

# Get devices in the specified group
$groupDevices = Get-IntuneManagedDevice -Filter "devicePhysicalIds/any(id: id eq '$groupName')"

# Assign selected categories to group devices
foreach ($device in $groupDevices) {
    foreach ($category in $selectedCategories) {
        Update-IntuneManagedDevice -managedDeviceId $device.managedDeviceId -deviceCategoryDisplayName $category.displayName
    }
}

# Generate output file
$groupDevices | Export-Csv -Path "C:\Path\To\OutputFile.csv" -NoTypeInformation

Write-Host "Device categories updated and output file created."
