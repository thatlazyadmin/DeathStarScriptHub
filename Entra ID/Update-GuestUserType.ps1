# Created By: Shaun Hardneck (ThatLazyAdmin)
# www.thatlazyadmin.com
# PowerShell Script: FetchAndUpdate-GuestUserTypes.ps1

########################################################################################################################
# Connect to Microsoft Entra (formerly Azure AD)
try {
    Connect-AzureAD | Out-Null
    Write-Host "Connected to Microsoft Entra successfully."
}
catch {
    Write-Error "Error connecting to Entra Identity Governance. Please ensure you have the AzureAD module installed and are running PowerShell with the necessary permissions."
    exit
}

# Search for all Guest accounts with UserType 'Guest'
$guestAccounts = Get-AzureADUser -All $true | Where-Object { $_.UserType -eq 'Guest' }

if ($guestAccounts.Count -eq 0) {
    Write-Host "No guest accounts found."
    exit
}

# Display the found Guest accounts with index
Write-Host "Found $($guestAccounts.Count) guest account(s):"
$index = 1
foreach ($account in $guestAccounts) {
    Write-Host "$index. $($account.UserPrincipalName)"
    $index++
}

# Display options for updating UserType in cyan
Write-Host "Choose an option:" -ForegroundColor Cyan
Write-Host "[1] Update UserType for a single Guest user" -ForegroundColor Cyan
Write-Host "[2] Update UserType for all Guest accounts" -ForegroundColor Cyan

# Capture the user's choice
$choice = Read-Host "Enter your choice (1 or 2)"

$updatedAccounts = @()

switch ($choice) {
    '1' {
        # Prompt for the index of the single user to update
        $userIndex = Read-Host "Enter the number of the Guest user to update"
        if ($userIndex -le 0 -or $userIndex -gt $guestAccounts.Count) {
            Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
            exit
        }
        $selectedAccount = $guestAccounts[$userIndex - 1]
        Set-AzureADUser -ObjectId $selectedAccount.ObjectId -UserType "Member"
        $updatedAccounts += $selectedAccount
        Write-Host "Updated UserType for $($selectedAccount.UserPrincipalName) to Member" -ForegroundColor Green
    }
    '2' {
        foreach ($account in $guestAccounts) {
            Set-AzureADUser -ObjectId $account.ObjectId -UserType "Member"
            $updatedAccounts += $account
            Write-Host "Updated UserType for $($account.UserPrincipalName) to Member" -ForegroundColor Green
        }
    }
    default {
        Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
        exit
    }
}

# Export the updated accounts to a text file
$exportPath = "UpdatedUserTypes.txt"
$updatedAccounts | ForEach-Object {
    $user = Get-AzureADUser -ObjectId $_.ObjectId
    "$($user.UserPrincipalName), Member" | Out-File -FilePath $exportPath -Append
}
Write-Host "UserTypes updated successfully. Check '$exportPath' for the list of updated accounts." -ForegroundColor Green