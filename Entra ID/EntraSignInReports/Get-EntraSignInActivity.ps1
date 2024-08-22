<#
.SYNOPSIS
This script retrieves all sign-in activity for a specified Entra ID user in GCC or GCCH environments using the Microsoft Graph API.

.DESCRIPTION
The script prompts the user for the UPN (User Principal Name) and then uses Microsoft Graph to pull all available sign-in activity, including details such as IP address, device information, location, and status.

.AUTHOR
Shaun Hardneck
www.thatlazyadmin.com

.NOTES
The script requires the Microsoft Graph PowerShell module and appropriate permissions to access sign-in logs.
#>

# Install required modules
$modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Reports")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Force -AllowClobber
    }
    Import-Module $module
}

# Suppress warning messages
$WarningPreference = "SilentlyContinue"

# Function to connect to Microsoft Graph
function Connect-MicrosoftGraph {
    Write-Host "Connecting to Microsoft Graph in US Government Cloud..." -ForegroundColor Cyan
    try {
        Connect-MgGraph -Environment USGov -Scopes "AuditLog.Read.All" -ErrorAction Stop
        Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
    } catch {
        Write-Host "Error: Failed to connect to Microsoft Graph." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Exit
    }
}

# Prompt for UPN
$UPN = Read-Host "Enter the UPN of the user"

# Connect to Microsoft Graph
Connect-MicrosoftGraph

# Fetch sign-in activity for the specified UPN
Write-Host "Fetching sign-in activity for $UPN..." -ForegroundColor Cyan

try {
    $SignInLogs = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UPN'" -All -ErrorAction Stop

    if ($SignInLogs.Count -eq 0) {
        Write-Host "No sign-in activity found for $UPN." -ForegroundColor Yellow
    } else {
        # Display and export the sign-in logs
        $SignInLogs | ForEach-Object {
            $SignIn = $_
            Write-Host "Sign-in Date: $($SignIn.createdDateTime)"
            Write-Host "Status: $($SignIn.status.errorCode) - $($SignIn.status.failureReason)"
            Write-Host "IP Address: $($SignIn.ipAddress)"
            Write-Host "Device ID: $($SignIn.deviceDetail.deviceId)"
            Write-Host "Operating System: $($SignIn.deviceDetail.operatingSystem)"
            Write-Host "Browser: $($SignIn.deviceDetail.browser)"
            Write-Host "Location: $($SignIn.location.city), $($SignIn.location.state), $($SignIn.location.countryOrRegion)"
            Write-Host "-----------------------------" -ForegroundColor DarkGray
        }

        # Export results to CSV
        $csvPath = "$PSScriptRoot\SignInActivity_$($UPN.Replace('@', '_')).csv"
        $SignInLogs | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Sign-in activity exported to $csvPath" -ForegroundColor Green
    }
} catch {
    Write-Host "Error: Failed to fetch sign-in activity." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Disconnect from Microsoft Graph
try {
    Disconnect-MgGraph
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Error: Failed to disconnect from Microsoft Graph." -ForegroundColor Yellow
}

Write-Host "Script completed." -ForegroundColor Cyan