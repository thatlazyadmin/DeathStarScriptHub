# Import the Teams module
Import-Module MicrosoftTeams

# Connect to Microsoft Teams
$credential = Get-Credential
Connect-MicrosoftTeams -Credential $credential

# Get all Teams Voice users
$teamsVoiceUsers = Get-CsOnlineUser | Where-Object { $_.EnterpriseVoiceEnabled -eq $true -and $_.OnPremLineUri -ne $null } 

# Display the UPN and assigned number in green
foreach ($user in $teamsVoiceUsers) {
    Write-Host "UPN: $($user.UserPrincipalName) - Assigned Number: $($user.OnPremLineUri)" -ForegroundColor Green
}

# Disconnect from the Teams session
Disconnect-MicrosoftTeams
