<# 
.SYNOPSIS
    This script checks all users in Microsoft Entra ID (Azure AD) for their last password change date 
    and calculates the days remaining before expiry (assuming 90-day expiry). 
    If the expiry is within 7 days, it displays an alert on-screen.

    Author: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Contact: Shaun@thatlazyadmin.com

.DESCRIPTION
    - Connects to Microsoft Entra ID (Azure AD) using Microsoft Graph PowerShell.
    - Retrieves all users and filters out accounts with disabled password expiration.
    - Checks the last password change date and calculates the days remaining.
    - Displays alerts if the password expires within 7 days.

.NOTES
    - Requires Microsoft Graph PowerShell (`Microsoft.Graph`) module.
    - Run the script with a user that has the necessary permissions.

#>

# Import required module
Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph
$cred = Get-Credential
try {
    Connect-MgGraph -Credential $cred -Scopes "User.Read.All"
    Write-Host "`n[+] Connected to Microsoft Graph successfully!" -ForegroundColor Green
} catch {
    Write-Host "[!] Failed to connect to Microsoft Graph. Please check credentials." -ForegroundColor Red
    Exit
}

# Get all users excluding those with password expiration disabled
$users = Get-MgUser -All | Where-Object { $_.PasswordPolicies -ne "DisablePasswordExpiration" }

# Define password expiry settings
$thresholdDays = 7  # Alert threshold
$expiryDays = 90     # Default password expiration period

Write-Host "`n[+] Checking password expiry for users..." -ForegroundColor Cyan

foreach ($user in $users) {
    try {
        # Retrieve password last changed date
        $userDetails = Get-MgUser -UserId $user.Id -Select DisplayName, UserPrincipalName, PasswordLastChangedDateTime
        $pwdLastChanged = $userDetails.PasswordLastChangedDateTime

        # Skip if password last changed date is not available
        if (-not $pwdLastChanged) { continue }
        
        # Calculate days to expiry
        $daysToExpiry = [math]::Round((($pwdLastChanged.AddDays($expiryDays) - (Get-Date)).TotalDays))
        
        if ($daysToExpiry -le $thresholdDays) {
            Write-Host "[!] ALERT: User $($userDetails.DisplayName) ($($userDetails.UserPrincipalName)) password expires in $daysToExpiry days." -ForegroundColor Yellow
        } else {
            Write-Host "[✓] User $($userDetails.DisplayName) ($($userDetails.UserPrincipalName)) password is valid for $daysToExpiry days." -ForegroundColor Green
        }
    } catch {
        Write-Host "[!] Error processing user $($user.DisplayName): $_" -ForegroundColor Red
    }
}

Write-Host "`n[+] Password expiry check completed." -ForegroundColor Cyan