<#
=============================================================================================
Name:           M365_RBAC_Audit_Export
Description:    This script exports Microsoft 365 admin role group membership to CSV.
Version:        3.0
Website:        www.thatlazyadmin.com

Script Highlights: 
- The script uses MS Graph PowerShell.
- It supports MFA-enabled admin accounts.
- It can be executed with certificate-based authentication (CBA).
- Simple execution format for all admins’ report and role-based admin report.
- Helps to find admin roles for a specific user(s).
- Helps to get all admins with a specific role(s).
- The script is scheduler-friendly.
- Exports the result to a CSV file and also opens the CSV on confirmation.

For detailed Script execution: https://www.thatlazyadmin.com
=============================================================================================
#>

param ( 
    [switch] $RoleBasedAdminReport, 
    [switch] $ExcludeGroups,
    [String] $AdminName = $null, 
    [String] $RoleName = $null,
    [string] $TenantId,
    [string] $ClientId,
    [string] $CertificateThumbprint
)

# Check for and import necessary Microsoft Graph submodules
$requiredModules = @(
    "Microsoft.Graph.Users",
    "Microsoft.Graph.DirectoryObjects"
)

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        try {
            Import-Module $module
        } catch {
            Write-Host "Error: Could not load module $module. Please install the module using 'Install-Module $module' and try again." -ForegroundColor Red
            Exit
        }
    }
}

# Connect to Microsoft Graph
if (($TenantId -ne "") -and ($ClientId -ne "") -and ($CertificateThumbprint -ne "")) {  
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -ErrorAction SilentlyContinue -ErrorVariable ConnectionError | Out-Null
    if ($ConnectionError -ne $null) {    
        Write-Host $ConnectionError -Foregroundcolor Red
        Exit
    }
} else {
    Connect-MgGraph -Scopes "Directory.Read.All,User.Read.All" -ErrorAction SilentlyContinue -ErrorVariable ConnectionError | Out-Null
    if ($ConnectionError -ne $null) {
        Write-Host "$ConnectionError" -Foregroundcolor Red
        Exit
    }
}

Write-Host "Microsoft Graph PowerShell module is connected successfully" -ForegroundColor Green
Write-Host "`nNote: If you encounter module-related conflicts, run the script in a fresh PowerShell window." -ForegroundColor Yellow
Write-Host "`nPreparing admin report..."

$Admins = @() 
$RoleList = @() 
$OutputCsv = ".\AdminReport_$((Get-Date -format MMM-dd` hh-mm` tt).ToString()).csv"

function Process_AdminReport {
    param ($Admin)
    $AdminMemberOf = Get-MgUserMemberOf -UserId $Admin.Id
    $AssignedRoles = $AdminMemberOf | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.directoryRole' }
    $DisplayName = $Admin.DisplayName
    $LicenseStatus = if ($Admin.AssignedLicenses -ne $null) { "Licensed" } else { "Unlicensed" }
    $SignInStatus = if ($Admin.AccountEnabled -eq $true) { "Allowed" } else { "Blocked" }

    Write-Progress -Activity "Currently processing: $DisplayName" -Status "Updating CSV file"
    
    if ($AssignedRoles -ne $null) { 
        $ExportResult = [PSCustomObject]@{
            'Admin EmailAddress' = $Admin.UserPrincipalName
            'Admin Name'         = $DisplayName
            'Assigned Roles'     = ($AssignedRoles.DisplayName -join ',')
            'License Status'     = $LicenseStatus
            'SignIn Status'      = $SignInStatus
        }
        $ExportResult | Export-Csv -Path $OutputCsv -NoTypeInformation -Append  
    } 
}

function Process_RoleBasedAdminReport {
    param ($Role)
    $AdminList = Get-MgDirectoryRoleMember -DirectoryRoleId $Role.Id
    $RoleName = $Role.DisplayName

    if ($ExcludeGroups) {
        $AdminList = $AdminList | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.user' }
    }
    $AdminList = $AdminList | ForEach-Object {
        Get-MgUser -UserId $_.Id
    }

    if ($AdminList) {
        Write-Progress -Activity "Currently Processing $RoleName role" -Status "Updating CSV file"
        $ExportResults = @()
        foreach ($Admin in $AdminList) {
            $ExportResult = [PSCustomObject]@{
                'Role Name'        = $RoleName
                'Admin EmailAddress' = $Admin.UserPrincipalName
                'Admin Name'       = $Admin.DisplayName
                'Admin Count'      = $AdminList.Count
            }
            $ExportResults += $ExportResult
        }
        $ExportResults | Export-Csv -Path $OutputCsv -NoTypeInformation -Append
    }
}

# Generate role-based admin report
if ($RoleBasedAdminReport) { 
    Get-MgDirectoryRole -All | ForEach-Object { 
        Process_RoleBasedAdminReport -Role $_ 
    } 
}

# Get admin roles for specific user
elseif ($AdminName -ne "") { 
    $AllUPNs = $AdminName.Split(",")
    ForEach ($Admin in $AllUPNs) { 
        $Admin = Get-MgUser -UserId $Admin -ErrorAction SilentlyContinue 
        if ($Admin -eq $null) { 
            Write-host "$Admin is not available. Please check the input" -ForegroundColor Red 
        } else { 
            Process_AdminReport -Admin $Admin
        } 
    }
}

# Get all admins for a specific role
elseif ($RoleName -ne "") { 
    $RoleNames = $RoleName.Split(",")
    ForEach ($Name in $RoleNames) { 
        $Role = Get-MgDirectoryRole -Filter "DisplayName eq '$Name'" -ErrorAction SilentlyContinue 
        if ($Role -eq $null) { 
            Write-Host "$Name role is not available. Please check the input" -ForegroundColor Red 
        } else { 
            Process_RoleBasedAdminReport -Role $Role
        } 
    } 
}

# Generate all admins report
else { 
    Get-MgUser -All | ForEach-Object { 
        Process_AdminReport -Admin $_
    } 
}

# Open output file after execution 
if (Test-Path -Path $OutputCsv) { 
    Write-Host `n "The Output file is available in:" -NoNewline -ForegroundColor Yellow; Write-Host "$OutputCsv" `n 
    $prompt = New-Object -ComObject wscript.shell    
    $UserInput = $prompt.popup("Do you want to open the output file?", 0, "Open Output File", 4)    
    if ($UserInput -eq 6) {    
        Invoke-Item "$OutputCsv"  
        Write-Host "Report generated successfully"
    }
} else {
    Write-Host "No data found" -ForegroundColor Red
}

Write-Host `n~~ Script prepared by Shaun Hardneck ~~`n -ForegroundColor Green
Write-Host "~~ Check out " -NoNewline -ForegroundColor Green; Write-Host "www.thatlazyadmin.com" -ForegroundColor Yellow -NoNewline; Write-Host " for more Microsoft 365 tips and scripts. ~~" -ForegroundColor Green `n`n
Disconnect-MgGraph | Out-Null