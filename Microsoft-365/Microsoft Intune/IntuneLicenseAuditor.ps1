<#
.SYNOPSIS
This script fetches all available Microsoft Intune licenses within a tenant and details the users to whom these licenses are assigned.

.DESCRIPTION
Leveraging the Microsoft Graph API, the script retrieves detailed information about each Intune license available in your Microsoft tenant and lists the users assigned to each of these licenses.

.NOTES
Created by: Shaun Hardneck
Blog: www.thatlazyadmin.com

#>

# Requires the installation of the Microsoft.Graph PowerShell SDK
# Install it using: Install-Module Microsoft.Graph -Scope CurrentUser

Import-Module Microsoft.Graph

# Authenticate to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All"

# Function to fetch all Intune licenses in the tenant
function Get-IntuneLicenses {
    $allLicenses = Get-MgSubscribedSku
    $intuneLicenses = $allLicenses | Where-Object { $_.ServicePlans.ServiceName -like "*INTUNE*" }

    foreach ($license in $intuneLicenses) {
        $licenseUsers = Get-MgUser -Filter "assignedLicenses/any(x:x/skuId eq '$($license.SkuId)')" -Property displayName, userPrincipalName

        [PSCustomObject]@{
            LicenseName = $license.SkuPartNumber
            Users       = $licenseUsers
        }
    }
}

# Execute the function and display the results
Get-IntuneLicenses

# Disconnect from Microsoft Graph
Disconnect-MgGraph