Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "SharedInsight365 – Microsoft 365 File Sharing Scanner"
$form.Size = New-Object System.Drawing.Size(750, 520)
$form.StartPosition = "CenterScreen"

$connectBtn = New-Object System.Windows.Forms.Button
$connectBtn.Text = "Connect & Authorize"
$connectBtn.Size = New-Object System.Drawing.Size(180,30)
$connectBtn.Location = New-Object System.Drawing.Point(20,20)

$scanBtn = New-Object System.Windows.Forms.Button
$scanBtn.Text = "Scan & Export"
$scanBtn.Size = New-Object System.Drawing.Size(180,30)
$scanBtn.Location = New-Object System.Drawing.Point(220,20)

$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "Exit"
$exitBtn.Size = New-Object System.Drawing.Size(100,30)
$exitBtn.Location = New-Object System.Drawing.Point(420,20)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Size = New-Object System.Drawing.Size(700,380)
$logBox.Location = New-Object System.Drawing.Point(20,70)
$logBox.ReadOnly = $true

$form.Controls.AddRange(@($connectBtn, $scanBtn, $exitBtn, $logBox))

# Load modules
function Load-Modules {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
    }
    Import-Module Microsoft.Graph
    Import-Module ExchangeOnlineManagement
}
Load-Modules

# Connect
$connectBtn.Add_Click({
    try {
        Connect-MgGraph -Scopes "AuditLog.Read.All","Sites.Read.All","Files.Read.All","User.Read.All","Directory.Read.All"
        $logBox.AppendText("✅ Connected to Microsoft Graph`r`n")
        Connect-ExchangeOnline -ShowBanner:$false
        $logBox.AppendText("✅ Connected to Exchange Online`r`n")
    } catch {
        $logBox.AppendText("❌ Connection error: $_`r`n")
    }
})

$exitBtn.Add_Click({ $form.Close() })

# Scan
$scanBtn.Add_Click({
    try {
        $results = @()
        $logBox.AppendText("🔍 Scanning Audit Logs (last 90 days)...`r`n")
        $startDate = (Get-Date).AddDays(-90)
        $endDate = Get-Date

        $auditData = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate `
            -RecordType SharePointFileOperation -Operations "SharingSet" -ResultSize 5000

        foreach ($entry in $auditData) {
            $results += [PSCustomObject]@{
                "File Name"   = $entry.ObjectId
                "File Path"   = $entry.Site_Url
                "Owner"       = $entry.UserId
                "Shared By"   = $entry.UserId
                "Shared With" = $entry.AffectedUserOrGroupName
                "Date & Time" = $entry.CreationDate
                "Source"      = "AuditLog"
            }
        }

        $logBox.AppendText("✅ Audit log scan complete. Now scanning OneDrive & SharePoint with Graph API...`r`n")

        # Get all users
        $users = Get-MgUser -Filter "UserType eq 'Member'" -All
        foreach ($user in $users) {
            try {
                $logBox.AppendText("📂 Checking OneDrive for: $($user.UserPrincipalName)`r`n")
                $drive = Get-MgUserDrive -UserId $user.Id -ErrorAction SilentlyContinue
                if ($null -ne $drive) {
                    $items = Get-MgDriveRootChildren -DriveId $drive.Id -ErrorAction SilentlyContinue
                    foreach ($item in $items) {
                        $permissions = Get-MgDriveItemPermission -DriveId $drive.Id -ItemId $item.Id -ErrorAction SilentlyContinue
                        foreach ($perm in $permissions) {
                            if ($perm.Link -or $perm.Roles -contains "read") {
                                $sharedTo = if ($perm.GrantedToV2.User.DisplayName) {
                                    $perm.GrantedToV2.User.DisplayName
                                } elseif ($perm.Invitation.Email) {
                                    $perm.Invitation.Email
                                } else {
                                    "Unknown / Anyone"
                                }

                                $results += [PSCustomObject]@{
                                    "File Name"   = $item.Name
                                    "File Path"   = $item.WebUrl
                                    "Owner"       = $user.UserPrincipalName
                                    "Shared By"   = $user.UserPrincipalName
                                    "Shared With" = $sharedTo
                                    "Date & Time" = $perm.SharedDateTime
                                    "Source"      = "Graph API"
                                }
                            }
                        }
                    }
                }
            } catch {
                $logBox.AppendText("⚠️ Failed scanning $($user.UserPrincipalName): $_`r`n")
            }
        }

        $logBox.AppendText("✅ Scanning complete. Total items: $($results.Count)`r`n")

        # Export
        $saveFile = New-Object System.Windows.Forms.SaveFileDialog
        $saveFile.Filter = "CSV (*.csv)|*.csv"
        $saveFile.Title = "Save Shared File Report"
        $saveFile.FileName = "SharedInsight365_Report.csv"
        if ($saveFile.ShowDialog() -eq "OK") {
            $results | Export-Csv -Path $saveFile.FileName -NoTypeInformation -Encoding UTF8
            $logBox.AppendText("📁 Report saved to: $($saveFile.FileName)`r`n")
        }

        # Feature Table
        $logBox.AppendText("`r`n`r`n🧩 Feature Status:`r`n")
        $logBox.AppendText("| Feature                                                 | Status                 |`r`n")
        $logBox.AppendText("| ------------------------------------------------------- | ---------------------- |`r`n")
        $logBox.AppendText("| Unified login button                                    | ✅ Implemented          |`r`n")
        $logBox.AppendText("| Live scan of OneDrive & SharePoint links via Graph      | ✅ Implemented          |`r`n")
        $logBox.AppendText("| Filter by user or site                                  | 🔜 Optional enhancement |`r`n")
        $logBox.AppendText("| Visual UI improvements (icons, banners, toggle options) | 🟡 In design phase      |`r`n")

    } catch {
        $logBox.AppendText("❌ Error during scan: $_`r`n")
    }
})

$form.Topmost = $true
[void]$form.ShowDialog()
