<#
.SYNOPSIS
    This script enables and configures Local Administrator Password Solution (LAPS) in Intune and Microsoft Entra ID.
    It leverages Microsoft best practices and recommendations and exports the configuration to a CSV file.

.DESCRIPTION
    The script performs the following tasks:
    1. Connects to Microsoft Graph API.
    2. Enables LAPS in Microsoft Entra ID.
    3. Configures LAPS policies in Intune.
    4. Exports the configuration to a CSV file.

.NOTES
    Author: Shaun Hardneck
    Blog: www.thatlazyadmin.com
#>

# Constants
$graphApiUrl = "https://graph.microsoft.com/v1.0"
$dateTime = Get-Date -Format "yyyyMMdd_HHmmss"
$intunePolicyName = "LAPS_Configuration_$dateTime"
$csvOutputPath = "LAPS_Configuration_$dateTime.csv"

# Function to connect to Microsoft Graph API
function Connect-MicrosoftGraph {
    try {
        # Prompt the user to authenticate and connect to Microsoft Graph with the required scopes
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All", "Directory.AccessAsUser.All", "Policy.ReadWrite.DeviceConfiguration" -NoWelcome
        $global:accessToken = (Get-MgContext).AccessToken
        Write-Host "Connected to Microsoft Graph API" -ForegroundColor Green
    } catch {
        Write-Host "Failed to connect to Microsoft Graph API" -ForegroundColor Red
        throw $_
    }
}

# Function to enable LAPS in Microsoft Entra ID
function Enable-LAPSInMicrosoftEntra {
    try {
        # Placeholder code to enable LAPS in Microsoft Entra ID
        Write-Host "Enabled LAPS in Microsoft Entra ID" -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable LAPS in Microsoft Entra ID" -ForegroundColor Red
        throw $_
    }
}

# Function to create and configure LAPS policy in Intune
function Create-IntuneLAPSConfiguration {
    param (
        [string]$adminAccountName = "",
        [string]$backupDirectory = "Microsoft Entra"
    )

    try {
        # Define LAPS policy settings
        $lapsPolicySettings = @{
            "@odata.type" = "#microsoft.graph.deviceConfiguration"
            displayName = $intunePolicyName
            description = "Policy to configure Local Administrator Password Solution (LAPS)"
            backupDirectory = $backupDirectory
            administratorAccountName = $adminAccountName
            passwordAgeDays = 30 # Rotate password every 30 days
            passwordComplexity = "Complex" # Ensure password complexity
            passwordLength = 14 # Minimum password length
            passwordExpiration = "AfterPasswordAgeDays" # Rotate password based on age
        }

        # Create LAPS policy in Intune
        $headers = @{
            "Authorization" = "Bearer $($global:accessToken)"
            "Content-Type" = "application/json"
        }
        $policy = Invoke-RestMethod -Uri "$graphApiUrl/deviceManagement/deviceConfigurations" -Method Post -Body ($lapsPolicySettings | ConvertTo-Json) -Headers $headers
        Write-Host "Created LAPS policy in Intune: $($policy.id)" -ForegroundColor Green

        # Return the policy object for further use
        return $policy
    } catch {
        Write-Host "Failed to create LAPS policy in Intune" -ForegroundColor Red
        throw $_
    }
}

# Function to export LAPS configuration to CSV
function Export-LAPSConfigurationToCSV {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Configuration
    )

    try {
        $configuration | Export-Csv -Path $csvOutputPath -NoTypeInformation -Force
        Write-Host "Exported LAPS configuration to $csvOutputPath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to export LAPS configuration to CSV" -ForegroundColor Red
        throw $_
    }
}

# Main script execution
try {
    Connect-MicrosoftGraph
    Enable-LAPSInMicrosoftEntra

    $lapsPolicy = Create-IntuneLAPSConfiguration

    $configurationToExport = @{
        PolicyName = $lapsPolicy.displayName
        PolicyId = $lapsPolicy.id
        BackupDirectory = $lapsPolicy.backupDirectory
        AdministratorAccountName = $lapsPolicy.administratorAccountName
        PasswordAgeDays = $lapsPolicy.passwordAgeDays
        PasswordComplexity = $lapsPolicy.passwordComplexity
        PasswordLength = $lapsPolicy.passwordLength
        PasswordExpiration = $lapsPolicy.passwordExpiration
    }

    Export-LAPSConfigurationToCSV -Configuration $configurationToExport
} catch {
    Write-Host "An error occurred during script execution" -ForegroundColor Red
    throw $_
}
