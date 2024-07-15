#command that you can runt to get a list of email addresses for all users in your organization and save it to a text file named Users.txt.
Get-Mailbox -ResultSize unlimited -Filter { RecipientTypeDetails -eq 'UserMailbox'} | Select-Object PrimarySmtpAddress > Users.txt
