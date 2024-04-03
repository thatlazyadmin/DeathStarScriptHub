#CreatedBy: Shaun Hardneck (ThatLazyAdmin)
#Blog: www.thatlazyadmin.com
#Github Repo: https://github.com/thatlazyadmin/DeathStarScriptHub
# Import the Exchange Online PowerShell module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online. This command opens a sign-in window where you enter your Office 365 admin credentials.
Connect-ExchangeOnline -ShowProgress $true

# Retrieve all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# Initialize a list to hold shared mailboxes with no full access or send as permissions
$sharedMailboxesWithNoPermissions = @()

# Iterate over each shared mailbox to check for permissions
foreach ($mailbox in $sharedMailboxes) {
    # Check for Full Access permissions
    $fullAccessPermissions = Get-MailboxPermission -Identity $mailbox.Identity | Where-Object { $_.AccessRights -eq "FullAccess" -and -not $_.IsInherited -and $_.User -notlike "NT AUTHORITY\SELF" }
    
    # Check for Send As permissions
    $sendAsPermissions = Get-RecipientPermission -Identity $mailbox.Identity | Where-Object { $_.AccessRights -eq "SendAs" -and $_.Trustee -notlike "NT AUTHORITY\SELF" }
    
    # If no Full Access and Send As permissions are found, add the mailbox to the list with a custom permissions indicator
    if (-not $fullAccessPermissions -and -not $sendAsPermissions) {
        $obj = New-Object PSObject -Property @{
            DisplayName = $mailbox.DisplayName
            PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
            PermissionsIndicator = "No Full Access or Send As permissions"
        }
        $sharedMailboxesWithNoPermissions += $obj
    }
}

# Display the shared mailboxes with no permissions
$sharedMailboxesWithNoPermissions | Format-Table DisplayName, PrimarySmtpAddress, PermissionsIndicator

# Optionally, export the list to a CSV file
$sharedMailboxesWithNoPermissions | Select-Object DisplayName, PrimarySmtpAddress, PermissionsIndicator | Export-Csv -Path "./SharedMailboxesWithNoPermissions.csv" -NoTypeInformation

# Disconnect the session
Disconnect-ExchangeOnline -Confirm:$false