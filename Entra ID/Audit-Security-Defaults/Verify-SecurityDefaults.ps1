<#
.SYNOPSIS
    This script verifies if security defaults are disabled in Microsoft 365 using Microsoft Graph PowerShell.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Microsoft Graph using the provided credentials.
    2. Checks the status of the security defaults policy.
    3. Outputs whether security defaults are enabled or disabled.

.PARAMETER None

.EXAMPLE
    .\Verify-SecurityDefaults.ps1
    This example runs the script to verify if security defaults are disabled and outputs the result.

.NOTES
    This script is necessary to ensure that security defaults are properly managed, enhancing the security posture of the organization.
#>

# Import required modules
# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to verify security defaults
function Verify-SecurityDefaults {
    try {
        $policy = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy -ErrorAction Stop
        if ($policy.IsEnabled -eq $false) {
            Write-Host "Security Defaults is disabled." -ForegroundColor Green
        } else {
            Write-Host "Security Defaults is enabled." -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to retrieve security defaults policy. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Verify-SecurityDefaults