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

function Show-Banner {
    $banner = @"
  ______   _______  _______  _______  __    _  ______   _______  ______      _______  _______  ______      _______  ___      _______  __   __  ______  
 |      | |       ||       ||       ||  |  | ||      | |       ||    _ |    |       ||       ||    _ |    |       ||   |    |       ||  | |  ||      | 
 |  _    ||    ___||    ___||    ___||   |_| ||  _    ||    ___||   | ||    |    ___||   _   ||   | ||    |       ||   |    |   _   ||  | |  ||  _    |
 | | |   ||   |___ |   |___ |   |___ |       || | |   ||   |___ |   |_||_   |   |___ |  | |  ||   |_||_   |       ||   |    |  | |  ||  |_|  || | |   |
 | |_|   ||    ___||    ___||    ___||  _    || |_|   ||    ___||    __  |  |    ___||  |_|  ||    __  |  |      _||   |___ |  |_|  ||       || |_|   |
 |       ||   |___ |   |    |   |___ | | |   ||       ||   |___ |   |  | |  |   |    |       ||   |  | |  |     |_ |       ||       ||       ||       |
 |______| |_______||___|    |_______||_|  |__||______| |_______||___|  |_|  |___|    |_______||___|  |_|  |_______||_______||_______||_______||______| 
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Check-Module {
    param (
        [string]$ModuleName
    )

    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Module $ModuleName is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber
    }
    else {
        Write-Host "Module $ModuleName is already installed." -ForegroundColor Green
    }
}

function Initialize-Script {
    Check-Module -ModuleName 'Az'
    Check-Module -ModuleName 'Az.Security'
    Check-Module -ModuleName 'ImportExcel'

    Import-Module Az.Security
    Import-Module ImportExcel
}

function Connect-DefenderForCloud {
    Connect-AzAccount -UseDeviceAuthentication -ErrorAction SilentlyContinue
    $subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue

    $report = @()
    foreach ($sub in $subscriptions) {
        Select-AzSubscription -SubscriptionId $sub.Id -ErrorAction SilentlyContinue
        $defenderStatus = Get-AzSecurityPricing -ErrorAction SilentlyContinue
        $report += [PSCustomObject]@{
            SubscriptionId = $sub.Id
            SubscriptionName = $sub.Name
            PlanDetails = ($defenderStatus | Format-Table | Out-String)
        }
    }

    $report | Export-Excel -Path "./DefenderForCloudStatus.xlsx" -AutoSize -TableName "DefenderStatus"
}

function Enable-DefenderPlans {
    $subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue

    foreach ($sub in $subscriptions) {
        Select-AzSubscription -SubscriptionId $sub.Id -ErrorAction SilentlyContinue
        $plans = @('Defender for Servers', 'Defender for Storage', 'Defender for SQL', 'Defender for Containers', 'Defender for App Service', 'Defender for Key Vault', 'Defender for Resource Manager', 'Defender for DNS')
        
        foreach ($plan in $plans) {
            Enable-AzSecurityPricing -PricingTier 'Standard' -Name $plan -ErrorAction SilentlyContinue
        }

        Write-Host "Enabled all Defender plans for subscription: $($sub.Name)" -ForegroundColor Green
    }
}

function Selective-EnableDefenderPlans {
    $subscription = Select-Subscription
    Select-AzSubscription -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue

    $plans = @('Defender for Servers', 'Defender for Storage', 'Defender for SQL', 'Defender for Containers', 'Defender for App Service', 'Defender for Key Vault', 'Defender for Resource Manager', 'Defender for DNS')
    Write-Host "Available Plans: " -ForegroundColor Yellow
    $plans | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    $selectedPlans = Read-Host "Enter the plans to enable (comma-separated)"

    foreach ($plan in $selectedPlans.Split(',')) {
        Enable-AzSecurityPricing -PricingTier 'Standard' -Name $plan.Trim() -ErrorAction SilentlyContinue
        Write-Host "Enabled $plan for Subscription: $($subscription.Name)" -ForegroundColor Green
    }
}

function Onboard-DefenderForCloud {
    $subscription = Select-Subscription
    Select-AzSubscription -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue

    $workspaces = Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue
    Write-Host "Available Log Analytics Workspaces:" -ForegroundColor Yellow
    $workspaces | ForEach-Object { Write-Host "$($_.Name) - $($_.ResourceId)" -ForegroundColor Yellow }
    $workspaceId = Read-Host "Enter the Resource ID of the workspace"

    $securityContactEmail = Read-Host "Enter Security Contact Email"

    Set-AzContext -Subscription $subscription.Id -ErrorAction SilentlyContinue
    Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security' -ErrorAction SilentlyContinue
    Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard" -ErrorAction SilentlyContinue
    Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/$($subscription.Id)" -WorkspaceId $workspaceId -ErrorAction SilentlyContinue
    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision -ErrorAction SilentlyContinue
    Set-AzSecurityContact -Name "default1" -Email $securityContactEmail -AlertAdmin -NotifyOnAlert -ErrorAction SilentlyContinue
    Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights' -ErrorAction SilentlyContinue
    $Policy = Get-AzPolicySetDefinition | Where-Object {$_.Properties.displayName -eq 'Microsoft cloud security benchmark'}
    New-AzPolicyAssignment -Name 'Microsoft cloud security benchmark' -PolicySetDefinition $Policy -Scope "/subscriptions/$($subscription.Id)" -ErrorAction SilentlyContinue

    Write-Host "Successfully onboarded Microsoft Defender for Cloud for subscription: $($subscription.Name)" -ForegroundColor Green
}

function Select-Subscription {
    $subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue
    Write-Host "Available Subscriptions:" -ForegroundColor Yellow
    $subscriptions | ForEach-Object { Write-Host "$($_.SubscriptionName) - $($_.Id)" -ForegroundColor Yellow }
    $subscriptionId = Read-Host "Enter the Subscription ID"
    return $subscriptions | Where-Object { $_.Id -eq $subscriptionId }
}

function Deploy-DefenderForCloudAcrossAll {
    $subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue

    foreach ($sub in $subscriptions) {
        Select-AzSubscription -SubscriptionId $sub.Id -ErrorAction SilentlyContinue
        Onboard-DefenderForCloud
    }
}

function Show-Menu {
    Clear-Host
    Show-Banner

    do {
        Write-Host "1: Generate Defender for Cloud Status Report" -ForegroundColor Cyan
        Write-Host "2: Enable Defender Plans Across All Subscriptions" -ForegroundColor Cyan
        Write-Host "3: Selectively Enable Defender Plans" -ForegroundColor Cyan
        Write-Host "4: Onboard Defender for Cloud" -ForegroundColor Cyan
        Write-Host "5: Deploy Defender for Cloud Across All Subscriptions" -ForegroundColor Cyan
        Write-Host "Q: Quit" -ForegroundColor Cyan
        $option = Read-Host "Please select an option"

        switch ($option) {
            '1' { Connect-DefenderForCloud }
            '2' { Enable-DefenderPlans }
            '3' { Selective-EnableDefenderPlans }
            '4' { Onboard-DefenderForCloud }
            '5' { Deploy-DefenderForCloudAcrossAll }
            'Q' { return }
            default { Write-Host "Invalid option, please try again." -ForegroundColor Red }
        }
    } while ($option -ne 'Q')
}

# Initialize and Execute the Menu
Initialize-Script
Show-Menu
