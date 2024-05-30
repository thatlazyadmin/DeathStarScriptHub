# Load necessary modules
Import-Module Microsoft.Online.SharePoint.PowerShell -Force
Import-Module Microsoft.Graph -Force

# Prompt for tenant domain name and credentials
$TenantDomain = Read-Host -Prompt "Enter your tenant domain (e.g., 'yourtenant' for 'yourtenant-admin.sharepoint.com')"
$AdminSiteURL = "https://$TenantDomain-admin.sharepoint.com"

# Connect to SharePoint Online
Connect-SPOService -Url $AdminSiteURL

# Authenticate to Microsoft Graph
$GraphAppId = Read-Host -Prompt "Enter your Graph App ID"
$GraphTenantId = Read-Host -Prompt "Enter your Graph Tenant ID"
$GraphClientSecret = Read-Host -Prompt "Enter your Graph Client Secret"

$tokenBody = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $GraphAppId
    client_secret = $GraphClientSecret
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$GraphTenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $tokenBody
$AccessToken = $tokenResponse.access_token

# Function to fetch sharing information from Microsoft Graph
function Get-GraphData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept        = "application/json"
    }

    $response = Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
    return $response.value
}

# Retrieve all SharePoint Online sites and sort them by Title
$Sites = Get-SPOSite -Limit All | Sort-Object Title

# Initialize a list to store external sharing information
$ExternalSharingInfo = [System.Collections.Generic.List[Object]]::new()

# Counter for tracking progress
$Counter = 0

# Iterate through each site and retrieve sharing information
ForEach ($Site in $Sites) {
    $Counter++
    Write-Host ("Checking Site {0}/{1}: {2}" -f $Counter, $Sites.Count, $Site.Title)

    $SiteId = (Get-SPOSite -Identity $Site.Url).Id
    $Uri = "https://graph.microsoft.com/v1.0/sites/$SiteId/drives"

    $Drives = Get-GraphData -Uri $Uri -AccessToken $AccessToken

    ForEach ($Drive in $Drives) {
        $DriveItemsUri = "https://graph.microsoft.com/v1.0/drives/$($Drive.id)/items/root/children"

        $DriveItems = Get-GraphData -Uri $DriveItemsUri -AccessToken $AccessToken

        ForEach ($Item in $DriveItems) {
            if ($Item.shared.sharedWith) {
                $InvitedBy = $Item.lastModifiedBy.user.displayName
                $SharedWith = ($Item.shared.sharedWith | ForEach-Object { $_.user.displayName }) -join ", "
                $ExternalSharingInfo.Add([PSCustomObject]@{
                    FileName     = $Item.name
                    InvitedBy    = $InvitedBy
                    SharedWith   = $SharedWith
                    SiteURL      = $Site.Url
                })
            }
        }
    }
}

# Function to generate HTML report with color styling
function Generate-HTMLReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$ExternalSharingInfo
    )

    $html = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; color: black; }
        h2 { color: black; }
        table { width: 100%; border-collapse: collapse; }
        th { background-color: DarkOrange; color: black; padding: 8px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
    </style>
</head>
<body>
    <h2>External File Sharing Report</h2>
    <table>
        <tr>
            <th>File Name</th>
            <th>Invited By</th>
            <th>Shared With</th>
            <th>Site URL</th>
        </tr>
"@

    foreach ($item in $ExternalSharingInfo) {
        $html += @"
        <tr>
            <td>$($item.FileName)</td>
            <td>$($item.InvitedBy)</td>
            <td>$($item.SharedWith)</td>
            <td>$($item.SiteURL)</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    return $html
}

# Generate HTML report
$HTMLReport = Generate-HTMLReport -ExternalSharingInfo $ExternalSharingInfo

# Get the script directory
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportPath = Join-Path -Path $ScriptDirectory -ChildPath "ExternalFileSharingReport.html"

# Save HTML report to a file
$HTMLReport | Out-File -FilePath $ReportPath

Write-Output "Report generated at $ReportPath"
