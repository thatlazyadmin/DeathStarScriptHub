<#
.SYNOPSIS
    This script checks if Microsoft Defender for Endpoint's EDR is enabled and set to block mode on the local machine.

.DESCRIPTION
    The Check-EDRBlockMode script verifies the installation of Microsoft Defender for Endpoint and checks the registry 
    settings to determine if EDR in block mode is enabled. It outputs the status based on the registry configuration.

    Author: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.PARAMETER None
    This script does not take any parameters.

.EXAMPLE
    Run the script without any parameters to check the EDR block mode status:
    
    .\Check-EDRBlockMode.ps1
#>

# Check if the Windows Defender ATP service is installed
$service = Get-Service -Name "Sense" -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Host "Microsoft Defender for Endpoint is not installed on this machine." -ForegroundColor Red
    return
}

# Get the EDR Block Mode setting from the registry
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection"
$registryValue = "ForceDefenderPassiveMode"

try {
    $edrBlockMode = Get-ItemProperty -Path $registryPath -Name $registryValue -ErrorAction Stop
    if ($edrBlockMode.ForceDefenderPassiveMode -eq 0) {
        Write-Host "EDR in block mode is enabled." -ForegroundColor Green
    } else {
        Write-Host "EDR in block mode is not enabled." -ForegroundColor Red
    }
} catch {
    Write-Host "EDR in block mode setting is not found in the registry. EDR in block mode might not be configured." -ForegroundColor Yellow
}
