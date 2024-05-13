# CreatedBy: Shaun Hardneck (ThatLazyAdmin)
# Blog: www.thatlazyadmin.com
# Github Repo: https://github.com/thatlazyadmin/DeathStarScriptHub
# Enhanced Script to Export Room Mailbox Calendar Permissions Including Permission Holder

# Function to ensure connection to Exchange Online
function Ensure-ExchangeOnlineConnection {
    try {
        Write-Host "Connecting to Exchange Online..."
        Connect-ExchangeOnline -ShowProgress $true -ErrorAction Stop
        Write-Host "Successfully connected to Exchange Online." -ForegroundColor Cyan
    } catch {
        Write-Error "Error connecting to Exchange Online: $_" -ForegroundColor Red
        exit
    }
}

# Main function to export room mailbox calendar permissions with Permission Holder
function Export-RoomMailboxCalendarPermissions {
    Ensure-ExchangeOnlineConnection

    $roomMailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited
    $results = @()

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