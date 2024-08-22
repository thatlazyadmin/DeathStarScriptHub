<#
.SYNOPSIS
    Audit and install Microsoft Defender for Endpoint on the local server.

.DESCRIPTION
    This script checks if Microsoft Defender for Endpoint is installed on the local server.
    It installs it if not present, and generates a success file in the Temp folder if the installation is successful.

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
#>

# Suppress warning messages
$ErrorActionPreference = "SilentlyContinue"

# Function to check and install Defender for Endpoint
function CheckAndInstall-DefenderForEndpoint {
    $status = "Unknown"
    $defender = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Microsoft Defender%'"
    
    if ($defender) {
        $status = "Installed"
    } else {
        # Install Defender for Endpoint
        Write-Host "Installing Microsoft Defender for Endpoint on $env:COMPUTERNAME" -ForegroundColor Yellow
        $installResult = Install-WindowsFeature -Name Windows-Defender-Features -IncludeAllSubFeature -IncludeManagementTools -Verbose
        
        if ($installResult.Success) {
            $status = "Installed (Reboot Required)"
            $successFile = "$env:TEMP\DefenderForEndpoint_Success.txt"
            New-Item -Path $successFile -ItemType File -Force | Out-Null
            Write-Host "Installation successful. Success file created at $successFile" -ForegroundColor Green
        } else {
            $status = "Installation Failed"
            Write-Host "Installation failed on $env:COMPUTERNAME" -ForegroundColor Red
        }
    }

    return $status
}

# Perform the check and installation on the local server
$defenderStatus = CheckAndInstall-DefenderForEndpoint

# Display final summary
Write-Host "Audit and installation complete. Microsoft Defender for Endpoint status: $defenderStatus" -ForegroundColor Green
