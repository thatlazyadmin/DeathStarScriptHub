# Connect to Azure AD
try {
    Connect-AzureAD
} catch {
    Write-Error "Failed to connect to Azure AD. Please ensure you have the AzureAD module installed."
    exit
}

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "User.Read.All","DeviceManagementManagedDevices.Read.All","Device.Read.All","Directory.Read.All"
} catch {
    Write-Error "Failed to connect to Microsoft Graph. Please ensure you have the Microsoft Graph PowerShell SDK installed."
    exit
}

# Export Stale Devices
$staleDevices = Get-MgDeviceManagementManagedDevice -Filter "lastSyncDateTime lt 2023-01-01 and deviceManagementType eq 'mdm'" # Update date as needed
$staleDevices | Export-Csv -Path "./StaleDevices.csv" -NoTypeInformation

# Export Unmanaged Devices
$unmanagedDevices = Get-MgDevice -All | Where-Object { $_.DeviceTrustType -eq 'Unmanaged' }
$unmanagedDevices | Export-Csv -Path "./UnmanagedDevices.csv" -NoTypeInformation

# Devices Not Connected to Intune
$notIntuneDevices = Get-MgDeviceManagementManagedDevice -Filter "deviceManagementType ne 'mdm'"
$notIntuneDevices | Export-Csv -Path "./NotIntuneDevices.csv" -NoTypeInformation

# Export User Accounts in Entra
$guestAccounts = Get-AzureADUser -Filter "userType eq 'Guest'" | Select-Object DisplayName, UserPrincipalName, UserType, @{Name='LastSignIn';Expression={(Get-MgAuditLogSignIn -Filter "userId eq '$($_.ObjectId)'").SignInDateTime | Sort-Object -Descending | Select-Object -First 1}}
$guestAccounts | Export-Csv -Path "./GuestAccounts.csv" -NoTypeInformation

$cloudOnlyAccounts = Get-AzureADUser -All $true | Where-Object { $_.OnPremisesSyncEnabled -eq $false } | Select-Object DisplayName, UserPrincipalName, UserType, @{Name='LastSignIn';Expression={(Get-MgAuditLogSignIn -Filter "userId eq '$($_.ObjectId)'").SignInDateTime | Sort-Object -Descending | Select-Object -First 1}}
$cloudOnlyAccounts | Export-Csv -Path "./CloudOnlyAccounts.csv" -NoTypeInformation

Write-Output "Export Completed Successfully."