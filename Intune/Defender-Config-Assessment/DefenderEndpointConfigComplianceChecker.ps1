# Define the script name, author, and synopsis for the banner
$scriptName = "DefenderConfigAssessment"
$author = "Created by: Shaun Hardneck"
$contact = "Contact: Shaun@thatlazyadmin.com"
$blog = "Blog: www.thatlazyadmin.com"
$synopsis = @"
Script Name: $scriptName
Author: $author
Contact: $contact
Blog: $blog

Synopsis:
This script connects to Microsoft Graph and retrieves the configuration settings for Microsoft Defender for Endpoint, including antivirus settings and Attack Surface Reduction (ASR) rules. It evaluates these settings against Microsoft's best practices and exports the results to a CSV file for analysis. The purpose of this script is to help administrators ensure that their Defender for Endpoint configurations are aligned with recommended security practices.
"@

# Display the banner
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host $synopsis -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Function to connect to Microsoft Graph
function Connect-Graph {
    try {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        $WarningPreference = 'SilentlyContinue'
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All" -NoWelcome | Out-Null
        $WarningPreference = 'Continue'
        Write-Host "Connected to Microsoft Graph successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to connect to Microsoft Graph. Exiting script." -ForegroundColor Red
        exit
    }
}

# Function to get all device configuration profiles
function Get-DeviceConfigurationProfiles {
    Write-Host "Retrieving device configuration profiles from Intune..." -ForegroundColor Yellow
    $profiles = Get-MgDeviceManagementDeviceConfiguration -All
    return $profiles
}

# Function to get Defender for Endpoint ASR rules and Antivirus settings
function Get-DefenderConfiguration {
    Write-Host "Retrieving Defender for Endpoint configuration..." -ForegroundColor Yellow
    $defenderConfig = Get-MpPreference
    return $defenderConfig
}

# Function to map ASR rule values to their descriptions
function Map-ASRValue {
    param (
        [int]$value
    )

    switch ($value) {
        0 { return "Not configured or Disabled" }
        1 { return "Block" }
        2 { return "Audit" }
        6 { return "Warn" }
        default { return "Unknown" }
    }
}

# Function to map general settings values to their descriptions
function Map-SettingValue {
    param (
        [string]$setting,
        [int]$value
    )

    switch ($setting) {
        "MAPSReporting" {
            switch ($value) {
                0 { return "Disabled" }
                1 { return "Basic" }
                2 { return "Advanced" }
                default { return "Unknown" }
            }
        }
        default { return $value }
    }
}

# Function to evaluate configuration against best practices
function Evaluate-DefenderConfiguration {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$config
    )
    
    $evaluationResults = @()

    # Define best practices
    $bestPractices = @{
        "CloudProtection" = @{ Setting = "MAPSReporting"; Value = "Advanced" }
        "SampleSubmission" = @{ Setting = "SubmitSamplesConsent"; Value = "Always" }
        "BlockAtFirstSeen" = @{ Setting = "DisableBlockAtFirstSeen"; Value = 0 }
        "IOAVProtection" = @{ Setting = "DisableIOAVProtection"; Value = 0 }
        "CloudBlockLevel" = @{ Setting = "CloudBlockLevel"; Value = "High" }
        "RealtimeMonitoring" = @{ Setting = "DisableRealtimeMonitoring"; Value = 0 }
        "BehaviorMonitoring" = @{ Setting = "DisableBehaviorMonitoring"; Value = 0 }
        "ScriptScanning" = @{ Setting = "DisableScriptScanning"; Value = 0 }
        "RemovableDriveScanning" = @{ Setting = "DisableRemovableDriveScanning"; Value = 0 }
        "PUAProtection" = @{ Setting = "PUAProtection"; Value = "Enabled" }
        "ArchiveScanning" = @{ Setting = "DisableArchiveScanning"; Value = 0 }
        "EmailScanning" = @{ Setting = "DisableEmailScanning"; Value = 0 }
        "ControlledFolderAccess" = @{ Setting = "EnableControlledFolderAccess"; Value = "Enabled" }
        "NetworkProtection" = @{ Setting = "EnableNetworkProtection"; Value = "Enabled" }
        "ExploitProtection" = @{ Setting = "ProcessMitigation"; Value = "Configured" }
    }

    # Define ASR rule names and IDs
    $asrRules = @{
        "56a863a9-875e-4185-98a7-b882c64b5ce5" = "Block abuse of exploited vulnerable signed drivers"
        "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c" = "Block Adobe Reader from creating child processes"
        "d4f940ab-401b-4efc-aadc-ad5f3c50688a" = "Block all Office applications from creating child processes"
        "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" = "Block credential stealing from the Windows local security authority subsystem (lsass.exe)"
        "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550" = "Block executable content from email client and webmail"
        "01443614-cd74-433a-b99e-2ecdc07bfc25" = "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"
        "5beb7efe-fd9a-4556-801d-275e5ffc04cc" = "Block execution of potentially obfuscated scripts"
        "d3e037e1-3eb8-44c8-a917-57927947596d" = "Block JavaScript or VBScript from launching downloaded executable content"
        "3b576869-a4ec-4529-8536-b80a7769e899" = "Block Office applications from creating executable content"
        "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84" = "Block Office applications from injecting code into other processes"
        "26190899-1602-49e8-8b27-eb1d0a1ce869" = "Block Office communication application from creating child processes"
        "e6db77e5-3df2-4cf1-b95a-636979351e5b" = "Block persistence through WMI event subscription"
        "d1e49aac-8f56-4280-b9ba-993a6d77406c" = "Block process creations originating from PSExec and WMI commands"
        "33ddedf1-c6e0-47cb-833e-de6133960387" = "Block rebooting machine in Safe Mode (preview)"
        "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4" = "Block untrusted and unsigned processes that run from USB"
        "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb" = "Block use of copied or impersonated system tools (preview)"
        "a8f5898e-1dc8-49a9-9878-85004b8a61e6" = "Block Webshell creation for Servers"
        "92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b" = "Block Win32 API calls from Office macros"
        "c1db55ab-c21a-4637-bb3f-a12568109d35" = "Use advanced protection against ransomware"
    }

    foreach ($bp in $bestPractices.GetEnumerator()) {
        $setting = $bp.Value.Setting
        $expectedValue = $bp.Value.Value
        $actualValue = Map-SettingValue -setting $setting -value $config.$setting

        $result = [PSCustomObject]@{
            Setting       = $setting
            ExpectedValue = $expectedValue
            ActualValue   = $actualValue
            Compliant     = $actualValue -eq $expectedValue
        }

        $evaluationResults += $result
    }

    foreach ($rule in $asrRules.GetEnumerator()) {
        $ruleId = $rule.Key
        $ruleName = $rule.Value
        $actualValueCode = if ($config.AttackSurfaceReductionRules_Ids -contains $ruleId) { 1 } else { 0 }
        $expectedValue = "Enabled"
        $actualValue = Map-ASRValue -value $actualValueCode

        $result = [PSCustomObject]@{
            Setting       = $ruleName
            ExpectedValue = $expectedValue
            ActualValue   = $actualValue
            Compliant     = $actualValue -eq $expectedValue
        }

        $evaluationResults += $result
    }

    return $evaluationResults
}

# Function to export results to CSV
function Export-Results {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]$results,
        [Parameter(Mandatory=$true)]
        [string]$outputPath
    )

    Write-Host "Exporting results to CSV..." -ForegroundColor Yellow
    $results | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "Results exported to $outputPath" -ForegroundColor Green
}

# Main script execution
try {
    # Connect to Microsoft Graph
    Connect-Graph 2>&1 | Out-Null

    # Get device configuration profiles
    $profiles = Get-DeviceConfigurationProfiles

    # Get Defender configuration
    $defenderConfig = Get-DefenderConfiguration

    # Evaluate configuration
    $evaluationResults = Evaluate-DefenderConfiguration -config $defenderConfig

    # Export results
    $outputPath = "DefenderConfigurationAssessmentResults.csv"
    Export-Results -results $evaluationResults -outputPath $outputPath

    Write-Host "Assessment completed successfully." -ForegroundColor Green

} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
