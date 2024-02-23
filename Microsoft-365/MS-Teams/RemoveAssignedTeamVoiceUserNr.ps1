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

# Function to remove a Teams Phone System number from a user
function Remove-TeamsPhoneNumber {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserName
    )

    try {
        # Fetch the user's Teams licensing information
        $user = Get-CsOnlineUser -Identity $UserName

        # Check if the user has a phone number assigned
        if ($user.EnterpriseVoiceEnabled -and $user.LineUri) {
            # Extract the phone number and ensure correct format
            $phoneNumber = $user.LineUri -replace 'tel:', ''

            # Diagnostic output to verify phone number format
            Write-Host "Attempting to remove phone number: $phoneNumber from user: $($user.DisplayName)" -ForegroundColor Cyan

            # Removing the Teams Phone System number
            # Adjust the PhoneNumberType to 'DirectRouting' based on the error message
            Remove-CsPhoneNumberAssignment -Identity $UserName -PhoneNumber $phoneNumber -PhoneNumberType DirectRouting

            Write-Host "Teams Phone System number removed from user: $($user.DisplayName)" -ForegroundColor Green
        }
        else {
            Write-Host "No Teams Phone System number assigned to user: $($user.DisplayName)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}

# Prompt for the username in cyan
Write-Host "Enter the username of the person to remove the Teams Phone System number from:" -ForegroundColor Cyan
$userName = Read-Host

# Call the function to remove the phone number
Remove-TeamsPhoneNumber -UserName $userName

# Disconnect from Microsoft Teams session
Disconnect-MicrosoftTeams