<#
.SYNOPSIS
    This script audits Microsoft Teams client configurations to verify that only authorized external storage providers are enabled. The results are exported to a CSV file with a current date stamp.

    Created by: Shaun Hardneck
    Contact: shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Microsoft Teams using the provided credentials.
    2. Retrieves Teams client configurations.
    3. Verifies the state of external storage providers (Dropbox, Box, Google Drive, ShareFile, Egnyte).
    4. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Audit-TeamsClientConfiguration.ps1
    This example runs the script to audit Microsoft Teams client configurations and verify that only authorized external storage providers are enabled. Results are exported to a CSV file.

.NOTES
    This script is necessary to ensure that only authorized external storage providers are enabled in Microsoft Teams, enhancing the security and compliance posture of the organization.
#>

# Import required modules
# Import-Module MicrosoftTeams -ErrorAction SilentlyContinue

# Connect to Microsoft Teams
try {
    Connect-MicrosoftTeams -Credential (Get-Credential)
    Write-Host "Successfully connected to Microsoft Teams." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Teams. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to audit Teams client configurations
function Audit-TeamsClientConfiguration {
    try {
        $configurations = Get-CsTeamsClientConfiguration | Select-Object AllowDropbox, AllowBox, AllowGoogleDrive, AllowShareFile, AllowEgnyte
        $results = @()

        foreach ($config in $configurations) {
            $results += [PSCustomObject]@{
                AllowDropbox     = $config.AllowDropbox
                AllowBox         = $config.AllowBox
                AllowGoogleDrive = $config.AllowGoogleDrive
                AllowShareFile   = $config.AllowShareFile
                AllowEgnyte      = $config.AllowEgnyte
            }
        }

        if ($results.Count -gt 0) {
            Write-Host "Teams client configurations retrieved." -ForegroundColor Green
            $results | Format-Table AllowDropbox, AllowBox, AllowGoogleDrive, AllowShareFile, AllowEgnyte

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "TeamsClientConfiguration_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No configurations found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve Teams client configurations. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Audit-TeamsClientConfiguration