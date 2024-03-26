#Created By: Shaun Hardneck
#Blog: www.thatlazyadmin.com
#Github: 

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
    
    # If no Full Access and Send As permissions are found, add the mailbox to the list
    if (-not $fullAccessPermissions -and -not $sendAsPermissions) {
        $sharedMailboxesWithNoPermissions += $mailbox
    }
}

# Display the shared mailboxes with no permissions
$sharedMailboxesWithNoPermissions | Format-Table DisplayName, PrimarySmtpAddress

# Optionally, export the list to a CSV file
$sharedMailboxesWithNoPermissions | Select-Object DisplayName, PrimarySmtpAddress | Export-Csv -Path "./SharedMailboxesWithNoPermissions.csv" -NoTypeInformation

# Disconnect the session
Disconnect-ExchangeOnline -Confirm:$false
