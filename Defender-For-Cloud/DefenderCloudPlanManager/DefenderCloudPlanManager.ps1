<#
.SYNOPSIS
Comprehensive management tool for Microsoft Defender for Cloud.
.DESCRIPTION
This script connects to Microsoft Defender for Cloud, generates a detailed Excel report on the current configuration status across all subscriptions, enables Defender plans as required, and provides manual control options.
.AUTHOR
Shaun Hardneck
.BLOG
www.thatlazyadmin.com
#>

function Connect-DefenderForCloud {
    Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
    Install-Module -Name Az.Security -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.Security

    Connect-AzAccount -UseDeviceAuthentication
    $subscriptions = Get-AzSubscription

    $report = @()
    foreach ($sub in $subscriptions) {
        Select-AzSubscription -SubscriptionId $sub.Id
        $defenderStatus = Get-AzSecurityPricing
        $report += [PSCustomObject]@{
            SubscriptionId = $sub.Id
            SubscriptionName = $sub.Name
            PlanDetails = ($defenderStatus | Format-Table | Out-String)
        }
    }

    $report | Export-Excel -Path "./DefenderForCloudStatus.xlsx" -AutoSize -TableName "DefenderStatus"
}

function Enable-DefenderPlans {
    $subscriptions = Get-AzSubscription

    foreach ($sub in $subscriptions) {
        Select-AzSubscription -SubscriptionId $sub.Id
        $plans = @('Defender for Servers', 'Defender for Storage', 'Defender for SQL', 'Defender for Containers', 'Defender for App Service', 'Defender for Key Vault', 'Defender for Resource Manager', 'Defender for DNS')
        
        foreach ($plan in $plans) {
            Enable-AzSecurityPricing -PricingTier 'Standard' -Name $plan
        }

        Write-Output "Enabled all Defender plans for subscription: $($sub.Name)"
    }
}

function Selective-EnableDefenderPlans {
    $subscription = Select-Subscription
    Select-AzSubscription -SubscriptionId $subscription.Id

    $plans = @('Defender for Servers', 'Defender for Storage', 'Defender for SQL', 'Defender for Containers', 'Defender for App Service', 'Defender for Key Vault', 'Defender for Resource Manager', 'Defender for DNS')
    Write-Output "Available Plans: "
    $plans | ForEach-Object { Write-Output $_ }
    $selectedPlans = Read-Host "Enter the plans to enable (comma-separated)"

    foreach ($plan in $selectedPlans.Split(',')) {
        Enable-AzSecurityPricing -PricingTier 'Standard' -Name $plan.Trim()
        Write-Output "Enabled $plan for Subscription: $($subscription.Name)"
    }
}

function Onboard-DefenderForCloud {
    $subscription = Select-Subscription
    Select-AzSubscription -SubscriptionId $subscription.Id

    $workspaces = Get-AzOperationalInsightsWorkspace
    Write-Output "Available Log Analytics Workspaces:"
    $workspaces | ForEach-Object { Write-Output "$($_.Name) - $($_.ResourceId)" }
    $workspaceId = Read-Host "Enter the Resource ID of the workspace"

    $securityContactEmail = Read-Host "Enter Security Contact Email"

    Set-AzContext -Subscription $subscription.Id
    Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security'
    Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard"
    Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/$($subscription.Id)" -WorkspaceId $workspaceId
    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision
    Set-AzSecurityContact -Name "default1" -Email $securityContactEmail -AlertAdmin -NotifyOnAlert
    Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'
    $Policy = Get-AzPolicySetDefinition | Where-Object {$_.Properties.displayName -eq 'Microsoft cloud security benchmark'}
    New-AzPolicyAssignment -Name 'Microsoft cloud security benchmark' -PolicySetDefinition $Policy -Scope "/subscriptions/$($subscription.Id)"

    Write-Output "Successfully onboarded Microsoft Defender for Cloud for subscription: $($subscription.Name)"
}

function Select-Subscription {
    $subscriptions = Get-AzSubscription
    Write-Output "Available Subscriptions:"
    $subscriptions | ForEach-Object { Write-Output "$($_.SubscriptionName) - $($_.Id)" }
    $subscriptionId = Read-Host "Enter the Subscription ID"
    return $subscriptions | Where-Object { $_.Id -eq $subscriptionId }
}

function Deploy-DefenderForCloudAcrossAll {
    $subscriptions = Get-AzSubscription

    foreach ($sub in $subscriptions) {
        Select-AzSubscription -SubscriptionId $sub.Id
        Onboard-DefenderForCloud
    }
}

function Show-Menu {
    do {
        Write-Output "1: Generate Defender for Cloud Status Report"
        Write-Output "2: Enable Defender Plans Across All Subscriptions"
        Write-Output "3: Selectively Enable Defender Plans"
        Write-Output "4: Onboard Defender for Cloud"
        Write-Output "5: Deploy Defender for Cloud Across All Subscriptions"
        Write-Output "Q: Quit"
        $option = Read-Host "Please select an option"

        switch ($option) {
            '1' { Connect-DefenderForCloud }
            '2' { Enable-DefenderPlans }
            '3' { Selective-EnableDefenderPlans }
            '4' { Onboard-DefenderForCloud }
            '5' { Deploy-DefenderForCloudAcrossAll }
            'Q' { return }
            default { Write-Output "Invalid option, please try again." }
        }
    } while ($option -ne 'Q')
}

# Execute the menu
Show-Menu
