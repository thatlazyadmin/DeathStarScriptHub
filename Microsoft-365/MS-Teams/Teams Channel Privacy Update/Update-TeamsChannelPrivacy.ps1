# Permanent banner with color
$bannerText = "=================== Microsoft Teams Channel Privacy Update Script ==================="
Write-Host $bannerText -ForegroundColor Cyan

# Attempt to import the necessary modules
try {
    Import-Module Microsoft.Graph.Teams -ErrorAction Stop
} catch {
    Write-Error "Failed to load Microsoft.Graph.Teams module. Please ensure it is installed."
    exit
}

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
        Invoke-MgGraphRequest -Uri $uri -Method PATCH -Body $body -ContentType "application/json"
        Write-Host "Channel privacy updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to update channel privacy: $_" -ForegroundColor Red
    }
}

# Main script logic
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "Group.ReadWrite.All", "ChannelMember.ReadWrite.All" -NoWelcome

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
[int]$teamIndexInt = 0
if (-not [int]::TryParse($teamIndex, [ref]$teamIndexInt) -or $teamIndexInt -lt 1 -or $teamIndexInt -gt $teams.Count) {
    Write-Error "Invalid selection. Please enter a valid number for the team."
    exit
}
$selectedTeam = $teams[$teamIndexInt - 1]

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
[int]$channelIndexInt = 0
if (-not [int]::TryParse($channelIndex, [ref]$channelIndexInt) -or $channelIndexInt -lt 1 -or $channelIndexInt -gt $channels.Count) {
    Write-Error "Invalid selection. Please enter a valid number for the channel."
    exit
}
$selectedChannel = $channels[$channelIndexInt - 1]

# Update channel privacy
Update-ChannelPrivacy -TeamId $selectedTeam.Id -ChannelId $selectedChannel.Id

Write-Host $bannerText -ForegroundColor Cyan # Re-display banner at the end for consistency
Write-Host "Script execution completed." -ForegroundColor Cyan

# Return to subscription selection prompt
Invoke-Command -ScriptBlock {
    param (
        [string]$ScriptPath
    )
    . $ScriptPath
} -ArgumentList $MyInvocation.MyCommand.Path
