# Required Modules
Install-Module -Name Microsoft.Graph.Intune -Force -AllowClobber
Install-Module -Name Microsoft.Graph.Security -Force -AllowClobber

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All","DeviceManagementConfiguration.ReadWrite.All" -NoWelcome

# Define function to check Defender for Endpoint Enforcement scope
function Get-DefenderEnforcementScope {
    $enforcementScope = Get-MgDeviceManagementConfigurationPolicy -Filter "displayName eq 'Defender for Endpoint Enforcement scope'"
    if ($enforcementScope -ne $null) {
        Write-Host "Defender for Endpoint Enforcement scope: $($enforcementScope.DisplayName)"
    } else {
        Write-Host "Defender for Endpoint Enforcement scope is not configured."
    }
}

# Define function to check Configuration Management
function Get-ConfigurationManagement {
    $configManagement = Get-MgDeviceManagementConfigurationPolicy -Filter "displayName eq 'Configuration Management'"
    if ($configManagement -ne $null) {
        Write-Host "Configuration Management: $($configManagement.DisplayName)"
        Write-Host "Windows Client Devices: $($configManagement.WindowsClientDevices)"
        Write-Host "Windows Server Devices: $($configManagement.WindowsServerDevices)"
    } else {
        Write-Host "Configuration Management is not configured."
    }
}

# Define function to check Security settings management for Microsoft Defender for Cloud
function Get-SecuritySettingsManagement {
    $securitySettings = Get-MgDeviceManagementConfigurationPolicy -Filter "displayName eq 'Security settings management for Microsoft Defender for Cloud'"
    if ($securitySettings -ne $null) {
        Write-Host "Security settings management: $($securitySettings.DisplayName)"
        Write-Host "Status: $($securitySettings.Status)"
    } else {
        Write-Host "Security settings management is not configured."
    }
}

# Define function to check Intune Endpoint Security settings
function Get-IntuneEndpointSecuritySettings {
    $intuneEndpointSecurity = Get-MgDeviceManagementConfigurationPolicy -Filter "displayName eq 'Intune Endpoint Security settings'"
    if ($intuneEndpointSecurity -ne $null) {
        Write-Host "Intune Endpoint Security settings: $($intuneEndpointSecurity.DisplayName)"
        Write-Host "Allow Microsoft Defender for Endpoint to enforce Endpoint Security Configurations: $($intuneEndpointSecurity.AllowMicrosoftDefenderForEndpointToEnforce)"
    } else {
        Write-Host "Intune Endpoint Security settings are not configured."
    }
}

# Execute functions to check the settings
Get-DefenderEnforcementScope
Get-ConfigurationManagement
Get-SecuritySettingsManagement
Get-IntuneEndpointSecuritySettings
