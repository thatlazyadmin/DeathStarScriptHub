<#
.SYNOPSIS
    Logs off all disconnected AVD sessions across all host pools and subscriptions.

.DESCRIPTION
    Designed for use in Azure Automation with Managed Identity.
    Includes a $testMode switch to simulate actions in the Test Pane.

.AUTHOR
    Shaun Hardneck | www.thatlazyadmin.com  |Shaun@thatlazyadmin.com
#>

# === CONFIGURATION ===
# Set to $true when running in the Test Pane to avoid logging off real sessions
$testMode = $true

# Set error behavior
$ErrorActionPreference = 'Stop'

# Authenticate using the Automation Account's Managed Identity
try {
    Connect-AzAccount -Identity
    Write-Output "Connected using Managed Identity"
} catch {
    Write-Error "Failed to authenticate with Managed Identity: $_"
    exit 1
}

# Get all subscriptions the identity has access to
$subscriptions = Get-AzSubscription

foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id

    Write-Output "Processing subscription: $($sub.Name) [$($sub.Id)]"

    try {
        $hostPools = Get-AzWvdHostPool
    } catch {
        Write-Warning "No AVD Host Pools found or access denied in subscription: $($sub.Name)"
        continue
    }

    foreach ($hp in $hostPools) {
        $hostPoolName = $hp.Name
        $resourceGroupName = $hp.Id.Split("/")[4]

        Write-Output "Checking Host Pool: $hostPoolName in Resource Group: $resourceGroupName"

        try {
            $sessions = Get-AzWvdUserSession -HostPoolName $hostPoolName -ResourceGroupName $resourceGroupName
        } catch {
            Write-Warning "Failed to retrieve sessions for ${hostPoolName}: $($_)"
            continue
        }

        foreach ($session in $sessions) {
            if ($session.SessionState -eq "Disconnected") {
                $sessionHost = $session.Name.Split("/")[1]
                $sessionId = $session.Name.Split("/")[2]
                $user = $session.ActiveDirectoryUserName

                if ($testMode) {
                    Write-Output "[TEST MODE] Would log off: $user from $sessionHost in Host Pool: $hostPoolName"
                } else {
                    try {
                        Remove-AzWvdUserSession -HostPoolName $hostPoolName `
                            -ResourceGroupName $resourceGroupName `
                            -SessionHostName $sessionHost `
                            -Id $sessionId -Force

                        Write-Output "Logged off: $user from $sessionHost in Host Pool: $hostPoolName"
                    } catch {
                        Write-Warning "Failed to log off ${user} from ${sessionHost}: $($_)"
                    }
                }
            }
        }
    }
}

Write-Output "Script execution complete. TestMode = $testMode"