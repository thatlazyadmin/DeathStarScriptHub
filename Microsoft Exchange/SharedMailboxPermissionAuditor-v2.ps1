#CreatedBy: Shaun Hardneck (ThatLazyAdmin)
#Blog: www.thatlazyadmin.com
#Github Repo: https://github.com/thatlazyadmin/DeathStarScriptHub

# Import the Exchange Online PowerShell module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online. This command opens a sign-in window where you enter your Office 365 admin credentials.
Connect-ExchangeOnline -ShowProgress $true

# Retrieve all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# Initialize a list to hold shared mailboxes with no full access or send as permissions and their sizes
$sharedMailboxesWithNoPermissions = @()

# Iterate over each shared mailbox to check for permissions and gather size information
foreach ($mailbox in $sharedMailboxes) {
    # Check for Full Access permissions
    $fullAccessPermissions = Get-MailboxPermission -Identity $mailbox.Identity | Where-Object { $_.AccessRights -eq "FullAccess" -and -not $_.IsInherited -and $_.User -notlike "NT AUTHORITY\SELF" }
    
    # Check for Send As permissions
    $sendAsPermissions = Get-RecipientPermission -Identity $mailbox.Identity | Where-Object { $_.AccessRights -eq "SendAs" -and $_.Trustee -notlike "NT AUTHORITY\SELF" }
    
    # Retrieve mailbox size information
    $mailboxStats = Get-MailboxStatistics -Identity $mailbox.Identity

    # If no Full Access and Send As permissions are found, add the mailbox to the list with size information
    if (-not $fullAccessPermissions -and -not $sendAsPermissions) {
        # Extract sizes from the ToString() output, assuming format like "12.34 GB (13,245,678 bytes)"
        $totalItemSizeMB = [regex]::Match($mailboxStats.TotalItemSize.ToString(), '(\d+(?:\.\d+)?)\s+MB').Groups[1].Value
        $totalDeletedItemSizeMB = [regex]::Match($mailboxStats.TotalDeletedItemSize.ToString(), '(\d+(?:\.\d+)?)\s+MB').Groups[1].Value
        
        $obj = New-Object PSObject -Property @{
            DisplayName = $mailbox.DisplayName
            PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
            PermissionsIndicator = "No Full Access or Send As permissions"
            TotalItemSizeMB = $totalItemSizeMB
            TotalDeletedItemSizeMB = $totalDeletedItemSizeMB
        }
        $sharedMailboxesWithNoPermissions += $obj
    }
}

# Display the shared mailboxes with no permissions and their sizes
$sharedMailboxesWithNoPermissions | Format-Table DisplayName, PrimarySmtpAddress, PermissionsIndicator, TotalItemSizeMB, TotalDeletedItemSizeMB

# Optionally, export the list to a CSV file
$sharedMailboxesWithNoPermissions | Select-Object DisplayName, PrimarySmtpAddress, PermissionsIndicator, TotalItemSizeMB, TotalDeletedItemSizeMB | Export-Csv -Path "./SharedMailboxesWithNoPermissions.csv" -NoTypeInformation

# Disconnect the session
Disconnect-ExchangeOnline -Confirm:$false
