# -----------------------------------------------------------------------------------------
# Script Name: Test-EntraHealthConnectivity.ps1
# Created By: Shaun Hardneck | www.thatlazyadmin.com
# Description: This script tests connectivity to essential Microsoft Entra Connect Health
# agent endpoints to ensure network access is not blocking communication.
# -----------------------------------------------------------------------------------------

Clear-Host  # Clears the PowerShell window before execution

# Display script header
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "     Microsoft Entra Health Agent Connectivity Test" -ForegroundColor Cyan
Write-Host "     Created by: Shaun Hardneck | www.thatlazyadmin.com" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# List of required URLs for Entra Health Agent
$urls = @(
    "https://aadconnecthealth.azure.com",
    "https://aadcdn.msftauth.net",
    "https://login.microsoftonline.com",
    "https://management.azure.com",
    "https://graph.microsoft.com",
    "https://secure.aadcdn.microsoftonline-p.com"
)

Write-Host "Checking Microsoft Entra Health Agent Connectivity..." -ForegroundColor Cyan
Write-Host ""

# Loop through URLs and test connectivity
foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        Write-Host "$url - SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "$url - FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Test complete. Review any failed connections." -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan
