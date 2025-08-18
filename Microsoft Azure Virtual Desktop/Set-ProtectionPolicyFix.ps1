<#
.SYNOPSIS
Sets the ProtectionPolicy registry key for DPAPI on domain-joined AVD session hosts to fix token encryption errors (0x80090034).

.DESCRIPTION
This script resolves issues where DPAPI fails to store AAD tokens due to missing DC backup availability by allowing local-only storage.

.AUTHOR
Shaun Hardneck
www.thatlazyadmin.com
#>

# Variables
$regPath   = "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb"
$logPath   = "C:\Softlib\Logs\Set-ProtectionPolicyFix.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Create log folder if it doesn't exist
if (-not (Test-Path "C:\Softlib\Logs")) {
    New-Item -Path "C:\Softlib\Logs" -ItemType Directory -Force | Out-Null
}

"[$timestamp] Starting ProtectionPolicy registry fix..." | Out-File -FilePath $logPath -Append

try {
    $existing = Get-ItemProperty -Path $regPath -Name ProtectionPolicy -ErrorAction SilentlyContinue

    if ($existing) {
        "[$timestamp] ProtectionPolicy already set to $($existing.ProtectionPolicy)" | Out-File $logPath -Append
    } else {
        New-ItemProperty -Path $regPath -Name ProtectionPolicy -PropertyType DWord -Value 1 -Force
        "[$timestamp]ProtectionPolicy key set to 1 successfully." | Out-File -FilePath $logPath -Append
    }
}
catch {
    "[$timestamp]ERROR: $_" | Out-File -FilePath $logPath -Append
    throw
}

"[$timestamp] Script execution complete." | Out-File -FilePath $logPath -Append
