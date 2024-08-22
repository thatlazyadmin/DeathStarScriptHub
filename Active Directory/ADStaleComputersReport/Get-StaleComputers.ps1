<#
.SYNOPSIS
    This script retrieves a list of devices in Active Directory that have not been connected in the last 90 days and exports the results to a CSV file.
.DESCRIPTION
    The script queries Active Directory for all computer objects and checks their 'lastLogonTimestamp'. If a computer has not logged in within the last 90 days, it is added to the result list. The results are exported to a CSV file.
.NOTES
    Created by: Shaun Hardneck
    Date: 07-08-2024
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Get the date 90 days ago
$ninetyDaysAgo = (Get-Date).AddDays(-90)

# Query AD for computer objects and filter by lastLogonTimestamp
$staleComputers = Get-ADComputer -Filter * -Property Name, LastLogonTimestamp | Where-Object {
    $_.LastLogonTimestamp -ne $null -and ([datetime]::FromFileTime($_.LastLogonTimestamp) -lt $ninetyDaysAgo)
}

# Prepare the results for export
$results = $staleComputers | Select-Object Name, @{Name="LastLogonDate";Expression={[datetime]::FromFileTime($_.LastLogonTimestamp)}}

# Ensure the folder exists
$folderPath = "C:\Softlib\ActiveDirectory\ADStaleComputersReport"
if (!(Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
}

# Export the results to a CSV file
$csvPath = "$folderPath\StaleComputers.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output "Stale computer report generated: $csvPath"