#CreatedBy: Shaun Hardneck (ThatLazyAdmin)
#Blog: www.thatlazyadmin.com
#GitHub: https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main

# Connect to Exchange Online
Connect-ExchangeOnline

# Prompt for the email address of the room mailbox
$RoomMailboxEmail = Read-Host -Prompt "Enter the email address of the room mailbox you wish to add to a group"

# Retrieve the specified room mailbox using the email address
$RoomMailbox = Get-Mailbox -Identity $RoomMailboxEmail -RecipientTypeDetails RoomMailbox -ErrorAction SilentlyContinue

# Check if the room mailbox exists
if ($null -eq $RoomMailbox) {
    Write-Host "The specified room mailbox does not exist or was not found. Please check the email address and try again."
    exit
}

# Prompt for the email address of the M365 group
$GroupEmail = Read-Host -Prompt "Enter the email address of the Microsoft 365 group to add the room mailbox to"

# Retrieve the M365 group by email address to ensure it exists
$Group = Get-UnifiedGroup -Identity $GroupEmail -ErrorAction SilentlyContinue

# Check if the group exists
if ($null -eq $Group) {
    Write-Host "The specified Microsoft 365 group does not exist or was not found. Please check the email address and try again."
    exit
}

# Add the room mailbox to the group, ensuring both identities are not null
if ($null -ne $RoomMailbox -and $null -ne $Group) {
    try {
        Add-UnifiedGroupLinks -Identity $GroupEmail -LinkType Members -Links $RoomMailboxEmail
        Write-Host "Successfully added $RoomMailboxEmail to $GroupEmail." -ForegroundColor Green
    }
    catch {
        Write-Host "Error adding $RoomMailboxEmail to ${GroupEmail}: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Error: One or more required objects were not found. Cannot proceed with adding to group."
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
