# Permanent banner with color
$bannerText = "=================== Microsoft Teams Channel Privacy Update Script ==================="
Write-Host $bannerText -ForegroundColor Cyan

# Import the Microsoft Graph module
# Import-Module Microsoft.Graph

# Function to get available teams
function Get-Teams {
    try {
        $teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -ConsistencyLevel eventual -CountVariable tCount
        return $teams
    } catch {
        Write-Error "Failed to retrieve teams: $_"
        return $null
    }
}

# Function to get channels for a team
function Get-Channels {
    param (
        [string]$TeamId
    )

    try {
        $channels = Get-MgTeamChannel -TeamId $TeamId
        return $channels
    } catch {
        Write-Error "Failed to retrieve channels: $_"
        return $null
    }
}

# Function to update channel privacy
function Update-ChannelPrivacy {
    param (
        [string]$TeamId,
        [string]$ChannelId
    )

    $uri = "https://graph.microsoft.com/v1.0/teams/$TeamId/channels/$ChannelId"
    $body = @{
        membershipType = "private"
    } | ConvertTo-Json

    try {
        Invoke-MgGraphRequest -Uri $uri -Method PATCH -Body $body
        Write-Host "Channel privacy updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to update channel privacy: $_" -ForegroundColor Red
    }
}

# Main script logic
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "ChannelMember.ReadWrite.All"

# Get available teams
$teams = Get-Teams
if ($null -eq $teams) {
    Write-Error "No teams found or failed to retrieve teams."
    exit
}

# Display available teams
Write-Host "Available Teams:" -ForegroundColor Yellow
for ($i = 0; $i -lt $teams.Count; $i++) {
    Write-Host "$($i + 1). $($teams[$i].DisplayName)" -ForegroundColor White
}

# Prompt user to select a team
$teamIndex = Read-Host "Select a team by number" 
if ($teamIndex -lt 1 -or $teamIndex -gt $teams.Count) {
    Write-Error "Invalid selection."
    exit
}
$selectedTeam = $teams[$teamIndex - 1]

# Get channels for the selected team
$channels = Get-Channels -TeamId $selectedTeam.Id
if ($null -eq $channels) {
    Write-Error "No channels found or failed to retrieve channels."
    exit
}

# Display available channels
Write-Host "Available Channels in '$($selectedTeam.DisplayName)':" -ForegroundColor Yellow
for ($j = 0; $j -lt $channels.Count; $j++) {
    Write-Host "$($j + 1). $($channels[$j].DisplayName)" -ForegroundColor White
}

# Prompt user to select a channel
$channelIndex = Read-Host "Select a channel by number"
if ($channelIndex -lt 1 -or $channelIndex -gt $channels.Count) {
    Write-Error "Invalid selection."
    exit
}
$selectedChannel = $channels[$channelIndex - 1]

# Update channel privacy
Update-ChannelPrivacy -TeamId $selectedTeam.Id -ChannelId $selectedChannel.Id

Write-Host "=================== Script Completed ===================" -ForegroundColor Cyan

# Return to subscription selection prompt
Invoke-Command -ScriptBlock {
    param (
        [string]$ScriptPath
    )
    . $ScriptPath
} -ArgumentList $MyInvocation.MyCommand.Path
