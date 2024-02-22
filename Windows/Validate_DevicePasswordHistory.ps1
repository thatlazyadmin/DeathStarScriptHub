# Define the path to the registry key
$registryPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\DeviceLock"

# Define the name of the property you want to check
$propertyName = "DevicePasswordHistory"

# Retrieve the property value
$propertyValue = (Get-ItemProperty -Path $registryPath -Name $propertyName).$propertyName

# Check if the property value is set to 24
if ($propertyValue -eq 24) {
    Write-Host "The DevicePasswordHistory is correctly set to 24."
} else {
    Write-Host "The DevicePasswordHistory is NOT set to 24. Current value is $propertyValue."
}
