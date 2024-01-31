# Check if Microsoft Graph PowerShell SDK is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft Graph PowerShell SDK is not installed. Please install it using 'Install-Module Microsoft.Graph -Scope CurrentUser'." -ForegroundColor Red
    exit
}

# Try to import Microsoft Graph module
#try {
#    Import-Module Microsoft.Graph -ErrorAction Stop
#} catch {
#    Write-Host "Failed to import Microsoft Graph PowerShell module. Please ensure it is installed correctly." -ForegroundColor Red
#    exit
#}

# Authenticate and connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.Directory"
} catch {
    Write-Host "Error connecting to Microsoft Graph. Please ensure you are logged in." -ForegroundColor Red
    exit
}

# Get all directory roles
$adminRoles = Get-MgDirectoryRole | Where-Object { $_.DisplayName -like "*admin*" }

# Check each role for members and their MFA status
foreach ($role in $adminRoles) {
    $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
    foreach ($member in $roleMembers) {
        $userId = $member.Id
        $user = Get-MgUser -UserId $userId
        $mfaMethods = Get-MgUserAuthenticationMethod -UserId $userId

        # Check if MFA methods are available for the user
        if ($null -eq $mfaMethods) {
            # Output user details in red to indicate critical finding
            Write-Host "User: $($user.DisplayName) - Role: $($role.DisplayName) - MFA: Not Enabled" -ForegroundColor Red
        }
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph