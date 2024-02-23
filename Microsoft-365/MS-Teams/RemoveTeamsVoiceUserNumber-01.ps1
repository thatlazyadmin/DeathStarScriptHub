##################################################################################################
#Created By: Shaun Hardneck (ThatLazyAdmin)
#Www.thatlazyadmin.com
#Email: shaun@thatlazyadmin.com

####### Script Start #############################################################################
# Import the Teams PowerShell module
# Ensure the MicrosoftTeams module is installed
Import-Module MicrosoftTeams

# Connect to Microsoft Teams
# This will prompt for credentials to connect to the Teams service
Connect-MicrosoftTeams

# Function to remove a Teams Phone System number from a single user
function Remove-TeamsPhoneNumber {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserName
    )

    try {
        $user = Get-CsOnlineUser -Identity $UserName
        if ($user.EnterpriseVoiceEnabled -and $user.LineUri) {
            $phoneNumber = $user.LineUri -replace 'tel:', ''
            Remove-CsPhoneNumberAssignment -Identity $UserName -PhoneNumber $phoneNumber -PhoneNumberType DirectRouting
            Write-Host "Phone number removed from user: $UserName" -ForegroundColor Green
        } else {
            Write-Host "No Direct Routing phone number assigned to user: $UserName" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}

# Function to remove Teams Phone System numbers from multiple users
function Remove-TeamsPhoneNumbersBulk {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserListPath
    )

    $userNames = Get-Content -Path $UserListPath

    foreach ($userName in $userNames) {
        Remove-TeamsPhoneNumber -UserName $userName
    }
}

# Main script
Write-Host "Select an option:" -ForegroundColor Cyan
Write-Host "1: Remove a telephone number for a single user"
Write-Host "2: Remove telephone numbers for multiple users"
$choice = Read-Host "Enter your choice (1 or 2)"

switch ($choice) {
    "1" {
        $userName = Read-Host "Enter the username to remove the Direct Routing phone number from"
        Remove-TeamsPhoneNumber -UserName $userName
    }
    "2" {
        $userListPath = Read-Host "Enter the path to the file containing the list of usernames"
        Remove-TeamsPhoneNumbersBulk -UserListPath $userListPath
    }
    default {
        Write-Host "Invalid choice. Please run the script again and select either 1 or 2." -ForegroundColor Red
    }
}

# Disconnect from Microsoft Teams session
Disconnect-MicrosoftTeams
