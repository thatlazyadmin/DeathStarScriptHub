<#
.SYNOPSIS
This script fetches all available Microsoft Intune licenses within a tenant and details the users to whom these licenses are assigned.

.DESCRIPTION
Leveraging the Microsoft Graph API, the script retrieves detailed information about each Intune license available in your Microsoft tenant, lists the users assigned to each of these licenses, and provides a count of how many Intune licenses are available.

.NOTES
Created by: Shaun Hardneck
Blog: www.thatlazyadmin.com

#>

# Requires the installation of the Microsoft.Graph PowerShell SDK
# Install it using: Install-Module Microsoft.Graph -Scope CurrentUser

#Import-Module Microsoft.Graph
#Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Authenticate to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All", "User.Read.All"

# Fetch all subscriptions in the tenant
$licenses = Get-MgSubscribedSku

# Check if licenses are retrieved
if (-not $licenses) {
    Write-Host "No licenses found. Please check the permissions or license status."
    Disconnect-MgGraph
    return
}

# Filter and display details on licenses that include Intune in their service plans
$intuneLicensesFound = $false
foreach ($license in $licenses) {
    $intuneServicePlans = $license.ServicePlans | Where-Object { $_.ServiceName -like "*INTUNE*" }
    if ($intuneServicePlans) {
        $intuneLicensesFound = $true
        Write-Host "License: $($license.SkuPartNumber) includes Intune."
        Write-Host "License Details:"
        $license | Select-Object -Property SkuPartNumber, SkuId, @{Name="EnabledUnits";Expression={$_.PrepaidUnits.Enabled}}, @{Name="ConsumedUnits";Expression={$_.PrepaidUnits.ConsumedUnits}} | Format-List
        Write-Host "Users with this license:"
        $usersWithLicense = Get-MgUser -Filter "assignedLicenses/any(x:x/skuId eq '$($license.SkuId)')" -Property displayName, userPrincipalName
        if ($usersWithLicense) {
            $usersWithLicense | Select-Object displayName, userPrincipalName | Format-Table
        } else {
            Write-Host "No users found with this license."
        }
    }
}

if (-not $intuneLicensesFound) {
    Write-Host "No Intune licenses found in the tenant."
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph