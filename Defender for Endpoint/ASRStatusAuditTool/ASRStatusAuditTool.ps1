# Check if ImportExcel module is installed
$moduleName = "ImportExcel"
$module = Get-Module -ListAvailable -Name $moduleName

if (-not $module) {
    Write-Host "Module '$moduleName' is not installed." -ForegroundColor Red
    $installChoice = Read-Host "Do you want to install the '$moduleName' module now? (Y/N)"
    if ($installChoice -eq "Y") {
        try {
            # Attempt to install the module
            Install-Module -Name $moduleName -Scope CurrentUser -Force
            Write-Host "Module '$moduleName' installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to install module '$moduleName'. Please install it manually." -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "The script cannot proceed without the '$moduleName' module. Exiting..." -ForegroundColor Yellow
        exit
    }
} else {
    Write-Host "Module '$moduleName' is already installed." -ForegroundColor Green
}

# Function to check if the script is running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Define message colors for output
$systemMessageColor = "Gray"
$processMessageColor = "Green"
$errorMessageColor = "Red"
$auditMessageColor = "Yellow"
$warningMessageColor = "Magenta"

# Display start message
Write-Host -ForegroundColor $systemMessageColor "Script started`n"

# Test for elevated privileges
Write-Host -ForegroundColor $processMessageColor "Checking for elevated privileges`n"
if (-not (Test-Admin)) {
    Write-Host -ForegroundColor $errorMessageColor "*** ERROR *** - Please re-run the PowerShell environment as Administrator`n"
    exit 1
}

# Define all possible ASR rules based on Microsoft's documentation
$asrRules = @(
    @{ Name = "Block abuse of exploited vulnerable signed drivers"; GUID = "56a863a9-875e-4185-98a7-b882c64b5ce5"; Description = "Prevents applications from writing vulnerable signed drivers to disk." },
    @{ Name = "Block Adobe Reader from creating child processes"; GUID = "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c"; Description = "Prevents Adobe Reader from creating processes to mitigate malware exploits." },
    @{ Name = "Block all Office applications from creating child processes"; GUID = "d4f940ab-401b-4efc-aadc-ad5f3c50688a"; Description = "Blocks Office apps from creating child processes to prevent malware spread." },
    @{ Name = "Block credential stealing from the Windows local security authority subsystem (lsass.exe)"; GUID = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"; Description = "Prevents credential theft by locking down LSASS." },
    @{ Name = "Block executable content from email client and webmail"; GUID = "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550"; Description = "Blocks executable files from propagating via email clients and webmail." },
    @{ Name = "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"; GUID = "01443614-cd74-433a-b99e-2ecdc07bfc25"; Description = "Blocks untrusted or unknown executable files from running." },
    @{ Name = "Block execution of potentially obfuscated scripts"; GUID = "5beb7efe-fd9a-4556-801d-275e5ffc04cc"; Description = "Detects and blocks execution of scripts with suspicious properties." },
    @{ Name = "Block JavaScript or VBScript from launching downloaded executable content"; GUID = "d3e037e1-3eb8-44c8-a917-57927947596d"; Description = "Prevents scripts from launching potentially malicious downloaded content." },
    @{ Name = "Block Office applications from creating executable content"; GUID = "3b576869-a4ec-4529-8536-b80a7769e899"; Description = "Blocks Office apps from creating potentially malicious executable content." },
    @{ Name = "Block Office applications from injecting code into other processes"; GUID = "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84"; Description = "Prevents Office apps from injecting code into other processes." },
    @{ Name = "Block Office communication application from creating child processes"; GUID = "26190899-1602-49e8-8b27-eb1d0a1ce869"; Description = "Prevents Office communication apps from creating child processes." },
    @{ Name = "Block persistence through WMI event subscription"; GUID = "e6db77e5-3df2-4cf1-b95a-636979351e5b"; Description = "Prevents persistence through Windows Management Instrumentation (WMI) event subscription." },
    @{ Name = "Block process creations originating from PSExec and WMI commands"; GUID = "d1e49aac-8f56-4280-b9ba-993a6d77406c"; Description = "Blocks process creations originating from PSExec and WMI commands." },
    @{ Name = "Block rebooting machine in Safe Mode (preview)"; GUID = "33ddedf1-c6e0-47cb-833e-de6133960387"; Description = "Blocks rebooting the machine in Safe Mode." },
    @{ Name = "Block untrusted and unsigned processes that run from USB"; GUID = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4"; Description = "Blocks untrusted and unsigned processes that run from USB." },
    @{ Name = "Block use of copied or impersonated system tools (preview)"; GUID = "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb"; Description = "Blocks the use of copied or impersonated system tools." },
    @{ Name = "Block Webshell creation for Servers"; GUID = "a8f5898e-1dc8-49a9-9878-85004b8a61e6"; Description = "Blocks the creation of Webshells on servers." },
    @{ Name = "Block Win32 API calls from Office macros"; GUID = "92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b"; Description = "Blocks Win32 API calls from Office macros." },
    @{ Name = "Use advanced protection against ransomware"; GUID = "c1db55ab-c21a-4637-bb3f-a12568109d35"; Description = "Provides advanced protection against ransomware." }
)

# Fetch current ASR settings from Windows Defender
$results = Get-MpPreference

# Compile all ASR rules from the registry and compare with the defined ASR rules
$enabledRules = $results.AttackSurfaceReductionRules_Ids

# Prepare data for export to Excel
$excelData = foreach ($rule in $asrRules) {
    $isConfigured = $enabledRules -contains $rule.GUID
    $status = if ($isConfigured) { "YES" } else { "NO" }
    $compliance = if ($isConfigured) { "YES" } else { "NO" }
    [PSCustomObject]@{
        RuleName = $rule.Name
        Description = $rule.Description
        Configured = $status
        Compliant = $compliance
    }
}

# Export to Excel
$excelPath = "./ASR_Rules_Compliance_Report.xlsx"
$excelData | Export-Excel -Path $excelPath -WorksheetName "ASR Rules Status" -AutoSize -BoldTopRow

# Display completion message
Write-Host -ForegroundColor $systemMessageColor "`nScript completed. Report generated at $excelPath`n"
