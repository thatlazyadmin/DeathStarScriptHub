# Connect to Exchange Online
Connect-ExchangeOnline -ShowProgress $true

# Prompt for the mailbox to check
$Mailbox = Read-Host -Prompt "Enter the mailbox email address"

# Get all inbox rules for the mailbox
$InboxRules = Get-InboxRule -Mailbox $Mailbox

# Display the rules and whether they are enabled or not
Write-Host "`nInbox Rules for $Mailbox" -ForegroundColor Cyan
foreach ($rule in $InboxRules) {
    $status = if ($rule.Enabled) { "Enabled" } else { "Disabled" }
    Write-Host "Rule Name: $($rule.Name) - Status: $status"
}

# Prompt the user to remove all inbox rules
$removeRules = Read-Host -Prompt "Do you want to remove all inbox rules? (Y/N)"

if ($removeRules -eq 'Y') {
    foreach ($rule in $InboxRules) {
        Remove-InboxRule -Mailbox $Mailbox -Identity $rule.Identity -Confirm:$false
        Write-Host "Removed rule: $($rule.Name)"
    }
    Write-Host "All inbox rules have been removed for $Mailbox." -ForegroundColor Green
} else {
    Write-Host "No rules were removed." -ForegroundColor Yellow
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
