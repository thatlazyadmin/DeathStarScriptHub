#CreatedBy: Shaun Hardneck (ThatLazyAdmin)
#Blog: www.thatlazyadmin.com
#GitHub: https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main
# Connect to Exchange Online
# Ensure you have the necessary permissions and the Exchange Online PowerShell Module installed

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


Connect-ExchangeOnline

# Collect mailbox permissions
$mailboxes = Get-Mailbox -ResultSize Unlimited
$reportEntries = @()

foreach ($mailbox in $mailboxes) {
    $permissions = Get-MailboxPermission $mailbox.Identity | Where-Object { $_.IsInherited -eq $False }
    $calendarPermissions = Get-MailboxFolderPermission -Identity "$($mailbox.PrimarySmtpAddress):\Calendar" | Where-Object { $_.User -ne "Anonymous" -and $_.User -ne "Default" }

    foreach ($perm in $permissions) {
        $reportEntries += [PSCustomObject]@{
            Mailbox           = $mailbox.PrimarySmtpAddress
            UserGrantedAccess = $perm.User
            AccessRights      = $perm.AccessRights
            Type              = "Mailbox"
        }
    }

    foreach ($calPerm in $calendarPermissions) {
        $reportEntries += [PSCustomObject]@{
            Mailbox           = $mailbox.PrimarySmtpAddress
            UserGrantedAccess = $calPerm.User
            AccessRights      = $calPerm.AccessRights
            Type              = "Calendar"
        }
    }
}

# Generate HTML report
$htmlHeader = @"
<style>
    body { font-family: Arial, sans-serif; }
    table { border-collapse: collapse; width: 100%; }
    th, td { text-align: left; padding: 8px; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .header { background-color: #04AA6D; color: white; padding: 10px; text-align: center; }
</style>
<h1 class='header'>Mailbox and Calendar Permissions Audit Report</h1>
<p>Generated on: $(Get-Date)</p>
"@

$htmlBody = $reportEntries | ConvertTo-Html -Property Mailbox, UserGrantedAccess, AccessRights, Type -Head $htmlHeader
$htmlBody | Out-File -FilePath "MailboxPermissionsReport.html"

# Open the report automatically (optional)
Invoke-Item "MailboxPermissionsReport.html"