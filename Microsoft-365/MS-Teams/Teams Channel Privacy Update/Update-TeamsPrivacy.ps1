<#
.SYNOPSIS
This script provides an interactive menu for managing Microsoft Teams visibility.
It allows users to list all public Teams and change the visibility of any team from public to private.

.DESCRIPTION
The script connects to Microsoft Teams using the Microsoft Teams PowerShell module.
It offers two main functionalities:
1. List all Public Teams - Displays all teams that are currently set to public visibility.
2. Change Team to Private - Allows the user to change a selected team's visibility from public to private.

The script ensures user-friendly interaction through a looping menu that allows multiple operations during a session.

Created By: Shaun Hardneck
Blog: www.thatlazyadmin.com
#>

function Connect-Teams {
    param (
        [string]$Environment
    )

    Write-Host "Connecting to Microsoft Teams ($Environment environment)..." -ForegroundColor Yellow
    switch ($Environment) {
        "Commercial" {
            Connect-MicrosoftTeams
        }
        "GCC" {
            Connect-MicrosoftTeams -TeamsEnvironmentName "UsGovDoD"
        }
        "GCCH" {
            Connect-MicrosoftTeams -TeamsEnvironmentName "UsGovGCCHigh"
        }
        default {
            Write-Host "Invalid environment specified." -ForegroundColor Red
            exit
        }
    }
}

function List-PublicTeams {
    $PublicTeams = Get-Team | Where-Object {$_.Visibility -eq "Public"}
    if ($PublicTeams.Count -eq 0) {
        Write-Host "No public teams found." -ForegroundColor Green
    } else {
        Write-Host "Listing all public teams:" -ForegroundColor Cyan
        foreach ($Team in $PublicTeams) {
            Write-Host "$($Team.DisplayName) - Visibility: Public" -ForegroundColor White
        }
    }
    Pause
}

function Change-TeamVisibility {
    $Teams = Get-Team
    $TotalTeams = $Teams.Count
    Write-Host "Listing all Teams:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Teams.Count; $i++) {
        Write-Host "$($i + 1). $($Teams[$i].DisplayName) - $($Teams[$i].Visibility)" -ForegroundColor White
    }

    $selectedTeamIndex = Read-Host "Select a Team to change visibility by number (Enter '0' to skip)"
    [int]$selectedTeamIndexInt = 0

    if ([int]::TryParse($selectedTeamIndex, [ref]$selectedTeamIndexInt) -and $selectedTeamIndexInt -gt 0 -and $selectedTeamIndexInt -le $TotalTeams) {
        $selectedTeam = $Teams[$selectedTeamIndexInt - 1]
        Write-Host "You selected Team: $($selectedTeam.DisplayName) with current visibility: $($selectedTeam.Visibility)" -ForegroundColor Yellow
        
        if ($selectedTeam.Visibility -eq "Public") {
            $confirmChange = Read-Host "This Team is Public. Do you want to change it to Private? (Y/N)"
            if ($confirmChange -eq 'Y' -or $confirmChange -eq 'y') {
                Write-Host "Setting Team '$($selectedTeam.DisplayName)' to Private..." -NoNewline
                Set-Team -GroupId $selectedTeam.GroupId -Visibility Private | Out-Null
                Write-Host " Done!" -ForegroundColor Green
            } else {
                Write-Host "No changes made." -ForegroundColor Yellow
            }
        } else {
            Write-Host "This Team is already Private." -ForegroundColor Green
        }
    } else {
        Write-Host "Invalid selection or no changes requested." -ForegroundColor Red
    }
    Pause
}

function Show-Menu {
    while ($true) {
        Write-Host "`nMain Menu:" -ForegroundColor Cyan
        Write-Host "1. List all Public Teams" -ForegroundColor Cyan
        Write-Host "2. Change Team to Private" -ForegroundColor Cyan
        Write-Host "0. Exit" -ForegroundColor Cyan
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" {
                List-PublicTeams
            }
            "2" {
                Change-TeamVisibility
            }
            "0" {
                Write-Host "Exiting..." -ForegroundColor Green
                break
            }
            default {
                Write-Host "Invalid choice, please try again." -ForegroundColor Red
            }
        }
    }
}

# Select environment and connect
Write-Host "Select the environment to connect to:" -ForegroundColor Cyan
Write-Host "1. Commercial" -ForegroundColor Cyan
Write-Host "2. GCC" -ForegroundColor Cyan
Write-Host "3. GCCH" -ForegroundColor Cyan
$envChoice = Read-Host "Enter your choice"
$environment = ""

switch ($envChoice) {
    "1" {
        $environment = "Commercial"
    }
    "2" {
        $environment = "GCC"
    }
    "3" {
        $environment = "GCCH"
    }
    default {
        Write-Host "Invalid choice, exiting script." -ForegroundColor Red
        exit
    }
}

Connect-Teams -Environment $environment
Show-Menu