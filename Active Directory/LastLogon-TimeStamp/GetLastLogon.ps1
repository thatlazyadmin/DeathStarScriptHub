<#
.SYNOPSIS
    This script pulls the last logon data for a user account from Active Directory.
.DESCRIPTION
    The script retrieves the last logon date for a specified user from Active Directory. 
    It loops through all domain controllers to get the most recent logon information.
.PARAMETER Username
    The username of the account for which to pull the last logon data.
.EXAMPLE
    .\GetLastLogon.ps1 -Username johndoe
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Username
)

# Function to convert last logon timestamp
function Convert-LastLogon {
    param (
        [Parameter(Mandatory = $true)]
        [long]$LastLogonTimestamp
    )
    
    return [DateTime]::FromFileTime($LastLogonTimestamp)
}

# Get all domain controllers
$DomainControllers = Get-ADDomainController -Filter *

# Initialize variable to store the latest logon
$LatestLogon = [DateTime]::MinValue

# Loop through each domain controller to get the last logon
foreach ($DC in $DomainControllers) {
    $User = Get-ADUser -Identity $Username -Server $DC.HostName -Properties LastLogon
    if ($User.LastLogon -gt 0) {
        $LastLogon = Convert-LastLogon -LastLogonTimestamp $User.LastLogon
        if ($LastLogon -gt $LatestLogon) {
            $LatestLogon = $LastLogon
        }
    }
}

if ($LatestLogon -eq [DateTime]::MinValue) {
    Write-Output "No logon information found for user: $Username"
} else {
    Write-Output "The last logon date for user $Username is: $LatestLogon"
}