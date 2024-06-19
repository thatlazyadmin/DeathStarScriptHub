<#
.SYNOPSIS
This script assigns the Power BI Admin role using Microsoft Entra access packages programmatically.

.DESCRIPTION
This PowerShell script connects to Microsoft Graph, retrieves the necessary catalog and resource details, 
prepares the parameters, and assigns the Power BI Admin role to the specified access package. 
This streamlines the process of role assignment, especially useful for managing roles across various resources.

.Created By: Shaun Hardneck
.Blog: www.thatlazyadmin.com
#>

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"

# Retrieve the catalog ID and resource details
$catalog = Get-MgEntitlementManagementCatalog -Filter "displayName eq 'Entra Admins'" -All
$rsc = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $catalog.id -ExpandProperty scopes

# Prepare the parameters for role assignment
$params = @{
    role = @{
        id = $rsc.Roles | Where-Object { $_.displayName -eq 'Power BI Administrator' } | Select-Object -First 1 | ForEach-Object { $_.Id }
        displayName = 'Power BI Administrator'
        description = 'Can manage all aspects of Power BI administration.'
        originSystem = 'Microsoft Entra'
        originId = 'powerbi_admin'
        resource = @{
            id = $rsc.Id
            originId = $rsc.OriginId
            originSystem = $rsc.OriginSystem
        }
    }
    scope = @{
        id = $rsc.Scopes[0].Id
        originId = $rsc.Scopes[0].OriginId
        originSystem = $rsc.Scopes[0].OriginSystem
    }
}

# Assign the role to the access package
$apid = 'your-access-package-id'  # Replace with your actual Access Package ID
New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $apid -BodyParameter $params