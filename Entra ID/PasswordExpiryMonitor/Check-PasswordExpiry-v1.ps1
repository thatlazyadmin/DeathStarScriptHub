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

# Ensure the Microsoft Graph module is installed but do not reinstall it every time
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "[!] Microsoft Graph PowerShell module is not installed. Please install it using 'Install-Module Microsoft.Graph'." -ForegroundColor Red
    Exit
}

# Check if the user is already connected to Microsoft Graph
try {
    $graphSession = Get-MgUser -Top 1 -ErrorAction Stop
    Write-Host "[+] Using existing Microsoft Graph session." -ForegroundColor Green
} catch {
    Write-Host "[!] Not connected to Microsoft Graph. Attempting to authenticate..." -ForegroundColor Yellow
    try {
        Connect-MgGraph -Scopes "User.Read.All" -ErrorAction Stop
        Write-Host "[+] Connected to Microsoft Graph successfully!" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to connect to Microsoft Graph. Please check credentials and permissions." -ForegroundColor Red
        Exit
    }
}

# Define password expiry settings
$thresholdDays = 7  # Alert threshold
$expiryDays = 90     # Default password expiration period

Write-Host "`n[+] Retrieving user details from Microsoft Entra ID..." -ForegroundColor Cyan

# Get all users excluding those with password expiration disabled
$users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, PasswordLastChangedDateTime, PasswordPolicies | 
         Where-Object { $_.PasswordPolicies -notcontains "DisablePasswordExpiration" }

Write-Host "`n[+] Checking password expiry for users..." -ForegroundColor Cyan

# Ensure users list is retrieved successfully
if (-not $users) {
    Write-Host "[!] No users retrieved from Microsoft Entra ID. Exiting script." -ForegroundColor Red
    Exit
}

foreach ($user in $users) {
    try {
        # Retrieve password last changed date
        $pwdLastChanged = $user.PasswordLastChangedDateTime

        # Skip if password last changed date is not available
        if (-not $pwdLastChanged) { continue }
        
        # Calculate days to expiry
        $daysToExpiry = [math]::Round((($pwdLastChanged.AddDays($expiryDays) - (Get-Date)).TotalDays))
        
        if ($daysToExpiry -le $thresholdDays) {
            Write-Host "[!] ALERT: User $($user.DisplayName) ($($user.UserPrincipalName)) password expires in $daysToExpiry days." -ForegroundColor Yellow
        } else {
            Write-Host "[✓] User $($user.DisplayName) ($($user.UserPrincipalName)) password is valid for $daysToExpiry days." -ForegroundColor Green
        }
    } catch {
        Write-Host "[!] Error processing user $($user.DisplayName): $_" -ForegroundColor Red
    }
}

Write-Host "`n[+] Password expiry check completed successfully." -ForegroundColor Cyan
