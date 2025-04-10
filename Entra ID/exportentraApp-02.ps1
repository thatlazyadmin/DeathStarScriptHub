# Connect to Microsoft Graph with required scopes
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Green
Connect-MgGraph -Scopes "Application.Read.All", "GroupMember.Read.All", "Directory.Read.All"

# Verify connection
if (!(Get-MgContext)) {
    Write-Host "Failed to authenticate to Microsoft Graph. Please ensure your credentials and scopes are correct." -ForegroundColor Red
    return
}

Write-Host "Connected to Microsoft Graph." -ForegroundColor Green

# Initialize results array
$results = @()

# Retrieve all applications
Write-Host "Retrieving all applications..." -ForegroundColor Cyan
$applications = Get-MgApplication -All

if (!$applications) {
    Write-Host "No applications found in the tenant." -ForegroundColor Yellow
    return
}

# Filter applications based on PublisherDomain (specific to organization)
Write-Host "Filtering applications created by the organization..." -ForegroundColor Cyan
$verifiedDomains = (Get-MgOrganization).VerifiedDomains | Select-Object -ExpandProperty Name
$orgApplications = $applications | Where-Object { $_.PublisherDomain -in $verifiedDomains }

if ($orgApplications.Count -eq 0) {
    Write-Host "No organization-created applications found." -ForegroundColor Yellow
    return
}

# Loop through each organization-created application
foreach ($app in $orgApplications) {
    Write-Host "Processing application: $($app.DisplayName)" -ForegroundColor Cyan

    $assignedGroups = @()
    $assignedUsers = @()

    try {
        # Ensure the application has a service principal
        $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($app.AppId)'"
        if (!$servicePrincipal) {
            Write-Host "No ServicePrincipal found for $($app.DisplayName)" -ForegroundColor Yellow
            continue
        }

        # Get app role assignments
        $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id

        foreach ($assignment in $appRoleAssignments) {
            if ($assignment.PrincipalType -eq "Group") {
                $group = Get-MgGroup -GroupId $assignment.PrincipalId
                $assignedGroups += $group.DisplayName
            } elseif ($assignment.PrincipalType -eq "User") {
                $user = Get-MgUser -UserId $assignment.PrincipalId
                $assignedUsers += $user.DisplayName
            }
        }
    } catch {
        Write-Host "Error retrieving assignments for $($app.DisplayName): $_" -ForegroundColor Red
        continue
    }

    # Add to results
    $results += [PSCustomObject]@{
        AppName           = $app.DisplayName
        AppId             = $app.AppId
        CreatedDateTime   = $app.CreatedDateTime
        AssignmentRequired = $servicePrincipal.AppRoleAssignmentRequired
        AssignedGroups    = ($assignedGroups -join ", ")
        AssignedUsers     = ($assignedUsers -join ", ")
    }
}

# Export results to CSV
$exportPath = Join-Path -Path (Get-Location) -ChildPath "OrganizationCreatedApps.csv"
Write-Host "Exporting results to $exportPath..." -ForegroundColor Green
$results | Export-Csv -Path $exportPath -NoTypeInformation -Force

Write-Host "Export completed successfully. File saved as $exportPath." -ForegroundColor Green


$AppId = "dde8fe16-f202-49d5-8ba7-0cef73c49f3b"; Connect-MgGraph -Scopes "Application.Read.All", "GroupMember.Read.All", "Directory.Read.All"; $App = Get-MgApplication -Filter "AppId eq '$AppId'"; $ServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$AppId'"; $AppRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id; $Results = $AppRoleAssignments | ForEach-Object { [PSCustomObject]@{ AppName = $App.DisplayName; AppId = $App.AppId; AssignmentRequired = $ServicePrincipal.AppRoleAssignmentRequired; PrincipalName = $_.PrincipalDisplayName; PrincipalType = $_.PrincipalType } }; $Results | Export-Csv -Path "$($App.DisplayName)_Details.csv" -NoTypeInformation -Force; Write-Host "Exported to $($App.DisplayName)_Details.csv" -ForegroundColor Green

$AppId = "dde8fe16-f202-49d5-8ba7-0cef73c49f3b"; 
Connect-MgGraph -Scopes "Application.Read.All", "Group.Read.All", "User.Read.All", "AppRoleAssignment.Read.All"; 
$ServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$AppId'"; 
$AppRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id; 

$Results = $AppRoleAssignments | ForEach-Object { 
    if ($_.PrincipalType -eq "Group") {
        $GroupMembers = Get-MgGroupMember -GroupId $_.PrincipalId | ForEach-Object { $_.DisplayName }
        [PSCustomObject]@{
            PrincipalName = $_.PrincipalDisplayName
            PrincipalType = "Group"
            GroupMembers = $GroupMembers -join "; "
        }
    } else {
        [PSCustomObject]@{
            PrincipalName = $_.PrincipalDisplayName
            PrincipalType = $_.PrincipalType
            GroupMembers = "N/A"
        }
    }
}

$Results | Export-Csv -Path "$($ServicePrincipal.DisplayName)_Assignments.csv" -NoTypeInformation -Force; 
Write-Host "Exported to $($ServicePrincipal.DisplayName)_Assignments.csv" -ForegroundColor Green
