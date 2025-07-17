Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check and install required module
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

# Connect Graph Function
function Connect-MicrosoftGraph {
    try {
        Connect-MgGraph -Scopes "AuditLog.Read.All", "Files.Read.All", "Sites.Read.All", "User.Read.All", "Directory.Read.All"
        $global:GraphConnected = $true
        $logBox.AppendText("Connected to Microsoft Graph.`n")
    } catch {
        $logBox.AppendText("Failed to connect to Microsoft Graph.`n")
    }
}

# Search Audit Logs for File Sharing
function Get-SharedFilesAuditData {
    try {
        $results = @()
        $logBox.AppendText("Searching Unified Audit Logs for sharing events...`n")
        
        $startDate = (Get-Date).AddDays(-90)
        $endDate = Get-Date

        $page = 1
        do {
            $auditData = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate `
                -RecordType SharePointFileOperation -Operations "SharingSet" -ResultSize 5000 -Page $page
            
            foreach ($entry in $auditData) {
                $record = [PSCustomObject]@{
                    "File Name"    = $entry.ObjectId
                    "File Path"    = $entry.ObjectId
                    "Owner"        = $entry.UserId
                    "Shared By"    = $entry.UserId
                    "Shared With"  = $entry.AffectedUserOrGroupName
                    "Date & Time"  = $entry.CreationDate
                }
                $results += $record
            }
            $page++
        } while ($auditData.Count -eq 5000)

        $logBox.AppendText("Audit log scan complete. Found $($results.Count) shared files.`n")
        return $results
    } catch {
        $logBox.AppendText("Error retrieving audit log data: $_`n")
    }
}

# Export to CSV
function Export-SharedFilesReport {
    $sharedData = Get-SharedFilesAuditData
    if ($sharedData -and $sharedData.Count -gt 0) {
        $saveFile = New-Object System.Windows.Forms.SaveFileDialog
        $saveFile.Filter = "CSV Files (*.csv)|*.csv"
        $saveFile.Title = "Save Report As"
        $saveFile.FileName = "SharedFilesReport.csv"

        if ($saveFile.ShowDialog() -eq "OK") {
            $sharedData | Export-Csv -Path $saveFile.FileName -NoTypeInformation -Encoding UTF8
            $logBox.AppendText("📁 Report exported to $($saveFile.FileName)`n")
        }
    } else {
        $logBox.AppendText("No data found to export.`n")
    }
}

# GUI Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "Microsoft 365 Shared Files Scanner"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Text = "1. Connect to Graph"
$connectButton.Size = New-Object System.Drawing.Size(160,30)
$connectButton.Location = New-Object System.Drawing.Point(20,20)
$connectButton.Add_Click({ Connect-MicrosoftGraph })
$form.Controls.Add($connectButton)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "2. Export Shared Files"
$scanButton.Size = New-Object System.Drawing.Size(160,30)
$scanButton.Location = New-Object System.Drawing.Point(200,20)
$scanButton.Add_Click({ Export-SharedFilesReport })
$form.Controls.Add($scanButton)

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(100,30)
$exitButton.Location = New-Object System.Drawing.Point(400,20)
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Log Window
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Size = New-Object System.Drawing.Size(550,280)
$logBox.Location = New-Object System.Drawing.Point(20,70)
$logBox.ReadOnly = $true
$form.Controls.Add($logBox)

# Load GUI
$form.Topmost = $true
[void]$form.ShowDialog()
