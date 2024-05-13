# CreatedBy: Shaun Hardneck (ThatLazyAdmin)
# Blog: www.thatlazyadmin.com
# Github Repo: https://github.com/thatlazyadmin/DeathStarScriptHub

# Enhanced Script to Export Room Mailbox Calendar Permissions Based on Building Location

# Function to ensure connection to Exchange Online
function Ensure-ExchangeOnlineConnection {
    try {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        Connect-ExchangeOnline
        Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
    } catch {
        Write-Error "Error connecting to Exchange Online: $_" -ForegroundColor Red
        exit
    }
}

# Main function to export room mailbox calendar permissions based on building location
function Export-RoomMailboxCalendarPermissionsByBuilding {
    Ensure-ExchangeOnlineConnection

    # Prompt for building
    $buildingName = Read-Host "Please enter the building name of the room mailboxes"
    Write-Host "Filtering room mailboxes for building: $buildingName..." -ForegroundColor DarkYellow

    $allRoomMailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited
    $filteredMailboxes = @()

    # Filter mailboxes by building using Get-Place
    foreach ($mailbox in $allRoomMailboxes) {
        $place = Get-Place -Identity $mailbox.Alias
        if ($place.Building -eq $buildingName) {
            $filteredMailboxes += $mailbox
        }
    }

    $results = @()

    if ($filteredMailboxes.Count -eq 0) {
        Write-Host "No room mailboxes found for the specified building. Exiting script." -ForegroundColor Red
        return
    }

    foreach ($roomMailbox in $filteredMailboxes) {
        $calendarPermissions = Get-MailboxFolderPermission -Identity "$($roomMailbox.Identity):\Calendar" -ErrorAction SilentlyContinue
        foreach ($permission in $calendarPermissions) {
            if ($permission.User -notin @('Default', 'Anonymous')) {
                $obj = [PSCustomObject]@{
                    "Display Name" = $roomMailbox.DisplayName
                    "User Principal Name" = $roomMailbox.UserPrincipalName
                    "Email Address" = $roomMailbox.PrimarySmtpAddress
                    "Permission Holder" = $permission.User.DisplayName
                    "Calendar Permissions" = $permission.AccessRights -join ', '
                }
                $results += $obj
            }
        }
    }

    # Export the results to a CSV file
    $results | Export-Csv -Path ".\RoomMailboxCalendarPermissionsByBuilding.csv" -NoTypeInformation
    Write-Host "Export completed successfully. Check the .\RoomMailboxCalendarPermissionsByBuilding.csv file." -ForegroundColor Green
}

# Execute the script
Export-RoomMailboxCalendarPermissionsByBuilding
