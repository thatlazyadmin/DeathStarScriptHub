<#
.SYNOPSIS
Microsoft Azure CIS Compliance Checker
.DESCRIPTION
This script checks compliance against the CIS benchmark for Azure.
It loops through all subscriptions and evaluates compliance with selected CIS controls.
The results are exported to an Excel file.
.NOTES
Created by: Shaun Hardneck
Blog: www.thatlazyadmin.com
#>

# Display Banner
$banner = @"
==============================================
     Microsoft Azure CIS Controls Checker
==============================================
"@
Write-Host $banner -ForegroundColor Green

# Prompt user to import required modules
$importModules = Read-Host "Do you want to import the required modules? (yes/no)"
if ($importModules -eq "yes") {
    Import-Module Az -ErrorAction SilentlyContinue
    Import-Module Microsoft.Graph -ErrorAction SilentlyContinue
    Import-Module AzureAD -ErrorAction SilentlyContinue
    Import-Module ImportExcel -ErrorAction SilentlyContinue
}

# Prompt for Azure Tenant ID in Cyan
Write-Host -ForegroundColor Cyan "Please enter the Azure Tenant ID:"
$tenantId = Read-Host

# Connect to Azure and silence warnings
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

Connect-AzAccount -Tenant $tenantId | Out-Null
Connect-MgGraph -Scopes "User.Read.All" | Out-Null
Connect-AzureAD | Out-Null

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

# Function to handle subscription
function Handle-Subscription {
    param (
        [PSObject]$subscription
    )
    Write-Host "`nChecking compliance for subscription: $($subscription.Name)" -ForegroundColor Yellow

    Set-AzContext -Subscription $subscription.Id -ErrorAction SilentlyContinue

    # Identity and Access Management
    try {
        $nonPrivilegedUsers = Get-AzureADUser | Where-Object { $_.UserType -eq "Member" -and $_.UserPrincipalName -notlike "*@domain.com" } # Replace with actual domain
        $nonCompliantUsers = $nonPrivilegedUsers | Where-Object { -not $_.StrongAuthenticationMethods }
        Check-Control $subscription.Id "1.1.3" "Ensure Multi-Factor Auth Status is Enabled for all Non-Privileged Users" ($nonCompliantUsers.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.1.3" "Ensure Multi-Factor Auth Status is Enabled for all Non-Privileged Users" $false ([ref]$Results)
    }

    try {
        $rememberMFASetting = Get-MsolCompanyInformation | Select-Object -ExpandProperty UsersAllowedToRememberMultiFactorAuthenticationOnTrustedDevicesEnabled
        Check-Control $subscription.Id "1.1.4" "Ensure that 'Allow users to remember multi-factor authentication on devices they trust' is Disabled" (-not $rememberMFASetting) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.1.4" "Ensure that 'Allow users to remember multi-factor authentication on devices they trust' is Disabled" $false ([ref]$Results)
    }

    try {
        $trustedLocations = Get-AzureADMSNamedLocationPolicy | Where-Object { $_.IsTrusted -eq $true }
        Check-Control $subscription.Id "1.2.1" "Ensure Trusted Locations Are Defined" ($trustedLocations.Count -gt 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "1.2.1" "Ensure Trusted Locations Are Defined" $false ([ref]$Results)
    }

    # Microsoft Defender for Cloud
    try {
        $defenderForServers = Get-AzSecurityPricing -Name "VirtualMachines"
        Check-Control $subscription.Id "2.1.1" "Ensure that Microsoft Defender for Servers is set to 'On'" ($defenderForServers.PricingTier -eq "Standard") ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "2.1.1" "Ensure that Microsoft Defender for Servers is set to 'On'" $false ([ref]$Results)
    }

    try {
        $defenderForAppServices = Get-AzSecurityPricing -Name "AppServices"
        Check-Control $subscription.Id "2.1.2" "Ensure that Microsoft Defender for App Services is set to 'On'" ($defenderForAppServices.PricingTier -eq "Standard") ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "2.1.2" "Ensure that Microsoft Defender for App Services is set to 'On'" $false ([ref]$Results)
    }

    # Storage Accounts
    try {
        $storageAccounts = Get-AzStorageAccount
        $nonCompliantStorageAccounts = $storageAccounts | Where-Object { $_.EnableHttpsTrafficOnly -eq $false }
        Check-Control $subscription.Id "3.1" "Ensure that 'Secure transfer required' is set to 'Enabled' for Storage Accounts" ($nonCompliantStorageAccounts.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "3.1" "Ensure that 'Secure transfer required' is set to 'Enabled' for Storage Accounts" $false ([ref]$Results)
    }

    try {
        $nonCompliantStorageAccounts = $storageAccounts | Where-Object { $_.EnableInfrastructureEncryption -eq $false }
        Check-Control $subscription.Id "3.2" "Ensure that 'Enable Infrastructure Encryption' for each Storage Account is set to 'Enabled'" ($nonCompliantStorageAccounts.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "3.2" "Ensure that 'Enable Infrastructure Encryption' for each Storage Account is set to 'Enabled'" $false ([ref]$Results)
    }

    # Database Services
    try {
        $sqlServers = Get-AzSqlServer
        $nonCompliantSqlServers = $sqlServers | Where-Object { $_.AuditingPolicy.State -ne "Enabled" }
        Check-Control $subscription.Id "4.1.1" "Ensure that 'Auditing' is set to 'On' for SQL Servers" ($nonCompliantSqlServers.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "4.1.1" "Ensure that 'Auditing' is set to 'On' for SQL Servers" $false ([ref]$Results)
    }

    try {
        $nonCompliantSqlServers = $sqlServers | Where-Object { $_.TransparentDataEncryption.State -ne "Enabled" -or $_.TransparentDataEncryption.KeyType -ne "CustomerManaged" }
        Check-Control $subscription.Id "4.1.3" "Ensure SQL server's Transparent Data Encryption (TDE) protector is encrypted with Customer-managed key" ($nonCompliantSqlServers.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "4.1.3" "Ensure SQL server's Transparent Data Encryption (TDE) protector is encrypted with Customer-managed key" $false ([ref]$Results)
    }

    # Logging and Monitoring
    try {
        $activityLogs = Get-AzDiagnosticSetting -ResourceId (Get-AzSubscription).Id
        Check-Control $subscription.Id "5.1.1" "Ensure that a 'Diagnostic Setting' exists for Subscription Activity Logs" ($activityLogs.Count -gt 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "5.1.1" "Ensure that a 'Diagnostic Setting' exists for Subscription Activity Logs" $false ([ref]$Results)
    }

    try {
        $nsgs = Get-AzNetworkSecurityGroup
        $nonCompliantNsgs = $nsgs | Where-Object { (Get-AzNetworkWatcherFlowLogStatus -ResourceGroupName $_.ResourceGroupName -NetworkSecurityGroupName $_.Name).Enabled -eq $false }
        Check-Control $subscription.Id "5.1.5" "Ensure that Network Security Group Flow logs are captured and sent to Log Analytics" ($nonCompliantNsgs.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "5.1.5" "Ensure that Network Security Group Flow logs are captured and sent to Log Analytics" $false ([ref]$Results)
    }

    # Networking
    try {
        $nonCompliantRdp = $nsgs | ForEach-Object {
            Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroupName $_.Name -ResourceGroupName $_.ResourceGroupName | Where-Object { $_.DestinationPortRange -eq "3389" -and $_.Access -eq "Allow" -and $_.Direction -eq "Inbound" }
        }
        Check-Control $subscription.Id "6.1" "Ensure that RDP access from the Internet is evaluated and restricted" ($nonCompliantRdp.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "6.1" "Ensure that RDP access from the Internet is evaluated and restricted" $false ([ref]$Results)
    }

    try {
        $nonCompliantSsh = $nsgs | ForEach-Object {
            Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroupName $_.Name -ResourceGroupName $_.ResourceGroupName | Where-Object { $_.DestinationPortRange -eq "22" -and $_.Access -eq "Allow" -and $_.Direction -eq "Inbound" }
        }
        Check-Control $subscription.Id "6.2" "Ensure that SSH access from the Internet is evaluated and restricted" ($nonCompliantSsh.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "6.2" "Ensure that SSH access from the Internet is evaluated and restricted" $false ([ref]$Results)
    }

    # Virtual Machines
    try {
        $bastionHosts = Get-AzBastion
        Check-Control $subscription.Id "7.1" "Ensure an Azure Bastion Host Exists" ($bastionHosts.Count -gt 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "7.1" "Ensure an Azure Bastion Host Exists" $false ([ref]$Results)
    }

    try {
        $vms = Get-AzVM
        $nonCompliantVms = $vms | Where-Object { $_.StorageProfile.OsDisk.ManagedDisk -eq $null }
        Check-Control $subscription.Id "7.2" "Ensure Virtual Machines are utilizing Managed Disks" ($nonCompliantVms.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "7.2" "Ensure Virtual Machines are utilizing Managed Disks" $false ([ref]$Results)
    }

    # Key Vault
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

    try {
        $nonCompliantKeyVaultsPrivateEndpoint = $keyVaults | Where-Object { (Get-AzKeyVaultPrivateEndpointConnection -VaultName $_.VaultName).PrivateLinkServiceConnectionState.Status -ne "Approved" }
        Check-Control $subscription.Id "8.2" "Ensure that Private Endpoints are used for Azure Key Vault" ($nonCompliantKeyVaultsPrivateEndpoint.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "8.2" "Ensure that Private Endpoints are used for Azure Key Vault" $false ([ref]$Results)
    }

    # App Service
    try {
        $appServices = Get-AzWebApp
        $nonCompliantAppServicesAuth = $appServices | Where-Object { (Get-AzWebAppAuthSettings -ResourceGroupName $_.ResourceGroup -Name $_.Name).Enabled -eq $false }
        Check-Control $subscription.Id "9.1" "Ensure App Service Authentication is set up for apps in Azure App Service" ($nonCompliantAppServicesAuth.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "9.1" "Ensure App Service Authentication is set up for apps in Azure App Service" $false ([ref]$Results)
    }

    try {
        $nonCompliantAppServicesHttps = $appServices | Where-Object { (Get-AzWebAppAuthSettings -ResourceGroupName $_.ResourceGroup -Name $_.Name).HttpsOnly -eq $false }
        Check-Control $subscription.Id "9.2" "Ensure Web App redirects all HTTP traffic to HTTPS in Azure App Service" ($nonCompliantAppServicesHttps.Count -eq 0) ([ref]$Results)
    } catch {
        Check-Control $subscription.Id "9.2" "Ensure Web App redirects all HTTP traffic to HTTPS in Azure App Service" $false ([ref]$Results)
    }

    Write-Host "Completed compliance check for subscription: $($subscription.Name)" -ForegroundColor Yellow
}

# Loop through all subscriptions
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Handle-Subscription -subscription $subscription
}

# Export results to Excel
$results | Export-Excel -Path "AzureCISComplianceReport.xlsx" -AutoSize -TableName "ComplianceResults"

# Open Excel file and format the report
$workbook = Open-ExcelPackage -Path "AzureCISComplianceReport.xlsx"
$worksheet = $workbook.Workbook.Worksheets["Results"]

# Add header styling
$worksheet.Cells["A1:D1"].Style.Font.Bold = $true
$worksheet.Cells["A1:D1"].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
$worksheet.Cells["A1:D1"].Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::LightGray)

# Separate subscriptions with a blank row
$lastRow = $worksheet.Dimension.End.Row
for ($i = $lastRow; $i -gt 1; $i--) {
    if ($worksheet.Cells["A$i"].Value -ne $worksheet.Cells["A$($i - 1)"].Value) {
        $worksheet.InsertRow($i, 1)
    }
}

Close-ExcelPackage $workbook

Write-Host "Compliance check completed. Results exported to AzureCISComplianceReport.xlsx" -ForegroundColor Green
