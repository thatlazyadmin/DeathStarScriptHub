<#
.SYNOPSIS
    Audit Microsoft Defender for Endpoint installation on all servers.

.DESCRIPTION
    This script queries Active Directory for all servers.
    It checks if Microsoft Defender for Endpoint is installed on these servers.
    The results are then exported to a CSV file.

.NOTES
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
#>

# Import necessary modules
Import-Module ActiveDirectory

# Suppress warning messages
$ErrorActionPreference = "SilentlyContinue"

# Get all servers from Active Directory
$servers = Get-ADComputer -Filter {OperatingSystem -like '*Server*'} -Property Name,OperatingSystem

# Initialize result array
$results = @()

# Function to check if Defender for Endpoint is installed
function Check-DefenderForEndpoint {
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
            $status = "Not Installed"
        }
        Remove-PSSession -Session $session
    } catch {
        Write-Host "Failed to connect to $ServerName" -ForegroundColor Red
        $status = "Offline or Not Available"
    }

    return $status
}

# Loop through each server and check Defender for Endpoint
foreach ($server in $servers) {
    $defenderStatus = Check-DefenderForEndpoint -ServerName $server.Name
    $result = [PSCustomObject]@{
        ServerName         = $server.Name
        OperatingSystem    = $server.OperatingSystem
        DefenderStatus     = $defenderStatus
    }
    $results += $result
}

# Export results to a CSV file
$results | Export-Csv -Path "DefenderStatusAudit_AllServers.csv" -NoTypeInformation

# Display final summary
Write-Host "Audit complete. Results exported to DefenderStatusAudit_AllServers.csv" -ForegroundColor Green