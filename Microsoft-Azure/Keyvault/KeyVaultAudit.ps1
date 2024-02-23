# Starting the authentication process
$ErrorActionPreference = "Stop"
try {
    Connect-AzAccount
} catch {
    Write-Host "Error during authentication: $_" -ForegroundColor Red
    exit
}

# Importing required modules
#Import-Module Az.Accounts
#Import-Module Az.KeyVault

# Prepare an array to hold the results
$results = @()

# Getting all subscriptions the user has access to
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    # Attempting to set the context for the current subscription
    try {
        $null = Set-AzContext -SubscriptionId $subscription.Id
    } catch {
        Write-Host "Skipping subscription $($subscription.Name) due to authentication issue: $_" -ForegroundColor DarkYellow
        continue
    }

    Write-Host "Auditing Key Vaults in subscription: $($subscription.Name)" -ForegroundColor DarkYellow

    # Fetching all Key Vaults in the current subscription
    $keyVaults = Get-AzKeyVault

    foreach ($keyVault in $keyVaults) {
        $publicAccessAllowed = $false
        $firewallEnabledWithVNetRestrictions = $false

        if ($keyVault.NetworkAcls -ne $null) {
            $publicAccessAllowed = $keyVault.NetworkAcls.DefaultAction -eq 'Allow'
            $firewallEnabledWithVNetRestrictions = $keyVault.NetworkAcls.DefaultAction -eq 'Deny' -and ($keyVault.NetworkAcls.VirtualNetworkRules.Count -gt 0)
        }

        $result = @{
            "SubscriptionName" = $subscription.Name
            "KeyVaultName"     = $keyVault.VaultName
            "PublicAccess"     = $publicAccessAllowed
            "VNetRestrictions" = $firewallEnabledWithVNetRestrictions
        }
        $results += New-Object PSObject -Property $result
    }
}

# Displaying the results on screen
$results | ForEach-Object {
    Write-Host "Subscription: $($_.SubscriptionName), Key Vault: $($_.KeyVaultName), Public Access: $($_.PublicAccess), VNet Restrictions: $($_.VNetRestrictions)" -ForegroundColor DarkYellow
}

# Exporting results to CSV
$results | Export-Csv -Path "KeyVaultAuditResults.csv" -NoTypeInformation

Write-Host "Audit completed. Results are saved to KeyVaultAuditResults.csv" -ForegroundColor DarkYellow
