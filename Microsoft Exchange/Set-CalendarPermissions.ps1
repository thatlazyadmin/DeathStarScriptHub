#CreatedBy: Shaun Hardneck (ThatLazyAdmin)
#Blog: www.thatlazyadmin.com
#GitHub: https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main

# PowerShell script to set calendar permissions for a user's mailbox in Exchange Online

# Function to connect to Exchange Online
function Connect-ExchangeOnlineSession {
    # Check if the user is already connected to Exchange Online
    try {
        Get-ExoMailbox -Identity $env:USERNAME -ErrorAction Stop > $null
        Write-Host "Already connected to Exchange Online." -ForegroundColor Green
    } catch {
        # Prompt for Exchange Online connection
        try {
            Write-Host "Attempting to connect to Exchange Online. Please enter your credentials." -ForegroundColor Yellow
            Connect-ExchangeOnline -ShowBanner:$false
            Write-Host "Connected to Exchange Online successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to connect to Exchange Online. Please check your credentials and try again." -ForegroundColor Red
            exit
        }
    }
}

# Invoke the function to connect to Exchange Online
Connect-ExchangeOnlineSession

# Define permission levels using an ordered dictionary to maintain order
$permissionLevels = [ordered]@{
    "1" = "Owner";
    "2" = "PublishingEditor";
    "3" = "Editor";
    "4" = "PublishingAuthor";
    "5" = "Author";
    "6" = "NonEditingAuthor";
    "7" = "Reviewer";
    "8" = "Contributor";
    "9" = "AvailabilityOnly";
    "10" = "LimitedDetails"
}

# Display permission levels to the user with the intended colors
Write-Host "Select the permission level for the calendar:" -ForegroundColor Cyan
foreach ($key in $permissionLevels.Keys) {
    Write-Host "$key. $($permissionLevels[$key])" -ForegroundColor DarkYellow
}

# Prompt for permission level
$selectedPermissionLevel = Read-Host "Enter the number for the desired permission level"
while (-not ($permissionLevels.Keys -contains $selectedPermissionLevel)) {
    Write-Host "Invalid selection. Please select a valid number." -ForegroundColor DarkYellow
    $selectedPermissionLevel = Read-Host "Enter the number for the desired permission level"
}

# Prompt for the mailbox owner whose calendar permissions will be modified
$mailboxOwner = Read-Host "Enter the email address of the mailbox owner"

# Prompt for the user who will be granted access
$accessUser = Read-Host "Enter the email address of the user who will have access"

# Attempt to set calendar permissions
try {
    Set-MailboxFolderPermission -Identity "$mailboxOwner`:\Calendar" -User $accessUser -AccessRights $permissionLevels[$selectedPermissionLevel] -ErrorAction Stop
    Write-Host "Calendar permissions for $mailboxOwner have been modified. User $accessUser has $($permissionLevels[$selectedPermissionLevel]) permissions on the calendar." -ForegroundColor Green
} catch {
    # If setting permissions fails, attempt to add the permission
    try {
        Add-MailboxFolderPermission -Identity "$mailboxOwner`:\Calendar" -User $accessUser -AccessRights $permissionLevels[$selectedPermissionLevel]
        Write-Host "Calendar permissions for $mailboxOwner have been added. User $accessUser now has $($permissionLevels[$selectedPermissionLevel]) permissions on the calendar." -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while attempting to modify or add permissions: $_" -ForegroundColor Red
    }
}
