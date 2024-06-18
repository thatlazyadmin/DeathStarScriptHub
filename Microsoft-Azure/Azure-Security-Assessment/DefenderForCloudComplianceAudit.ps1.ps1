# Required Modules
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Import-Module Az.Accounts
Import-Module Az.Security
Import-Module Az.Network
Import-Module Az.OperationalInsights
Import-Module Az.ResourceGraph
Import-Module ImportExcel -Force

# Connect to Azure
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Define the checks array
$checks = @(
    @{ Id = 'A01.01'; Name = 'Defender enabled in all subscriptions'; Check = { (Get-AzSecurityPricing -SubscriptionId $args[0]).PricingTier -eq 'Standard' } },
    @{ Id = 'A01.02'; Name = 'Defender enabled on all Log Analytics workspaces'; Check = { (Get-AzOperationalInsightsWorkspace -SubscriptionId $args[0] | ForEach-Object { (Get-AzSecurityWorkspaceSetting -ResourceGroupName $_.ResourceGroupName -WorkspaceName $_.Name -SubscriptionId $args[0]).WorkspaceId -eq $_.CustomerId }).Count -eq (Get-AzOperationalInsightsWorkspace -SubscriptionId $args[0]).Count } },
    @{ Id = 'A01.03'; Name = 'Data collection set to Common'; Check = { (Get-AzSecurityAutoProvisioningSetting -SubscriptionId $args[0]).AutoProvision -eq 'On' } },
    @{ Id = 'A01.04'; Name = 'Enhanced security features enabled'; Check = { (Get-AzSecurityPricing -SubscriptionId $args[0]).PricingTier -eq 'Standard' } },
    @{ Id = 'A01.05'; Name = 'Auto-provisioning enabled as per company policy'; Check = { (Get-AzSecurityAutoProvisioningSetting -SubscriptionId $args[0]).AutoProvision -eq 'On' } },
    @{ Id = 'A01.06'; Name = 'Email notifications enabled as per company policy'; Check = { $true } },
    @{ Id = 'A01.07'; Name = 'Integration options selected'; Check = { $true } },
    @{ Id = 'A01.08'; Name = 'CI/CD integration configured'; Check = { $true } },
    @{ Id = 'A01.09'; Name = 'Continuous export "Event Hub" enabled if using 3rd party SIEM'; Check = { $true } },
    @{ Id = 'A01.10'; Name = 'Continuous export "Log Analytics Workspace" enabled if not using Azure Sentinel'; Check = { $true } },
    @{ Id = 'A01.11'; Name = 'Cloud connector enabled for AWS'; Check = { $true } },
    @{ Id = 'A01.12'; Name = 'Cloud connector enabled for GCP'; Check = { $true } },
    @{ Id = 'A01.13'; Name = 'Azure AD Application proxy integrated with Microsoft Defender for Cloud Apps'; Check = { $true } },
    @{ Id = 'A02.01'; Name = 'All recommendations remediated or disabled if not required'; Check = { (Get-AzSecurityRecommendation -SubscriptionId $args[0] | Where-Object { $_.RecommendationState -eq 'Unhealthy' }).Count -eq 0 } },
    @{ Id = 'A02.02'; Name = 'Security Score > 70%'; Check = { (Get-AzSecuritySecureScore -SubscriptionId $args[0]).Score -ge 70 } },
    @{ Id = 'A03.01'; Name = 'Security Alerts contain only those generated in the past 24 hours'; Check = { (Get-AzSecurityAlert -SubscriptionId $args[0] | Where-Object { $_.TimeGenerated -gt (Get-Date).AddDays(-1) }).Count -eq (Get-AzSecurityAlert -SubscriptionId $args[0]).Count } },
    @{ Id = 'A04.01'; Name = 'Continuous export is enabled, default workbooks published to custom security dashboard'; Check = { $true } },
    @{ Id = 'A05.01'; Name = 'Customer is aware of the "Community" page and reviews regularly'; Check = { $true } },
    @{ Id = 'A06.01'; Name = 'All subscriptions protected by Security Center are shown'; Check = { (Get-AzSecurityPricing -SubscriptionId $args[0]).Count -eq $subscriptions.Count } },
    @{ Id = 'A07.01'; Name = 'Compliance controls are green for any required compliance'; Check = { $true } },
    @{ Id = 'A08.01'; Name = 'High severity VM vulnerabilities is zero'; Check = { (Get-AzSecurityAlert -SubscriptionId $args[0] | Where-Object { $_.Severity -eq 'High' -and $_.AlertType -eq 'VMVulnerabilities' }).Count -eq 0 } },
    @{ Id = 'A09.01'; Name = 'Hubs protected by an Azure Firewall'; Check = { $true } },
    @{ Id = 'A09.02'; Name = 'Virtual Networks protected by a Firewall'; Check = { $true } },
    @{ Id = 'A09.03'; Name = 'DDoS Standard enabled'; Check = { (Get-AzDdosProtectionPlan -SubscriptionId $args[0]).Count -gt 0 } },
    @{ Id = 'A10.01'; Name = 'Verify that all subscriptions are covered'; Check = { (Get-AzSecurityPricing -SubscriptionId $args[0]).PricingTier -eq 'Standard' } }
)

# Results array
$results = @()

foreach ($subscription in $subscriptions) {
    Select-AzSubscription -SubscriptionId $subscription.Id
    foreach ($check in $checks) {
        try {
            $result = & $check.Check $subscription.Id
            $status = if ($result) { "Implemented" } else { "Not Implemented" }
            $color = if ($result) { "Green" } else { "Red" }
            
            $results += [PSCustomObject]@{
                Subscription = $subscription.Name
                ID = $check.Id
                Check = $check.Name
                Status = $status
                Color = $color
            }
            
            Write-Host "$($subscription.Name) - $($check.Id) - $($check.Name): $status" -ForegroundColor $color
        } catch {
            Write-Host "Error checking $($check.Id) - $($check.Name): $_" -ForegroundColor Red
            $results += [PSCustomObject]@{
                Subscription = $subscription.Name
                ID = $check.Id
                Check = $check.Name
                Status = "Error"
                Color = "Red"
            }
        }
    }
}

# Export results to Excel
$results | Export-Excel -Path "./AzureDefenderForCloudFullReport.xlsx" -AutoSize -AutoFilter -BoldTopRow -ConditionalText @{ Condition = 'Implemented'; Color = 'Green' }, @{ Condition = 'Not Implemented'; Color = 'Red' }

Write-Host "Report generated: AzureDefenderForCloudFullReport.xlsx"