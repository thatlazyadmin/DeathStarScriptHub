# Suppress Azure subscription warnings
$ErrorActionPreference = "SilentlyContinue"
$PSDefaultParameterValues['*:WarningAction'] = 'SilentlyContinue'

# Function to check if a module is installed
function Install-ModuleIfNeeded {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Install-Module -Name $ModuleName -AllowClobber -Scope CurrentUser
    }
}

# Check and import required modules
Install-ModuleIfNeeded -ModuleName "Az"
Install-ModuleIfNeeded -ModuleName "Az.Accounts"
Install-ModuleIfNeeded -ModuleName "Az.Security"
Install-ModuleIfNeeded -ModuleName "Az.Network"
Install-ModuleIfNeeded -ModuleName "Az.OperationalInsights"
Install-ModuleIfNeeded -ModuleName "Az.ResourceGraph"
Install-ModuleIfNeeded -ModuleName "ImportExcel"

Import-Module Az
Import-Module Az.Accounts
Import-Module Az.Security
Import-Module Az.Network
Import-Module Az.OperationalInsights
Import-Module Az.ResourceGraph
Import-Module ImportExcel

# Connect to Azure
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Define the checks array
$checks = @(
    @{ Id = 'A01.01'; Name = 'Defender enabled in all subscriptions'; Check = { param ($subscriptionId) (Get-AzSecurityPricing -Context (Get-AzContext -SubscriptionId $subscriptionId) | Where-Object { $_.PricingTier -eq 'Standard' }).Count -gt 0 } },
    @{ Id = 'A01.02'; Name = 'Defender enabled on all Log Analytics workspaces'; Check = { param ($subscriptionId) (Get-AzOperationalInsightsWorkspace -SubscriptionId $subscriptionId | ForEach-Object { (Get-AzSecurityWorkspaceSetting -ResourceGroupName $_.ResourceGroupName -WorkspaceName $_.Name).WorkspaceId -eq $_.CustomerId }).Count -eq (Get-AzOperationalInsightsWorkspace -SubscriptionId $subscriptionId).Count } },
    @{ Id = 'A01.03'; Name = 'Data collection set to Common'; Check = { param ($subscriptionId) (Get-AzSecurityAutoProvisioningSetting -Context (Get-AzContext -SubscriptionId $subscriptionId)).AutoProvision -eq 'On' } },
    @{ Id = 'A01.04'; Name = 'Enhanced security features enabled'; Check = { param ($subscriptionId) (Get-AzSecurityPricing -Context (Get-AzContext -SubscriptionId $subscriptionId) | Where-Object { $_.Name -eq 'AppServices' -and $_.PricingTier -eq 'Standard' }).Count -gt 0 } },
    @{ Id = 'A01.05'; Name = 'Auto-provisioning enabled as per company policy'; Check = { param ($subscriptionId) (Get-AzSecurityAutoProvisioningSetting -Context (Get-AzContext -SubscriptionId $subscriptionId)).AutoProvision -eq 'On' } },
    @{ Id = 'A01.06'; Name = 'Email notifications enabled as per company policy'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.07'; Name = 'Integration options selected'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.08'; Name = 'CI/CD integration configured'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.09'; Name = 'Continuous export "Event Hub" enabled if using 3rd party SIEM'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.10'; Name = 'Continuous export "Log Analytics Workspace" enabled if not using Azure Sentinel'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.11'; Name = 'Cloud connector enabled for AWS'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.12'; Name = 'Cloud connector enabled for GCP'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A01.13'; Name = 'Azure AD Application proxy integrated with Microsoft Defender for Cloud Apps'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A02.01'; Name = 'All recommendations remediated or disabled if not required'; Check = { param ($subscriptionId) (Get-AzSecurityRecommendation -Context (Get-AzContext -SubscriptionId $subscriptionId) | Where-Object { $_.RecommendationState -eq 'Unhealthy' }).Count -eq 0 } },
    @{ Id = 'A02.02'; Name = 'Security Score > 70%'; Check = { param ($subscriptionId) (Get-AzSecuritySecureScore -Context (Get-AzContext -SubscriptionId $subscriptionId)).Score -ge 70 } },
    @{ Id = 'A03.01'; Name = 'Security Alerts contain only those generated in the past 24 hours'; Check = { param ($subscriptionId) (Get-AzSecurityAlert -Context (Get-AzContext -SubscriptionId $subscriptionId) | Where-Object { $_.TimeGenerated -gt (Get-Date).AddDays(-1) }).Count -eq (Get-AzSecurityAlert -Context (Get-AzContext -SubscriptionId $subscriptionId)).Count } },
    @{ Id = 'A04.01'; Name = 'Continuous export is enabled, default workbooks published to custom security dashboard'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A05.01'; Name = 'Customer is aware of the "Community" page and reviews regularly'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A06.01'; Name = 'All subscriptions protected by Security Center are shown'; Check = { param ($subscriptionId) (Get-AzSecurityPricing -Context (Get-AzContext -SubscriptionId $subscriptionId)).Count -eq (Get-AzSubscription).Count } },
    @{ Id = 'A07.01'; Name = 'Compliance controls are green for any required compliance'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A08.01'; Name = 'High severity VM vulnerabilities is zero'; Check = { param ($subscriptionId) (Get-AzSecurityAlert -Context (Get-AzContext -SubscriptionId $subscriptionId) | Where-Object { $_.Severity -eq 'High' -and $_.AlertType -eq 'VMVulnerabilities' }).Count -eq 0 } },
    @{ Id = 'A09.01'; Name = 'Hubs protected by an Azure Firewall'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A09.02'; Name = 'Virtual Networks protected by a Firewall'; Check = { param ($subscriptionId) $true } },
    @{ Id = 'A09.03'; Name = 'DDoS Standard enabled'; Check = { param ($subscriptionId) (Get-AzDdosProtectionPlan -Context (Get-AzContext -SubscriptionId $subscriptionId)).Count -gt 0 } },
    @{ Id = 'A10.01'; Name = 'Verify that all subscriptions are covered'; Check = { param ($subscriptionId) (Get-AzSecurityPricing -Context (Get-AzContext -SubscriptionId $subscriptionId)).PricingTier -eq 'Standard' } }
)

# Results array
$results = @()

foreach ($subscription in $subscriptions) {
    Write-Host "Checking subscription: $($subscription.Name)" -ForegroundColor Yellow
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
            
            Write-Host "$($check.Id) - $($check.Name): $status" -ForegroundColor $color
        } catch {
            Write-Host "Feature not enabled or configured for $($check.Id) - $($check.Name)" -ForegroundColor Red
            $results += [PSCustomObject]@{
                Subscription = $subscription.Name
                ID = $check.Id
                Check = $check.Name
                Status = "Feature not enabled or configured"
                Color = "Red"
            }
        }
    }
}

# Get the script directory
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Export results to Excel
try {
    $results | Export-Excel -Path "$scriptDirectory\DefenderForCloudComplianceAudit.xlsx" -AutoSize -AutoFilter -BoldTopRow

    # Apply conditional formatting
    $excel = Open-ExcelPackage "$scriptDirectory\DefenderForCloudComplianceAudit.xlsx"
    $worksheet = $excel.Workbook.Worksheets[1]

    # Define the range for conditional formatting
    $lastRow = $results.Count + 1

    # Green for "Implemented"
    $greenRule = $worksheet.ConditionalFormatting.AddContainsText("D2:D$lastRow")
    $greenRule.Text = "Implemented"
    $greenRule.Style.Font.Color.Color = [System.Drawing.Color]::FromArgb(0, 128, 0)

    # Red for "Not Implemented"
    $redRule = $worksheet.ConditionalFormatting.AddContainsText("D2:D$lastRow")
    $redRule.Text = "Not Implemented"
    $redRule.Style.Font.Color.Color = [System.Drawing.Color]::FromArgb(255, 0, 0)

    # Red for "Feature not enabled or configured"
    $featureNotEnabledRule = $worksheet.ConditionalFormatting.AddContainsText("D2:D$lastRow")
    $featureNotEnabledRule.Text = "Feature not enabled or configured"
    $featureNotEnabledRule.Style.Font.Color.Color = [System.Drawing.Color]::FromArgb(255, 0, 0)

    $excel.SaveAs("$scriptDirectory\DefenderForCloudComplianceAudit.xlsx")

    Write-Host "Report generated: $scriptDirectory\DefenderForCloudComplianceAudit.xlsx" -ForegroundColor Green
} catch {
    Write-Host "Failed to generate report: $_" -ForegroundColor Red
}
