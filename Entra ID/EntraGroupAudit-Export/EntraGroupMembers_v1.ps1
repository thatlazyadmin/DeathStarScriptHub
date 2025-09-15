# Clear the console
Clear-Host

# ==================== THATLAZYADMIN PowerShell Toolkit ====================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      🔍 Entra Group Member Attributes Export Tool        ║" -ForegroundColor Cyan
Write-Host "║        Developed by THATLAZYADMIN                        ║" -ForegroundColor Cyan
Write-Host "║        www.thatlazyadmin.com | shaun@thatlazyadmin.com   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:"
Write-Host " - Prompt for an Entra ID security group name"
Write-Host " - Retrieve all members of the group"
Write-Host " - Export all user attributes with values to a CSV" -ForegroundColor Yellow
Write-Host ""

# Ensure Microsoft Graph module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "[INFO] Installing Microsoft Graph PowerShell SDK..." -ForegroundColor Cyan
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Write-Host "[INFO] Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"
Write-Host "[OK] Connected to Microsoft Graph." -ForegroundColor Green

# Prompt for group name
$GroupName = Read-Host -Prompt "Enter the Security Group Name"

# Search for the group
Write-Host "[INFO] Searching for group: $GroupName" -ForegroundColor Cyan
$Group = Get-MgGroup -Filter "displayName eq '$GroupName'" -Property Id, DisplayName -ErrorAction SilentlyContinue

if (!$Group) {
    Write-Host "[ERROR] Group not found. Please check the name and try again." -ForegroundColor Red
    exit
}

$GroupId = $Group.Id
Write-Host "[OK] Group found: $($Group.DisplayName)" -ForegroundColor Green

# Get group members
Write-Host "[INFO] Fetching group members..." -ForegroundColor Cyan
$Members = Get-MgGroupMember -GroupId $GroupId -All -ErrorAction SilentlyContinue

if (-not $Members) {
    Write-Host "[WARNING] No members found in the group." -ForegroundColor Yellow
    exit
}

# Process users and collect non-empty attributes
$Output = foreach ($Member in $Members) {
    if ($Member.'@odata.type' -eq '#microsoft.graph.user') {
        $User = Get-MgUser -UserId $Member.Id -Property * -ErrorAction SilentlyContinue
        if ($User) {
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

# Create output folder
$ExportFolder = "$PSScriptRoot\Exports"
if (-not (Test-Path $ExportFolder)) {
    New-Item -Path $ExportFolder -ItemType Directory | Out-Null
}

# Export to CSV
$DateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ExportPath = "$ExportFolder\EntraGroupUsers_$($Group.DisplayName)_$DateStamp.csv"

Write-Host "[INFO] Exporting data to CSV..." -ForegroundColor Cyan
$Output | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host "[DONE] Export complete. File saved at:" -ForegroundColor Green
Write-Host $ExportPath -ForegroundColor Yellow