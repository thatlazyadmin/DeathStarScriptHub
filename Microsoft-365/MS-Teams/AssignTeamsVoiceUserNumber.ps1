##################################################################################################
#Created By: Shaun Hardneck (ThatLazyAdmin)
#Www.thatlazyadmin.com
#Email: shaun@thatlazyadmin.com

####### Script Start #############################################################################

# Import required modules
Import-Module MicrosoftTeams
Import-Module AzureAD

# Function to check Teams Phone System license
function Check-TeamsPhoneSystemLicense {
    param (
        [string]$Username
    )

    # Connect to AzureAD
    Write-Host "Connecting to AzureAD..." -ForegroundColor Yellow
    $aadSession = Connect-AzureAD

    Write-Host "Retrieving user details..." -ForegroundColor Yellow
    # Retrieve user and their licenses
    $user = Get-AzureADUser -ObjectId $Username

    # Check for Teams Phone System service plan in all licenses
    $hasTeamsPhoneSystem = $false
    foreach ($license in $user.AssignedLicenses) {
        # Get the details of the assigned license
        $licenseDetails = Get-AzureADSubscribedSku | Where-Object { $_.SkuId -eq $license.SkuId }

        # Check each service plan in the license for Teams Phone System
        foreach ($servicePlan in $licenseDetails.ServicePlans) {
            if ($servicePlan.ServicePlanName -match "MCOPSTN" -or $servicePlan.ServicePlanName -match "MCOEV") {
                $hasTeamsPhoneSystem = $true
                Write-Host "Teams Phone System functionality found." -ForegroundColor Green
                break
            }
        }

        if ($hasTeamsPhoneSystem) {
            break
        }
    }

    # Disconnect from AzureAD to clean up the session
    Disconnect-AzureAD -Confirm:$false

    return $hasTeamsPhoneSystem
}

# Function to assign Teams Direct Routing Telephone Number
function Assign-TeamsDirectRoutingNumber {
    param (
        [string]$Username,
        [string]$TelephoneNumber
    )

    # Connect to Microsoft Teams
    Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Yellow
    $teamsSession = Connect-MicrosoftTeams

    # Check if user has Teams Phone System license
    $hasPhoneSystemLicense = Check-TeamsPhoneSystemLicense -Username $Username

    if ($hasPhoneSystemLicense) {
        # Assign the telephone number
        Set-CsPhoneNumberAssignment -Identity $Username -PhoneNumber $TelephoneNumber -PhoneNumberType DirectRouting

        # Display success message
        Write-Host "Telephone number $TelephoneNumber assigned to $Username successfully." -ForegroundColor Green
    } else {
        # Display error message
        Write-Host "User does not have the Teams Phone System functionality. Please assign the correct license and try again." -ForegroundColor Red
    }

    # Disconnect session
    Disconnect-MicrosoftTeams -Confirm:$false
}

# Telephone number format guidance
Write-Host "Please ensure the telephone number is in E.164 format, e.g., +11234567890" -ForegroundColor Cyan

# Main script logic
$Username = Read-Host "Please enter the user's username (UPN)"
$TelephoneNumber = Read-Host "Please enter the telephone number to assign (in E.164 format, e.g., +11234567890)"

Assign-TeamsDirectRoutingNumber -Username $Username -TelephoneNumber $TelephoneNumber