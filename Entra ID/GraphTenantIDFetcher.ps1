<#
.SYNOPSIS
    This script retrieves the Microsoft Tenant ID using Microsoft Graph.

.DESCRIPTION
    The script connects to Microsoft Graph and pulls out the Microsoft Tenant ID, displaying it in a clear and formatted manner. It is intended for administrators and requires the Microsoft.Graph module.

.NOTES
    Version:        1.0
    Author:         Your Name
    Creation Date:  Your Date
    Purpose/Change: Updated script to use Microsoft Graph PowerShell SDK

.EXAMPLE
    .\Get-MSTenantIDGraph.ps1
#>

# Ensure the Microsoft.Graph module is loaded
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module is not installed. Please install using 'Install-Module Microsoft.Graph'." -ForegroundColor Red
    exit
}

# Attempt to connect to Microsoft Graph
try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "Organization.Read.All" | Out-Null
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
}
catch {
    Write-Host "Error connecting to Microsoft Graph. Please ensure you have permissions and are connected to the internet." -ForegroundColor Red
    exit
}

# Retrieve Tenant Details
try {
    $tenantDetails = Get-MgOrganization
    Write-Host "Successfully retrieved tenant details." -ForegroundColor Green
}
catch {
    Write-Host "Error retrieving tenant details." -ForegroundColor Red
    exit
}

# Display Tenant ID in a clear format
Write-Host "Microsoft Tenant ID:" -ForegroundColor Cyan
foreach ($tenantDetail in $tenantDetails) {
    Write-Host $tenantDetail.Id -ForegroundColor White
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph