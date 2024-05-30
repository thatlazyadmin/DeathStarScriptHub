# Import necessary modules
#Import-Module Az
#Import-Module Microsoft.Graph
#Import-Module AzureAD
#Import-Module ImportExcel

# Connect to Azure and silence warnings
$tenantId = "f8a9f5a5-fbb5-4c50-9f67-84b1899a9f74"
Connect-AzAccount -Tenant $tenantId -ErrorAction SilentlyContinue | Out-Null
Connect-MgGraph -Scopes "User.Read.All" -ErrorAction SilentlyContinue | Out-Null
Connect-AzureAD -ErrorAction SilentlyContinue | Out-Null

# Function to check and output control compliance status
function Check-Control {
    param (
        [string]$SubscriptionId,
        [string]$ControlId,
        [string]$ControlName,
        [bool]$IsCompliant,
        [ref]$Results
    )
    $result = [PSCustomObject]@{
        SubscriptionId = $SubscriptionId
        ControlId      = $ControlId
        ControlName    = $ControlName
        Status         = if ($IsCompliant) { "Green" } else { "Red" }
    }
    $Results.Value += $result
    if ($IsCompliant) {
        Write-Host "$ControlId - $ControlName : Green" -ForegroundColor Green
    } else {
        Write-Host "$ControlId - $ControlName : Red" -ForegroundColor Red
    }
}

# Initialize results array
$Results = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    Set-AzContext -Subscription $subscription.Id -ErrorAction SilentlyContinue

    Write-Host "Checking compliance for subscription: $($subscription.Name)"

    # Identity and Access Management

    # 1.1.1 Ensure Security Defaults is enabled on Microsoft Entra ID
    try {
        $securityDefaults = Get-AzureADDirectorySetting | Where-Object { $_.DisplayName -eq "SecurityDefaults" }
        $securityDefaultsEnabled = $securityDefaults.Values | Where-Object { $_.Name -eq "EnableSecurityDefaults" } | Select-Object -ExpandProperty Value
        Check-Control $subscription.Id "1.1.1" "Ensure Security Defaults is enabled on Microsoft Entra ID" ($securityDefaultsEnabled -eq "True") ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.1.1" "Ensure Security Defaults is enabled on Microsoft Entra ID" $false ([ref]$Results)
    }

    # 1.1.2 Ensure that 'Multi-Factor Auth Status' is 'Enabled' for all Privileged Users
    try {
        $privilegedRoles = @("Global Administrator", "Privileged Role Administrator", "Exchange Administrator", "SharePoint Administrator", "User Administrator", "Security Administrator", "Helpdesk Administrator")
        $privilegedUsers = @()
        foreach ($role in $privilegedRoles) {
            $privilegedUsers += Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -eq $role } | Get-AzureADDirectoryRoleMember
        }
        $nonCompliantUsers = $privilegedUsers | Where-Object { -not $_.StrongAuthenticationMethods }
        Check-Control $subscription.Id "1.1.2" "Ensure Multi-Factor Auth Status is Enabled for all Privileged Users" ($nonCompliantUsers.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.1.2" "Ensure Multi-Factor Auth Status is Enabled for all Privileged Users" $false ([ref]$Results)
    }

    # 1.1.4 Ensure that 'Allow users to remember multi-factor authentication on devices they trust' is Disabled
    try {
        $rememberMFASetting = Get-MsolCompanyInformation | Select-Object -ExpandProperty UsersAllowedToRememberMultiFactorAuthenticationOnTrustedDevicesEnabled
        Check-Control $subscription.Id "1.1.4" "Ensure that 'Allow users to remember multi-factor authentication on devices they trust' is Disabled" (-not $rememberMFASetting) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.1.4" "Ensure that 'Allow users to remember multi-factor authentication on devices they trust' is Disabled" $false ([ref]$Results)
    }

    # 1.2.1 Ensure Trusted Locations Are Defined
    try {
        $trustedLocations = Get-AzureADMSNamedLocationPolicy | Where-Object { $_.IsTrusted -eq $true }
        Check-Control $subscription.Id "1.2.1" "Ensure Trusted Locations Are Defined" ($trustedLocations.Count -gt 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.2.1" "Ensure Trusted Locations Are Defined" $false ([ref]$Results)
    }

    # Microsoft Defender for Cloud

    # 2.1.1 Ensure that Microsoft Defender for Servers is set to 'On'
    try {
        $defenderForServers = Get-AzSecurityPricing -Name "VirtualMachines"
        Check-Control $subscription.Id "2.1.1" "Ensure that Microsoft Defender for Servers is set to 'On'" ($defenderForServers.PricingTier -eq "Standard") ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "2.1.1" "Ensure that Microsoft Defender for Servers is set to 'On'" $false ([ref]$Results)
    }

    # Storage Accounts

    # 3.1 Ensure that 'Secure transfer required' is set to 'Enabled' for Storage Accounts
    try {
        $storageAccounts = Get-AzStorageAccount
        $nonCompliantStorageAccounts = $storageAccounts | Where-Object { $_.EnableHttpsTrafficOnly -eq $false }
        Check-Control $subscription.Id "3.1" "Ensure that 'Secure transfer required' is set to 'Enabled'" ($nonCompliantStorageAccounts.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "3.1" "Ensure that 'Secure transfer required' is set to 'Enabled'" $false ([ref]$Results)
    }

    # 3.2 Ensure that 'Enable Infrastructure Encryption' for each Storage Account is set to 'Enabled'
    try {
        $nonCompliantStorageAccountsInfra = $storageAccounts | Where-Object { $_.InfrastructureEncryption -eq $false }
        Check-Control $subscription.Id "3.2" "Ensure that 'Enable Infrastructure Encryption' is set to 'Enabled'" ($nonCompliantStorageAccountsInfra.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "3.2" "Ensure that 'Enable Infrastructure Encryption' is set to 'Enabled'" $false ([ref]$Results)
    }

    # Database Services

    # 4.1.1 Ensure that 'Auditing' is set to 'On' for SQL Servers
    try {
        $sqlServers = Get-AzSqlServer
        $nonCompliantSqlServers = $sqlServers | Where-Object { (Get-AzSqlServerAuditing -ResourceGroupName $_.ResourceGroupName -ServerName $_.ServerName).State -ne "Enabled" }
        Check-Control $subscription.Id "4.1.1" "Ensure that 'Auditing' is set to 'On' for SQL Servers" ($nonCompliantSqlServers.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "4.1.1" "Ensure that 'Auditing' is set to 'On' for SQL Servers" $false ([ref]$Results)
    }

    # Logging and Monitoring

    # 5.1.1 Ensure that a 'Diagnostic Setting' exists for Subscription Activity Logs
    try {
        $activityLogs = Get-AzDiagnosticSetting -ResourceId (Get-AzSubscription).Id
        Check-Control $subscription.Id "5.1.1" "Ensure that a 'Diagnostic Setting' exists for Subscription Activity Logs" ($activityLogs.Count -gt 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "5.1.1" "Ensure that a 'Diagnostic Setting' exists for Subscription Activity Logs" $false ([ref]$Results)
    }

    # Networking

    # 6.1 Ensure that RDP access from the Internet is evaluated and restricted
    try {
        $nsgRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroupName $_.Name -ResourceGroupName $_.ResourceGroupName
        $nonCompliantRdp = $nsgRules | Where-Object { $_.DestinationPortRange -eq "3389" -and $_.Access -eq "Allow" -and $_.Direction -eq "Inbound" }
        Check-Control $subscription.Id "6.1" "Ensure that RDP access from the Internet is evaluated and restricted" ($nonCompliantRdp.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "6.1" "Ensure that RDP access from the Internet is evaluated and restricted" $false ([ref]$Results)
    }

    # 6.2 Ensure that SSH access from the Internet is evaluated and restricted
    try {
        $nonCompliantSsh = $nsgRules | Where-Object { $_.DestinationPortRange -eq "22" -and $_.Access -eq "Allow" -and $_.Direction -eq "Inbound" }
        Check-Control $subscription.Id "6.2" "Ensure that SSH access from the Internet is evaluated and restricted" ($nonCompliantSsh.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "6.2" "Ensure that SSH access from the Internet is evaluated and restricted" $false ([ref]$Results)
    }

    # Virtual Machines

    # 7.1 Ensure an Azure Bastion Host Exists
    try {
        $bastionHosts = Get-AzBastion
        Check-Control $subscription.Id "7.1" "Ensure an Azure Bastion Host Exists" ($bastionHosts.Count -gt 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "7.1" "Ensure an Azure Bastion Host Exists" $false ([ref]$Results)
    }

    # 7.2 Ensure Virtual Machines are utilizing Managed Disks
    try {
        $vms = Get-AzVM
        $nonCompliantVms = $vms | Where-Object { $_.StorageProfile.OsDisk.ManagedDisk -eq $null }
        Check-Control $subscription.Id "7.2" "Ensure Virtual Machines are utilizing Managed Disks" ($nonCompliantVms.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "7.2" "Ensure Virtual Machines are utilizing Managed Disks" $false ([ref]$Results)
    }

    # Key Vault

    # 8.1 Ensure that the Expiration Date is set for all Keys and Secrets in RBAC Key Vaults
    try {
        $keyVaults = Get-AzKeyVault
        $nonCompliantKeyVaults = $keyVaults | Where-Object { 
            (Get-AzKeyVaultKey -VaultName $_.VaultName).KeyAttributes.Expires -eq $null -or 
            (Get-AzKeyVaultSecret -VaultName $_.VaultName).SecretAttributes.Expires -eq $null 
        }
        Check-Control $subscription.Id "8.1" "Ensure that the Expiration Date is set for all Keys and Secrets in RBAC Key Vaults" ($nonCompliantKeyVaults.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "8.1" "Ensure that the Expiration Date is set for all Keys and Secrets in RBAC Key Vaults" $false ([ref]$Results)
    }

    # 8.2 Ensure that Private Endpoints are used for Azure Key Vault
    try {
        $nonCompliantKeyVaultsPrivateEndpoint = $keyVaults | Where-Object { (Get-AzKeyVaultPrivateEndpointConnection -VaultName $_.VaultName).PrivateLinkServiceConnectionState.Status -ne "Approved" }
        Check-Control $subscription.Id "8.2" "Ensure that Private Endpoints are used for Azure Key Vault" ($nonCompliantKeyVaultsPrivateEndpoint.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "8.2" "Ensure that Private Endpoints are used for Azure Key Vault" $false ([ref]$Results)
    }

    # App Service

    # 9.1 Ensure App Service Authentication is set up for apps in Azure App Service
    try {
        $appServices = Get-AzWebApp
        $nonCompliantAppServicesAuth = $appServices | Where-Object { (Get-AzWebAppAuthSettings -ResourceGroupName $_.ResourceGroup -Name $_.Name).Enabled -eq $false }
        Check-Control $subscription.Id "9.1" "Ensure App Service Authentication is set up for apps in Azure App Service" ($nonCompliantAppServicesAuth.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "9.1" "Ensure App Service Authentication is set up for apps in Azure App Service" $false ([ref]$Results)
    }

    # 9.2 Ensure Web App redirects all HTTP traffic to HTTPS in Azure App Service
    try {
        $nonCompliantAppServicesHttps = $appServices | Where-Object { (Get-AzWebApp -ResourceGroupName $_.ResourceGroup -Name $_.Name).HttpsOnly -eq $false }
        Check-Control $subscription.Id "9.2" "Ensure Web App redirects all HTTP traffic to HTTPS in Azure App Service" ($nonCompliantAppServicesHttps.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "9.2" "Ensure Web App redirects all HTTP traffic to HTTPS in Azure App Service" $false ([ref]$Results)
    }

    Write-Host "Completed compliance check for subscription: $($subscription.Name)"
}

# Output results to Excel
$Results | Export-Excel -Path ".\CIS_Compliance_Results.xlsx" -AutoSize -Title "CIS Compliance Results"

Write-Host "CIS Benchmark Compliance Check Completed"
