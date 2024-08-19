<#
.SYNOPSIS
    ASR Rules Audit Script

.DESCRIPTION
    This script allows you to audit ASR rules on either all servers in the domain or a specific server. The script checks if the ASR rules are configured and exports the results to a CSV file.

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
    Contact: Shaun@thatlazyadmin.com

    This script requires the Active Directory module and PowerShell Remoting to be enabled on target servers.
#>

# Import Active Directory Module
Import-Module ActiveDirectory

# ASR Rules to Audit
$asrRules = @(
    @{Name = "Block abuse of exploited vulnerable signed drivers"; GUID = "56a863a9-875e-4185-98a7-b882c64b5ce5"},
    @{Name = "Block Adobe Reader from creating child processes"; GUID = "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c"},
    @{Name = "Block all Office applications from creating child processes"; GUID = "d4f940ab-401b-4efc-aadc-ad5f3c50688a"},
    @{Name = "Block credential stealing from the Windows local security authority subsystem (lsass.exe)"; GUID = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"},
    @{Name = "Block executable content from email client and webmail"; GUID = "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550"},
    @{Name = "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"; GUID = "01443614-cd74-433a-b99e-2ecdc07bfc25"},
    @{Name = "Block execution of potentially obfuscated scripts"; GUID = "5beb7efe-fd9a-4556-801d-275e5ffc04cc"},
    @{Name = "Block JavaScript or VBScript from launching downloaded executable content"; GUID = "d3e037e1-3eb8-44c8-a917-57927947596d"},
    @{Name = "Block Office applications from creating executable content"; GUID = "3b576869-a4ec-4529-8536-b80a7769e899"},
    @{Name = "Block Office applications from injecting code into other processes"; GUID = "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84"},
    @{Name = "Block Office communication application from creating child processes"; GUID = "26190899-1602-49e8-8b27-eb1d0a1ce869"},
    @{Name = "Block persistence through WMI event subscription"; GUID = "e6db77e5-3df2-4cf1-b95a-636979351e5b"},
    @{Name = "Block process creations originating from PSExec and WMI commands"; GUID = "d1e49aac-8f56-4280-b9ba-993a6d77406c"},
    @{Name = "Block rebooting machine in Safe Mode (preview)"; GUID = "33ddedf1-c6e0-47cb-833e-de6133960387"},
    @{Name = "Block untrusted and unsigned processes that run from USB"; GUID = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4"},
    @{Name = "Block use of copied or impersonated system tools (preview)"; GUID = "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb"},
    @{Name = "Block Webshell creation for Servers"; GUID = "a8f5898e-1dc8-49a9-9878-85004b8a61e6"},
    @{Name = "Block Win32 API calls from Office macros"; GUID = "92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b"},
    @{Name = "Use advanced protection against ransomware"; GUID = "c1db55ab-c21a-4637-bb3f-a12568109d35"}
)

# Prompt user to select audit type (single server or all servers)
$auditType = Read-Host "Do you want to audit a single server or all servers? (Enter 'Single' or 'All')"

if ($auditType -eq 'Single') {
    # Prompt for server name
    $serverName = Read-Host "Enter the server name to audit"
    $servers = @($serverName)
} elseif ($auditType -eq 'All') {
    # Get all servers in Active Directory
    $servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} -Property Name | Select-Object -ExpandProperty Name
} else {
    Write-Host "Invalid selection. Please run the script again and select either 'Single' or 'All'." -ForegroundColor Red
    exit
}

# Prepare the output list
$output = @()

# Loop through each server and audit ASR rules
foreach ($server in $servers) {
    Write-Host "Checking server: $server" -ForegroundColor Cyan
    try {
        # Get the ASR rules configured on the server
        $mpPreference = Invoke-Command -ComputerName $server -ScriptBlock { Get-MpPreference } -ErrorAction Stop
        $configuredRules = $mpPreference.AttackSurfaceReductionRules_Ids
        $configuredActions = $mpPreference.AttackSurfaceReductionRules_Actions

        foreach ($rule in $asrRules) {
            # Check if the ASR rule is configured
            $index = $configuredRules.IndexOf($rule.GUID)

            if ($index -ge 0) {
                $status = $configuredActions[$index]
                switch ($status) {
                    1 { $status = "Enabled" }
                    2 { $status = "AuditMode" }
                    6 { $status = "Warn" }
                    0 { $status = "Disabled" }
                    default { $status = "Unknown" }
                }
            } else {
                $status = "Not Configured"
            }

            # Add the result to the output list
            $output += [PSCustomObject]@{
                ServerName = $server
                ASRRuleGUID = $rule.GUID
                ASRRuleName = $rule.Name
                Status = $status
            }
        }
    } catch {
        Write-Host "Failed to connect to $server $_" -ForegroundColor Red
    }
}

# Export the results to a CSV file
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$output | Export-Csv -Path "./ASR_Audit_$timestamp.csv" -NoTypeInformation -Force

Write-Host "ASR audit completed. Results exported to ASR_Audit_$timestamp.csv" -ForegroundColor Green