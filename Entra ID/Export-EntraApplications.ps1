<#
.SYNOPSIS
Export applications created by the organization in Entra App Registrations.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves applications created in "App Registrations"
by filtering for the PublisherDomain matching the organization. It fetches associated users, groups,
and the AssignmentRequired status for each app. The data is then exported to a CSV file.

.AUTHOR
Your Name
#>

# Function to ensure the Microsoft.Graph module is installed and loaded
function Ensure-GraphModule {
    if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph")) {
        Write-Host "Microsoft Graph module is not installed. Installing now..." -ForegroundColor Yellow
        Install-Module -Name "Microsoft.Graph" -Force -Scope CurrentUser -AllowClobber
    }
    if (-not (Get-Module -Name "Microsoft.Graph")) {
        Write-Host "Importing Microsoft Graph module..." -ForegroundColor Yellow
        Import-Module -Name "Microsoft.Graph" -ErrorAction Stop
    }
}

# Function to connect to Microsoft Graph
function Connect-Graph {
    if (-not (Get-MgContext)) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All", "AppRoleAssignment.ReadWrite.All"
    } else {
        Write-Host "Already connected to Microsoft Graph." -ForegroundColor Green
    }
}

# Ensure PowerShell version is adequate
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "PowerShell 7 or higher is recommended. Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    return
}

# Ensure Microsoft.Graph module is installed and loaded
Ensure-GraphModule

# Connect to Microsoft Graph
Connect-Graph

# Retrieve the organization's verified domain
$orgDomain = (Get-MgOrganization).VerifiedDomains | Select-Object -First 1 -ExpandProperty Name
if (-not $orgDomain) {
    Write-Host "Could not retrieve the organization's verified domain. Exiting..." -ForegroundColor Red
    return
}
Write-Host "Organization's verified domain: $orgDomain" -ForegroundColor Green

# Retrieve all applications created by the organization
Write-Host "Retrieving organization-created applications..." -ForegroundColor Cyan
$appRegistrations = Get-MgApplication -All -Filter "PublisherDomain eq '$orgDomain'" -ErrorAction Stop

# Check if applications were found
if (-not $appRegistrations) {
    Write-Host "No applications found for the organization's domain: $orgDomain" -ForegroundColor Yellow
    return
}

# Prepare output for CSV export
$applicationsData = @()

foreach ($app in $appRegistrations) {
    Write-Host "Processing application: $($app.DisplayName)" -ForegroundColor Yellow

    # Retrieve the corresponding ServicePrincipalId for the application
    $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($app.AppId)'" -ErrorAction SilentlyContinue

    if (-not $servicePrincipal) {
        Write-Warning "No Service Principal found for application: $($app.DisplayName)"
        continue
    }

    # Basic application details
    $appDetails = @{
        "ApplicationId"       = $app.AppId
        "DisplayName"         = $app.DisplayName
        "CreatedDateTime"     = $app.CreatedDateTime
        "PublisherDomain"     = $app.PublisherDomain
        "AssignmentRequired"  = $servicePrincipal.AppRoleAssignmentRequired -eq $true ? "Yes" : "No"
    }

    # Retrieve users and groups assigned to the app
    $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id -ErrorAction SilentlyContinue
    if ($appRoleAssignments) {
        $users = @()
        $groups = @()

        foreach ($assignment in $appRoleAssignments) {
            if ($assignment.PrincipalType -eq "User") {
                $user = Get-MgUser -UserId $assignment.PrincipalId -ErrorAction SilentlyContinue
                if ($user) {
                    $users += $user.DisplayName
                }
            } elseif ($assignment.PrincipalType -eq "Group") {
                $group = Get-MgGroup -GroupId $assignment.PrincipalId -ErrorAction SilentlyContinue
                if ($group) {
                    $groups += $group.DisplayName
                }
            }
        }

        $appDetails["AssignedUsers"] = if ($users.Count -gt 0) { $users -join ", " } else { "None" }
        $appDetails["AssignedGroups"] = if ($groups.Count -gt 0) { $groups -join ", " } else { "None" }
    } else {
        $appDetails["AssignedUsers"] = "None"
        $appDetails["AssignedGroups"] = "None"
    }

    # Add app details to the data array
    $applicationsData += $appDetails
}

# Export data to CSV
$exportPath = "OrganizationCreatedApps.csv"
Write-Host "Exporting application details to $exportPath..." -ForegroundColor Cyan
$applicationsData | Export-Csv -Path $exportPath -NoTypeInformation -Force -Encoding UTF8
Write-Host "Export completed successfully. File saved as $exportPath." -ForegroundColor Green