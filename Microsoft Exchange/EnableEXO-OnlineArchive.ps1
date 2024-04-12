# CreatedBy: Shaun Hardneck (ThatLazyAdmin)
# Blog: www.thatlazyadmin.com
# Github Repo: https://github.com/thatlazyadmin/DeathStarScriptHub

# Import the Exchange Online Management module
#Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
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

# Path to the CSV file
$csvPath = "C:\softlib\exoarc.csv"

# Import the CSV file
$userList = Import-Csv -Path $csvPath

# Loop through each user in the CSV
foreach ($user in $userList) {
    # Enable Online Archive for the user
    try {
        Enable-Mailbox -Identity $user.EmailAddress -Archive
        Write-Host "Online archive enabled for $($user.EmailAddress)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable online archive for $($user.EmailAddress): $_" -ForegroundColor Red
    }
}

# Disconnect the session
Disconnect-ExchangeOnline -Confirm:$false
