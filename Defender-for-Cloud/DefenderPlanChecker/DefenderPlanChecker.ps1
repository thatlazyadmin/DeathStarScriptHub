# Display banner
$banner = @"
========================================
  Defender Plan Exporter
  Created by: Shaun Hardneck
========================================
"@
Write-Host $banner -ForegroundColor Cyan

# Authenticate to Azure
function Authenticate-Azure {
    try {
        Write-Host "To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code displayed to authenticate."
        $azAccount = Connect-AzAccount -DeviceCode
        if ($azAccount) {
            Write-Host "Authentication successful!" -ForegroundColor Green
        }
    } catch {
        Write-Host "Authentication failed. Error: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
}

# Function to export Defender for Cloud plans
function Export-DefenderPlans {
    param (
        [string]$SubscriptionId,
        [string]$SubscriptionName
    )

    try {
        Write-Host "Setting context to subscription: $SubscriptionName ($SubscriptionId)" -ForegroundColor Cyan
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        $defenderPlans = Get-AzSecurityPricing
    } catch {
        Write-Host "Failed to set context or retrieve Defender plans. Check subscription details." -ForegroundColor Red
        return
    }

    if ($defenderPlans) {
        Write-Host "Defender plans retrieved for $SubscriptionName" -ForegroundColor Green
        $exportData = $defenderPlans | ForEach-Object {
            $enabledStatus = if ($_.PricingTier -eq "Standard") { "Enabled" } else { "Disabled" }
            [PSCustomObject]@{
                PlanName    = $_.Name
                Description = $_.ResourceType
                Enabled     = $enabledStatus
            }
        }

        # Define the current script directory
        $currentScriptDirectory = Split-Path -Parent -Path $PSCommandPath
        $filePath = Join-Path -Path $currentScriptDirectory -ChildPath ("DefenderPlans_" + $SubscriptionName.Replace(' ', '_') + ".xlsx")

        try {
            # Export data to Excel
            $exportData | Export-Excel -Path $filePath -AutoSize -TableName "DefenderPlans" -Show
            Write-Host "Exported Defender plans to $filePath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to export to Excel. Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "No Defender plans found for $SubscriptionName" -ForegroundColor Yellow
    }
}

# Function to show menu and handle user input
function Show-Menu {
    Write-Host "`nSelect an action:" -ForegroundColor Cyan
    Write-Host "1. Export Defender Plans for a selected subscription" -ForegroundColor Cyan
    Write-Host "0. Exit" -ForegroundColor Cyan

    $choice = Read-Host "Enter your choice (0-1)"
    switch ($choice) {
        "1" {
            $subscriptions = Get-AzSubscription
            $selectedSub = $subscriptions | Out-GridView -PassThru -Title "Select a Subscription"
            if ($selectedSub) {
                Export-DefenderPlans -SubscriptionId $selectedSub.SubscriptionId -SubscriptionName $selectedSub.Name
            } else {
                Write-Host "No subscription selected. Exiting..." -ForegroundColor Red
            }
        }
        "0" {
            Write-Host "Exiting script." -ForegroundColor Yellow
            break
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Show-Menu
        }
    }
}

# Execute Authentication and Show Menu
Authenticate-Azure
Show-Menu
