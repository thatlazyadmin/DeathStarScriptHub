#urbannerdconsulting
# Prompt for the domain name
$domainName = Read-Host "Please enter your domain name (without https:// and -admin part)"
$adminUrl = "https://$domainName-admin.sharepoint.com"

# Prompt for credentials
#$username = Read-Host "Enter your username"
#$password = Read-Host "Enter your password" -AsSecureString
#$credentials = New-Object System.Management.Automation.PSCredential($username, $password)

# Connect to SharePoint Online Admin Center
Connect-SPOService -Url $adminUrl -Credential $credentials

# Get all site collections
$sites = Get-SPOSite -Limit All

# Prepare an array to hold the export data
$exportData = @()

foreach ($site in $sites) {
    $siteDetail = Get-SPOSite -Identity $site.Url -Detailed
    # Assuming 'ExternalUserAndGuestSharing' as public sites, adjust as needed
    if ($siteDetail.SharingCapability -eq "ExternalUserAndGuestSharing") {
        # List site names in green
        Write-Host $siteDetail.Title -ForegroundColor Green

        # Get site administrators
        $admins = Get-SPOUser -Site $siteDetail.Url | Where-Object { $_.IsSiteAdmin -eq $true } | Select-Object -ExpandProperty DisplayName

        # Create a custom object for each site and add it to the array
        $obj = [PSCustomObject]@{
            "Site Name" = $siteDetail.Title
            "URL" = $siteDetail.Url
            "Administrators" = ($admins -join ", ")
            "External Sharing" = $siteDetail.SharingCapability
        }
        $exportData += $obj
    }
}

# Export to CSV
$exportPath = "SPO_Sites_Public.csv"
$exportData | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "Export completed. File path: $exportPath" -ForegroundColor Cyan

# Disconnect the SharePoint Online session
Disconnect-SPOService