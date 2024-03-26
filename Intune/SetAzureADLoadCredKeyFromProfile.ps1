# Define registry key path and value details
$regKeyPath = "HKLM\Software\Policies\Microsoft\AzureADAccount"
$valueName = "LoadCredKeyFromProfile"
$valueData = 1
$valueType = "REG_DWORD"

# Check if the registry key already exists
if (Test-Path "Registry::$regKeyPath") {
    Write-Host "Registry key $regKeyPath already exists."
} else {
    # Create the registry key if it does not exist
    New-Item -Path "Registry::$regKeyPath" -Force | Out-Null
    Write-Host "Created registry key $regKeyPath."
}

# Set the registry value
Set-ItemProperty -Path "Registry::$regKeyPath" -Name $valueName -Value $valueData -Type $valueType

Write-Host "Registry value $valueName created with data $valueData under key $regKeyPath."