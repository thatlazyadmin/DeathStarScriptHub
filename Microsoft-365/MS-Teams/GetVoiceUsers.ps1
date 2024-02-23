#Created By: Shaun Hardneck (ThatLazyAdmin)
#Www.thatlazyadmin.com
# Import the Teams module
Import-Module MicrosoftTeams

# Attempt to connect to Microsoft Teams
try {
    Connect-MicrosoftTeams -ErrorAction Stop
} catch {
    Write-Host "Error connecting to Microsoft Teams. Please ensure you are authenticated." -ForegroundColor Red
    exit
}

# Get all Teams Voice users with an assigned phone number
$teamsVoiceUsers = Get-CsOnlineUser | Where-Object { $_.EnterpriseVoiceEnabled -eq $true -and ($_.TelephoneNumber -ne $null -or $_.LineUri -ne $null) }

# Check if any users were found
if ($teamsVoiceUsers.Count -eq 0) {
    Write-Host "No Teams Voice users found with assigned numbers." -ForegroundColor Yellow
} else {
    # Display the UPN and assigned number in green
    Write-Host ******************* Users Found *************************** -ForegroundColor Cyan
    foreach ($user in $teamsVoiceUsers) {
        $assignedNumber = if ($user.TelephoneNumber) { $user.TelephoneNumber } else { $user.LineUri }
        Write-Host "UPN: $($user.UserPrincipalName) - Assigned Number: $assignedNumber" -ForegroundColor Green
    }
}

# Clean up the session
Disconnect-MicrosoftTeams
