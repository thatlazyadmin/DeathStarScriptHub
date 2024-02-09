# Define the AnyDesk application name pattern to search in the list of installed programs
$AnyDeskAppNamePattern = "AnyDesk"

# Use the Get-CimInstance cmdlet to fetch all installed programs. This is compatible with more environments compared to Get-WmiObject.
$InstalledApps = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -match $AnyDeskAppNamePattern }

# Check if AnyDesk is installed
if ($InstalledApps) {
    foreach ($App in $InstalledApps) {
        # Attempt to uninstall AnyDesk
        $UninstallResult = $App | Invoke-CimMethod -MethodName Uninstall

        # Check the result of the uninstallation process
        if ($UninstallResult.ReturnValue -eq 0) {
            Write-Host "AnyDesk has been successfully uninstalled."
        } else {
            Write-Host "Failed to uninstall AnyDesk. Error Code: $($UninstallResult.ReturnValue)"
        }
    }
} else {
    Write-Host "AnyDesk is not installed on this computer." -ForegroundColor Green
}