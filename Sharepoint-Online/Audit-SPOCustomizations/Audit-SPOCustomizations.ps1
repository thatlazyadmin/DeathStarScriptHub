<#
.SYNOPSIS
    This script audits SharePoint Online sites to ensure that "DenyAddAndCustomizePages" is enabled for each site, excluding MySite hosts. The results are exported to a CSV file with a current date stamp.

    Created by: Shaun Hardneck
    Contact: shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to SharePoint Online using the provided credentials.
    2. Retrieves all SharePoint Online sites.
    3. Checks if the "DenyAddAndCustomizePages" setting is enabled for each site.
    4. Exports the non-compliant results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Audit-SPOCustomizations.ps1
    This example runs the script to audit SharePoint Online sites and verify that "DenyAddAndCustomizePages" is enabled for each site, excluding MySite hosts. Results are exported to a CSV file.

.PREREQUISITES
    - You must have the SharePoint Online Management Shell installed.
    - You must have the necessary permissions to connect to SharePoint Online and retrieve site details.

.NOTES
    This script is necessary to ensure that the "DenyAddAndCustomizePages" setting is enabled for all SharePoint Online sites, enhancing the security and compliance posture of the organization.
#>

# Import required modules
# Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Connect to SharePoint Online
try {
    Connect-SPOService -Url https://<your-tenant>-admin.sharepoint.com -Credential (Get-Credential)
    Write-Host "Successfully connected to SharePoint Online." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to SharePoint Online. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to audit SharePoint Online sites
function Audit-SPOCustomizations {
    try {
        $sites = Get-SPOSite -Limit All | Where-Object { $_.DenyAddAndCustomizePages -eq "Disabled" -and $_.Url -notlike "*-my.sharepoint.com/" }
        $nonCompliantSites = @()

        foreach ($site in $sites) {
            $nonCompliantSites += [PSCustomObject]@{
                Title = $site.Title
                Url = $site.Url
                DenyAddAndCustomizePages = $site.DenyAddAndCustomizePages
            }
        }

        if ($nonCompliantSites.Count -gt 0) {
            Write-Host "Non-compliant sites found." -ForegroundColor Red
            $nonCompliantSites | Format-Table Title, Url, DenyAddAndCustomizePages

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "NonCompliantSPOCustomizations_$currentDate.csv"
            $nonCompliantSites | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "All sites are compliant." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to retrieve site details. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Audit-SPOCustomizations