<#
.SYNOPSIS
    Ensure 'WDigest Authentication' is set to 'Disabled' as per CIS Control 18.4.8 (L1).

.DESCRIPTION
    This script checks and sets the registry key to disable WDigest authentication.
    When WDigest authentication is enabled, Lsass.exe retains a copy of the user's plaintext password in memory,
    where it can be at risk of theft. If this setting is not configured, WDigest authentication is disabled in 
    Windows 8.1 and in Windows Server 2012 R2; it is enabled by default in earlier versions of Windows and Windows Server.
    This script targets Windows 7, Windows Server 2008, and older hosts.

.AUTHOR
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
#>

# Define registry path and property
$regPath = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\WDigest"
$regProperty = "UseLogonCredential"
$desiredValue = 0

# Check if the registry path exists
if (-not (Test-Path $regPath)) {
    # Create the registry path if it does not exist
    New-Item -Path $regPath -Force | Out-Null
}

# Set the registry property to disable WDigest authentication
try {
    $currentValue = Get-ItemProperty -Path $regPath -Name $regProperty -ErrorAction Stop
    if ($currentValue.$regProperty -ne $desiredValue) {
        Set-ItemProperty -Path $regPath -Name $regProperty -Value $desiredValue -PropertyType DWORD -Force
        Write-Output "WDigest Authentication has been set to 'Disabled'."
    } else {
        Write-Output "WDigest Authentication is already set to 'Disabled'."
    }
} catch {
    Set-ItemProperty -Path $regPath -Name $regProperty -Value $desiredValue -PropertyType DWORD -Force
    Write-Output "WDigest Authentication has been set to 'Disabled'."
}
