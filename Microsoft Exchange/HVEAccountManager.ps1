<#
.SYNOPSIS
HVEAccountManager.ps1 - High Volume Email Account Management Tool for Microsoft 365.

.DESCRIPTION
This PowerShell script offers a simple, interactive menu-driven interface for managing High Volume Email (HVE) accounts in Microsoft 365. It allows administrators to perform essential HVE account operations such as listing all HVE accounts, changing the display name of a specific HVE account, removing an HVE account, creating a new HVE account with a specified name and SMTP address, and displaying detailed information about an individual HVE account.

.PREREQUISITES
- Requires the Exchange Online PowerShell Module or Exchange Online V2 module (EXO V2) installed and connected to your Microsoft 365 tenant.
- You must have administrative privileges to manage mail users in your Microsoft 365 tenant.

.USAGE
1. Open PowerShell as an administrator.
2. Connect to your Microsoft 365 Exchange Online session if not already connected.
3. Navigate to the directory containing this script.
4. Run the script by typing: .\HVEAccountManager.ps1
5. Follow the on-screen prompts to select the desired operation.

.NOTES
Author: Shaun Hardneck (ThatLazyAdmin)
Version: 1.0
#GitHub Repo: https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main
#Blog: www.thatlazyadmin.com

For feedback or suggestions, please contact Shaun@thatlazyadmin.com.

#>

function Show-Menu {
    param (
        [string]$Title = 'HVE Account Management Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"

    Write-Host "1: List all HVE Accounts"
    Write-Host "2: Change Display Name of a HVE Account"
    Write-Host "3: Remove a HVE Account"
    Write-Host "4: Create a New HVE Account"
    Write-Host "5: Display an Individual HVE Account with All Details"
    Write-Host "Q: Quit"
}

function List-HVEAccounts {
    # Assuming a cmdlet or a function exists to list HVE Accounts
    Write-Host "Listing all HVE Accounts..."
    Get-MailUser -ResultSize Unlimited | Where {$_.ExternalDirectoryObjectId -ne $null} | Format-Table DisplayName, ExternalEmailAddress, Alias
}

function Change-DisplayName {
    $name = Read-Host "Enter the alias of the HVE Account to change the display name"
    $newDisplayName = Read-Host "Enter the new display name"
    Set-MailUser -Identity $name -DisplayName $newDisplayName
    Write-Host "Display name updated."
}

function Remove-HVEAccount {
    $name = Read-Host "Enter the alias of the HVE Account to remove"
    Remove-MailUser -Identity $name -Confirm:$false
    Write-Host "HVE Account removed."
}

function Create-HVEAccount {
    $name = Read-Host "Enter the name for the new HVE Account"
    $smtpAddress = "$name@yourdomain.com" # Replace yourdomain.com with your actual domain
    New-MailUser -Name $name -ExternalEmailAddress $smtpAddress -Alias $name
    Write-Host "HVE Account created with SMTP Address: $smtpAddress"
}

function Display-HVEAccountDetails {
    $name = Read-Host "Enter the alias of the HVE Account to display details"
    Get-MailUser -Identity $name | Format-List
}

do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            List-HVEAccounts
        }
        '2' {
            Change-DisplayName
        }
        '3' {
            Remove-HVEAccount
        }
        '4' {
            Create-HVEAccount
        }
        '5' {
            Display-HVEAccountDetails
        }
        'Q' {
            return
        }
        default {
            Write-Host "Invalid option, please try again."
        }
    }
    pause
}
while ($input -ne 'Q')
