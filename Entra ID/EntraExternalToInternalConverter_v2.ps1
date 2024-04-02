# Created By: Shaun Hardneck (ThatLazyAdmin)
# www.thatlazyadmin.com
# # PowerShell Script: EntraExternalToInternalConverterMenu.ps1
# Requires the Microsoft Graph PowerShell SDK
# Install it using: Install-Module Microsoft.Graph
########################################################################################################################

Import-Module Microsoft.Graph.Users

function Show-Menu {
    param (
        [string]$Title = 'Entra ID External to Internal User Converter Enhanced Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan

    Write-Host "1: List all guest accounts" -ForegroundColor Green
    Write-Host "2: Export all guest accounts to CSV" -ForegroundColor Green
    Write-Host "3: Bulk convert guest accounts from CSV" -ForegroundColor Green
    Write-Host "4: Convert guest accounts from specific domain" -ForegroundColor Green
    Write-Host "Q: Exit" -ForegroundColor Red
}

function List-GuestAccounts {
    $guestUsers = Get-MgUser -Filter "userType eq 'Guest'"
    $guestUsers | Format-Table DisplayName, UserPrincipalName, UserType -AutoSize
}

function Export-GuestAccountsToCSV {
    $guestUsers = Get-MgUser -Filter "userType eq 'Guest'"
    $guestUsers | Export-Csv -Path "./guestUsers.csv" -NoTypeInformation
    Write-Host "All guest users have been exported to guestUsers.csv." -ForegroundColor Yellow
}

function ConvertTo-InternalUser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,
        [Parameter(Mandatory = $true)]
        [string]$NewUPNDomain
    )

    $newUPN = "$UserId@$NewUPNDomain"
    Write-Host "Enter a strong password for the user ($newUPN):" -ForegroundColor Yellow
    $password = Read-Host -AsSecureString
    $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    Update-MgUser -UserId $UserId -UserPrincipalName $newUPN -PasswordProfile @{ForceChangePasswordNextSignIn = $true; Password = $passwordText} -UserType "Member"
    Write-Host "User $UserId has been converted to an internal user with UPN $newUPN." -ForegroundColor Green
}

function BulkConvert-GuestAccountsFromCSV {
    $csvPath = Read-Host "Enter path to CSV file"
    $usersToConvert = Import-Csv -Path $csvPath
    foreach ($user in $usersToConvert) {
        ConvertTo-InternalUser -UserId $user.UserId -NewUPNDomain $user.NewUPNDomain
    }
}

function Convert-GuestAccountsFromDomain {
    $domain = Read-Host "Enter domain"
    $guestUsers = Get-MgUser -Filter "userType eq 'Guest'"
    $domainGuestUsers = $guestUsers | Where-Object { $_.Mail -like "*@$domain" }
    foreach ($user in $domainGuestUsers) {
        $newUPNDomain = Read-Host "Enter the new UPN domain for $($user.DisplayName)"
        ConvertTo-InternalUser -UserId $user.Id -NewUPNDomain $newUPNDomain
    }
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "User.Read.All", "Directory.Read.All" -NoWelcome

do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            List-GuestAccounts
        }
        '2' {
            Export-GuestAccountsToCSV
        }
        '3' {
            BulkConvert-GuestAccountsFromCSV
        }
        '4' {
            Convert-GuestAccountsFromDomain
        }
        'Q' {
            break
        }
        default {
            Write-Host "Invalid option, please try again." -ForegroundColor Red
        }
    }
    pause
}
until ($input -eq 'Q')

# Disconnect from Microsoft Graph
Disconnect-MgGraph