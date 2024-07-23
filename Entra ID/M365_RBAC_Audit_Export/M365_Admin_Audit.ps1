# Ensure the Microsoft.Graph module is installed and imported
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}

# Import-Module Microsoft.Graph

# Connect to Microsoft Graph with necessary Graph API Permissions
Connect-MgGraph -Scopes "User.Read.All", "RoleManagement.Read.Directory" -NoWelcome

# Get all directory roles
$roles = Get-MgDirectoryRole

# Find the role ID for global administrators
$globalAdminRole = $roles | Where-Object { $_.DisplayName -eq "Global Administrator" }

# Initialize counts and arrays for storing details
$totalGlobalAdmins = 0
$globalAdminDetails = @()

# Get the members of the global administrator role
if ($globalAdminRole -ne $null) {
    $globalAdmins = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id -All
    $totalGlobalAdmins = $globalAdmins.Count
    $globalAdmins | ForEach-Object {
        $user = Get-MgUser -UserId $_.Id
        $globalAdminDetails += [PSCustomObject]@{
            DisplayName = $user.DisplayName
            Email = $user.UserPrincipalName
        }
    }
}

Write-Output "Total Global Administrators: $totalGlobalAdmins"
Write-Output "Global Administrators Details:"
$globalAdminDetails | Format-Table -AutoSize