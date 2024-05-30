# Script Name: DefenderHighRiskDeviceActivityReport.ps1

# Ensure the necessary module is installed
$Module = Get-InstalledModule ExchangeOnlineManagement -ErrorAction SilentlyContinue
if (-not $Module -or $Module.Version -lt "3.2.0") { 
    Write-Host "Exchange Online PowerShell V3.2.0 module is not available or outdated" -ForegroundColor Yellow 
    $Confirm = Read-Host "Are you sure you want to install the module? [Y] Yes [N] No" 
    if ($Confirm -match "[yY]") { 
        Write-Host "Installing Exchange Online PowerShell module version 3.2.0" 
        Install-Module -Name ExchangeOnlineManagement -Force
    } else { 
        Write-Host "EXO V3.2.0 module is required to connect to Exchange Online. Please install the module using the Install-Module ExchangeOnlineManagement cmdlet." 
        Exit 
    } 
}

# Import the module
Import-Module ExchangeOnlineManagement

# Connect to Security & Compliance Center using interactive login
$UserPrincipalName = "shaun.hardneck@urbannerd-consulting.com"
Write-Host "Connecting to Security and Compliance PowerShell..."
try {
    Connect-IPPSSession -UserPrincipalName $UserPrincipalName -ErrorAction Stop
} catch {
    Write-Error "Failed to connect to Security & Compliance Center. Error: $_"
    exit 1
}

# Define function to get high-risk devices
function Get-HighRiskDevices {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $uri = "https://api.security.microsoft.com/api/machines?riskScore=high"
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
    }

    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
    return $response.value
}

# Define function to get recent activity for a device
function Get-DeviceRecentActivity {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $true)]
        [string]$DeviceId
    )

    $uri = "https://api.security.microsoft.com/api/machines/$DeviceId/timeline"
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
    }

    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
    return $response.value
}

# Function to print output with color
function Write-ColoredOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Color = "White"
    )

    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Main script
try {
    $AccessToken = ($global:EXOSession).AuthToken

    $HighRiskDevices = Get-HighRiskDevices -AccessToken $AccessToken

    foreach ($device in $HighRiskDevices) {
        Write-ColoredOutput -Message "Device Name: $($device.computerDnsName)" -Color "Cyan"
        Write-ColoredOutput -Message "Risk Score: $($device.riskScore)" -Color "Red"
        Write-ColoredOutput -Message "Detected Threats: $($device.threats)" -Color "Yellow"

        $RecentActivity = Get-DeviceRecentActivity -AccessToken $AccessToken -DeviceId $device.id

        foreach ($activity in $RecentActivity) {
            Write-ColoredOutput -Message "Activity Time: $($activity.timestamp)" -Color "Green"
            Write-ColoredOutput -Message "Activity Type: $($activity.eventType)" -Color "Cyan"
            Write-ColoredOutput -Message "Activity Details: $($activity.details)" -Color "Yellow"
        }

        Write-ColoredOutput -Message "-------------------------------------" -Color "White"
    }
}
catch {
    Write-ColoredOutput -Message "An error occurred: $_" -Color "Red"
}
finally {
    if ($global:EXOSession) {
        Remove-PSSession -Session $global:EXOSession
    }
}
