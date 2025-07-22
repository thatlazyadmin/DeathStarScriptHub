# Clear the screen
Clear-Host

# === THATLAZYADMIN PowerShell Toolkit ===
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      🔍 Entra Group Member Attributes Export Tool        ║" -ForegroundColor Cyan
Write-Host "║        Developed by THATLAZYADMIN                        ║" -ForegroundColor Cyan
Write-Host "║        www.thatlazyadmin.com | hello@unerd.cloud         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:"
Write-Host " - Prompt for an Entra ID security group name"
Write-Host " - Retrieve all members of the group"
Write-Host " - Export all user attributes with values to a CSV" -ForegroundColor Yellow
Write-Host ""

# Connect to Microsoft Graph
Write-Host "[INFO] Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"
Write-Host "[OK] Connected to Microsoft Graph." -ForegroundColor Green

# Prompt for group name
$GroupName = Read-Host -Prompt "Enter the Security Group Name"

# Search group
Write-Host "[INFO] Searching for group: $GroupName" -ForegroundColor Cyan
$Group = Get-MgGroup -Filter "displayName eq '$GroupName'" -Property Id, DisplayName

if (!$Group) {
    Write-Host "[ERROR] Group not found. Please check the name and try again." -ForegroundColor Red
    exit
}

$GroupId = $Group.Id
Write-Host "[OK] Group found: $($Group.DisplayName)" -ForegroundColor Green

# Get group members
Write-Host "[INFO] Fetching group members..." -ForegroundColor Cyan
$Members = Get-MgGroupMember -GroupId $GroupId -All

# Prepare output
$Output = foreach ($Member in $Members) {
    if ($Member.'@odata.type' -eq '#microsoft.graph.user') {
        $User = Get-MgUser -UserId $Member.Id -Property * -ErrorAction SilentlyContinue
        if ($User) {
            # Only include attributes that have values
            $FilteredProps = [ordered]@{}
            $User.PSObject.Properties | ForEach-Object {
                if ($_.Value -ne $null -and $_.Value -ne "") {
                    $FilteredProps[$_.Name] = $_.Value
                }
            }
            [PSCustomObject]$FilteredProps
        }
    }
}

# Export
$DateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ExportPath = "$PSScriptRoot\EntraGroupUsers_$($Group.DisplayName)_$DateStamp.csv"

Write-Host "[INFO] Exporting to CSV: $ExportPath" -ForegroundColor Cyan
$Output | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host "[DONE] Export complete. File saved at:" -ForegroundColor Green
Write-Host $ExportPath -ForegroundColor Yellow
