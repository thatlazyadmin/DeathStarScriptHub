# CreatedBy: Shaun Hardneck (ThatLazyAdmin)
# Blog: www.thatlazyadmin.com
# Github Repo: https://github.com/thatlazyadmin/DeathStarScriptHub
# Enhanced Script to Export Room Mailbox Calendar Permissions with Location Filtering

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

# Main function to export room mailbox calendar permissions with location-based filtering
function Export-RoomMailboxCalendarPermissions {
    Ensure-ExchangeOnlineConnection

    # Prompt for building or location
    $location = Read-Host "Please enter the building or location of the room mailboxes"
    Write-Host "Filtering room mailboxes for location: $location..." -ForegroundColor DarkYellow

    $roomMailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited |
                     Where-Object { $_.CustomAttribute1 -eq $location }
    
    $results = @()

    if ($roomMailboxes -eq $null -or $roomMailboxes.Count -eq 0) {
        Write-Host "No room mailboxes found for the specified location. Exiting script." -ForegroundColor DarkYellow
        return
    }

    foreach ($roomMailbox in $roomMailboxes) {
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
    $results | Export-Csv -Path ".\RoomMailboxCalendarPermissionsEnhanced.csv" -NoTypeInformation
    Write-Host "Export completed successfully. Check the .\RoomMailboxCalendarPermissionsEnhanced.csv file." -ForegroundColor Green
}

# Execute the script
Export-RoomMailboxCalendarPermissions
