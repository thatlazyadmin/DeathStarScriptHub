# -----------------------------------------------------------------------------------------
# Script Name: Test-EntraHealthConnectivity.ps1
# Created By: Shaun Hardneck | www.thatlazyadmin.com
# Description: This script tests connectivity to essential Microsoft Entra Connect Health
# agent endpoints and required Microsoft Update URLs.
# -----------------------------------------------------------------------------------------

Clear-Host  # Clears the PowerShell window before execution

# Display script header
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Microsoft Entra Health Agent Connectivity Test   " -ForegroundColor Cyan
Write-Host "  Created by: Shaun Hardneck | www.thatlazyadmin.com" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Define categories of required URLs
$requiredUrls = @{
    "Agent Communication (Required for Entra Health Agent)" = @(
        "https://aadconnecthealth.azure.com",
        "https://aadcdn.msftauth.net",
        "https://login.microsoftonline.com",
        "https://management.azure.com",
        "https://graph.microsoft.com",
        "https://secure.aadcdn.microsoftonline-p.com",
        "https://policykeyservice.dc.ad.msft.net"
    );
    "Microsoft Updates (Required for Agent Updates)" = @(
        "https://windowsupdate.com",
        "https://microsoft.com",
        "https://microsoftonline-p.com"
    )
}

Write-Host "Checking Microsoft Entra Health Agent Connectivity..." -ForegroundColor Cyan
Write-Host ""

# Loop through each category and test connectivity
foreach ($category in $requiredUrls.Keys) {
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "$category" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    foreach ($url in $requiredUrls[$category]) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
            Write-Host "  $url - SUCCESS" -ForegroundColor Green
        } catch {
            Write-Host "  $url - FAILED" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Test complete. Review any failed connections and adjust firewall/proxy settings if needed." -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan