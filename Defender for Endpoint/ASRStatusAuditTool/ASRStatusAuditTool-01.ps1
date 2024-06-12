# Import required module
Import-Module -Name ImportExcel -ErrorAction SilentlyContinue
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "Module 'ImportExcel' is not installed." -ForegroundColor Red
    exit
}

# Function to check if the script is running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure running as Administrator
if (-not (Test-Admin)) {
    Write-Host "Please run this script as an Administrator." -ForegroundColor Red
    exit
}

# Define ASR rules with descriptions and GUIDs
$asrRules = @(
    @{ Name = "Block abuse of exploited vulnerable signed drivers"; GUID = "56a863a9-875e-4185-98a7-b882c64b5ce5"; Description = "Prevents applications from writing vulnerable signed drivers to disk." },
    # Add all other ASR rules here...
)

function Get-ASRRulesFromRegistry {
    param (
        [string]$Path
    )
    try {
        $registryASRRules = Get-ItemProperty -Path $Path -ErrorAction Stop
        return $registryASRRules.PSObject.Properties.Name
    } catch {
        Write-Host "Failed to retrieve ASR rules from registry path: $Path" -ForegroundColor Red
        return $null
    }
}

function DisplayMenu {
    Write-Host "Select an option:"
    Write-Host "1: Generate ASR Compliance Report"
    Write-Host "2: Check ASR Rules from Registry"
    Write-Host "Q: Quit"
}

function GenerateASRComplianceReport {
    $results = Get-MpPreference
    $enabledRules = $results.AttackSurfaceReductionRules_Ids

    $excelData = foreach ($rule in $asrRules) {
        $isConfigured = $enabledRules -contains $rule.GUID
        $status = if ($isConfigured) { "Configured" } else { "Not Configured" }
        $compliance = if ($isConfigured) { "Compliant" } else { "Non-Compliant" }
        [PSCustomObject]@{
            RuleName = $rule.Name
            Description = $rule.Description
            Status = $status
            Compliance = $compliance
        }
    }

    $excelPath = "./ASR_Rules_Compliance_Report.xlsx"
    $excelData | Export-Excel -Path $excelPath -WorksheetName "ASR Rules Status" -AutoSize -BoldTopRow -ConditionalText $(@{Condition = "Not Configured"; Color = "Red"}, @{Condition = "Configured"; Color = "Green"})
    Write-Host "Report generated at $excelPath" -ForegroundColor Green
}

function CheckASRFromRegistry {
    $ASRPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules"
    )
    foreach ($path in $ASRPaths) {
        $asrRulesFromReg = Get-ASRRulesFromRegistry -Path $path
        if ($asrRulesFromReg) {
            foreach ($rule in $asrRulesFromReg) {
                Write-Host "$rule is present in the registry." -ForegroundColor Green
            }
        }
    }
}

do {
    DisplayMenu
    $input = Read-Host "Enter your choice"
    switch ($input) {
        '1' {
            GenerateASRComplianceReport
        }
        '2' {
            CheckASRFromRegistry
        }
        'Q' {
            break
        }
        default {
            Write-Host "Invalid option, please choose again." -ForegroundColor Yellow
        }
    }
} while ($input -ne 'Q')
