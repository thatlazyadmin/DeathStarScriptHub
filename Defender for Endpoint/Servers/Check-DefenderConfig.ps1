# Set Execution Policy
Set-ExecutionPolicy Bypass -Scope Process -Force

# Function to Display Messages with Color
function Show-Result {
    param (
        [string]$Message,
        [string]$Status
    )
    switch ($Status) {
        "Good" { Write-Host "[✔] $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[⚠] $Message" -ForegroundColor Yellow }
        "Critical" { Write-Host "[✖] $Message" -ForegroundColor Red }
    }
}

# Banner
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Microsoft Defender Configuration Check" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if Defender is Installed and Running
$DefenderStatus = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
if ($DefenderStatus.Status -ne "Running") {
    Show-Result "Microsoft Defender Antivirus is NOT Running!" "Critical"
    exit
} else {
    Show-Result "Microsoft Defender Antivirus is Running." "Good"
}

# Check if Defender is Managed by GPO
$GPOCheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -ErrorAction SilentlyContinue
if ($GPOCheck) {
    Show-Result "Defender is Managed by Group Policy (GPO)!" "Critical"
} else {
    Show-Result "No Group Policy (GPO) applied to Defender." "Good"
}

# Check if Defender is Managed by Intune (MDM)
$MDMCheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Defender" -ErrorAction SilentlyContinue
if ($MDMCheck) {
    Show-Result "Defender is Managed by Microsoft Intune!" "Critical"
} else {
    Show-Result "No Microsoft Intune (MDM) policies detected." "Good"
}

# Check if Defender for Endpoint (MDE) is Managing Defender
$MDECheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -ErrorAction SilentlyContinue
if ($MDECheck.OnboardingState -eq 1) {
    Show-Result "Microsoft Defender for Endpoint (MDE) is Managing Defender!" "Warning"
} else {
    Show-Result "Defender for Endpoint (MDE) is NOT Managing Defender." "Good"
}

# Get Defender Preferences
$DefenderPrefs = Get-MpPreference

# Check Real-time Protection
if ($DefenderPrefs.DisableRealtimeMonitoring -eq $false) {
    Show-Result "Real-time Protection is Enabled." "Good"
} else {
    Show-Result "Real-time Protection is DISABLED!" "Critical"
}

# Check Cloud Protection Level
if ($DefenderPrefs.CloudBlockLevel -ge 2) {
    Show-Result "Cloud Protection Level is HIGH." "Good"
} else {
    Show-Result "Cloud Protection Level is Low or Disabled!" "Critical"
}

# Check Tamper Protection
$TamperProtection = (Get-MpPreference).DisableTamperProtection
if ($TamperProtection -eq $false) {
    Show-Result "Tamper Protection is Enabled." "Good"
} else {
    Show-Result "Tamper Protection is DISABLED!" "Critical"
}

# Check Attack Surface Reduction (ASR) Rules
$ASRRules = $DefenderPrefs.AttackSurfaceReductionRules_Actions
if ($ASRRules.Count -gt 0) {
    Show-Result "Attack Surface Reduction (ASR) Rules are Configured." "Good"
} else {
    Show-Result "Attack Surface Reduction (ASR) Rules are NOT Configured!" "Warning"
}

# Check Network Protection
if ($DefenderPrefs.EnableNetworkProtection -ge 1) {
    Show-Result "Network Protection is Enabled." "Good"
} else {
    Show-Result "Network Protection is Disabled!" "Warning"
}

# Check Exclusions
$ExclusionPaths = $DefenderPrefs.ExclusionPath
if ($ExclusionPaths.Count -gt 0) {
    Show-Result "Defender has Exclusions Configured. Review Required!" "Warning"
} else {
    Show-Result "No Defender Exclusions Detected." "Good"
}

# Check Brute Force Protection
$BruteForceProtection = $DefenderPrefs.BruteForceProtectionConfiguredState
if ($BruteForceProtection -ge 1) {
    Show-Result "Brute Force Protection is Enabled." "Good"
} else {
    Show-Result "Brute Force Protection is NOT Configured!" "Critical"
}

# Check Defender EDR Mode
$EDRBlockMode = $DefenderPrefs.EDRInBlockMode
if ($EDRBlockMode -eq $true) {
    Show-Result "Endpoint Detection and Response (EDR) in Block Mode is Enabled." "Good"
} else {
    Show-Result "Endpoint Detection and Response (EDR) in Block Mode is Disabled!" "Critical"
}

# Save Output to Log File
$LogFile = "$env:SystemDrive\DefenderConfigCheck.log"
$Results = @"
Microsoft Defender Configuration Report - $(Get-Date)
----------------------------------------------------
Defender Status: $($DefenderStatus.Status)
GPO Managed: $(If ($GPOCheck) {"Yes"} Else {"No"})
Intune Managed: $(If ($MDMCheck) {"Yes"} Else {"No"})
MDE Managed: $(If ($MDECheck.OnboardingState -eq 1) {"Yes"} Else {"No"})
Real-time Protection: $(If ($DefenderPrefs.DisableRealtimeMonitoring -eq $false) {"Enabled"} Else {"DISABLED"})
Cloud Protection: $(If ($DefenderPrefs.CloudBlockLevel -ge 2) {"HIGH"} Else {"Low or Disabled"})
Tamper Protection: $(If ($TamperProtection -eq $false) {"Enabled"} Else {"DISABLED"})
ASR Rules Configured: $(If ($ASRRules.Count -gt 0) {"Yes"} Else {"No"})
Network Protection: $(If ($DefenderPrefs.EnableNetworkProtection -ge 1) {"Enabled"} Else {"Disabled"})
Exclusions Configured: $(If ($ExclusionPaths.Count -gt 0) {"Yes"} Else {"No"})
Brute Force Protection: $(If ($BruteForceProtection -ge 1) {"Enabled"} Else {"NOT CONFIGURED"})
EDR in Block Mode: $(If ($EDRBlockMode -eq $true) {"Enabled"} Else {"DISABLED"})
----------------------------------------------------
"@
$Results | Out-File -FilePath $LogFile -Encoding utf8

Write-Host "`nLog File Generated: $LogFile" -ForegroundColor Cyan
