# Install PSWriteHTML module
Install-Module -Name PSWriteHTML -Force

# Import the PSWriteHTML module
Import-Module PSWriteHTML -Force


# Prompt for tenant domain name
$TenantDomain = Read-Host -Prompt "Enter your tenant domain (e.g., 'yourtenant' for 'yourtenant-admin.sharepoint.com')"

# Construct the SharePoint Online admin site URL
$AdminSiteURL = "https://$TenantDomain-admin.sharepoint.com"

# Connect to SharePoint Online
Connect-SPOService -Url $AdminSiteURL

# Retrieve all SharePoint Online sites and sort them by Title
$Sites = Get-SPOSite -Limit All | Sort-Object Title

# Initialize a list to store external user information
$ExternalSPOUsers = [System.Collections.Generic.List[Object]]::new()

# Counter for tracking progress
$Counter = 0

# Iterate through each site and retrieve external users
ForEach ($Site in $Sites) {
    $Counter++
    Write-Host ("Checking Site {0}/{1}: {2}" -f $Counter, $Sites.Count, $Site.Title)
    
    [array]$SiteUsers = $Null
    $i = 0
    $Done = $False
    
    Do {
        # Retrieve external users in batches of 50
        [array]$SUsers = Get-SPOExternalUser -SiteUrl $Site.Url -PageSize 50 -Position $i
        
        If ($SUsers) { 
            $i += 50
            $SiteUsers = $SiteUsers + $SUsers 
        }
        
        If ($SUsers.Count -lt 50) { $Done = $True }
        
    } While ($Done -eq $False)
    
    # Add retrieved users to the external users list
    ForEach ($User in $SiteUsers) {
        $ReportLine = [PSCustomObject]@{
            Email        = $User.Email
            Name         = $User.DisplayName
            Accepted     = $User.AcceptedAs
            Created      = $User.WhenCreated
            SPOUrl       = $Site.Url
            TeamsChannel = $Site.IsTeamsChannelConnected
            ChannelType  = $Site.TeamsChannelType
            CrossTenant  = $User.IsCrossTenant
            LoginName    = $User.LoginName
        }
        $ExternalSPOUsers.Add($ReportLine)
    }
}

# Generate an HTML report of external users and display it
$ExternalSPOUsers | Sort-Object Email | Out-HtmlView -HideFooter -Title "SharePoint Online External Users Report"
