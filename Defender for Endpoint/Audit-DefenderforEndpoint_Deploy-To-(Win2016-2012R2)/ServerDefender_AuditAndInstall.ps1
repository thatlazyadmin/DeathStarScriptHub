<#
.SYNOPSIS
    Audit and install Microsoft Defender for Endpoint on Windows Server 2016 and 2012 R2 servers.

.DESCRIPTION
    This script queries Active Directory for servers running Windows Server 2016 and 2012 R2.
    It checks if Microsoft Defender for Endpoint is installed on these servers and installs it if not present.
    The results are then exported to a CSV file.

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com

#>

# Import necessary modules
Import-Module ActiveDirectory

# Suppress warning messages
$ErrorActionPreference = "SilentlyContinue"

# Get servers from Active Directory
$servers = Get-ADComputer -Filter {OperatingSystem -like '*Windows Server 2016*' -or OperatingSystem -like '*Windows Server 2012 R2*'} -Property Name,OperatingSystem

# Initialize result array
$results = @()
$installCount = 0

# Function to check and install Defender for Endpoint
function CheckAndInstall-DefenderForEndpoint {
    param (
        [string]$ServerName
    )

    $status = "Unknown"
    try {
        $session = New-PSSession -ComputerName $ServerName -ErrorAction Stop
        $defender = Invoke-Command -Session $session -ScriptBlock {
            Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Microsoft Defender%'"
        }
        if ($defender) {
            $status = "Installed"
        } else {
            # Install Defender for Endpoint
            Write-Host "Installing Microsoft Defender for Endpoint on $ServerName" -ForegroundColor Yellow
            $installResult = Invoke-Command -Session $session -ScriptBlock {
                Install-WindowsFeature -Name Windows-Defender-Features -IncludeAllSubFeature -IncludeManagementTools -Verbose
            }
            if ($installResult.Success) {
                $status = "Installed (Reboot Required)"
                $installCount++
            } else {
                $status = "Installation Failed"
            }
        }
        Remove-PSSession -Session $session
    } catch {
        Write-Host "Failed to connect or install on $ServerName" -ForegroundColor Red
        $status = "Offline or Not Available"
    }

    return $status
}

# Loop through each server and check/install Defender for Endpoint
foreach ($server in $servers) {
    $defenderStatus = CheckAndInstall-DefenderForEndpoint -ServerName $server.Name
    $result = [PSCustomObject]@{
        ServerName         = $server.Name
        OperatingSystem    = $server.OperatingSystem
        DefenderStatus     = $defenderStatus
    }
    $results += $result
}

# Export results to a CSV file
$results | Export-Csv -Path "DefenderForEndpointAudit.csv" -NoTypeInformation

# Display final summary
Write-Host "Audit and installation complete. Results exported to DefenderForEndpointAudit.csv" -ForegroundColor Green
Write-Host "$($installCount) servers had Microsoft Defender for Endpoint installed." -ForegroundColor Green
