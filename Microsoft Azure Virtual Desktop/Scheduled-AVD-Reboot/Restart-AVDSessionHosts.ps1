<#
.SYNOPSIS
    Restart Azure Virtual Desktop session hosts on a schedule using Azure Automation

.DESCRIPTION
    This script restarts AVD session hosts based on configurable criteria:
    - Can target specific host pools or all host pools in a subscription
    - Only restarts hosts with no active user sessions (configurable)
    - Sets hosts to drain mode before restart to prevent new connections
    - Waits for host to come back online after restart
    - Logs all actions for auditing

.PARAMETER HostPoolName
    (Optional) Name of specific host pool to restart. If not specified, processes all host pools.

.PARAMETER HostPoolResourceGroup
    (Optional) Resource group of the host pool. Required if HostPoolName is specified.

.PARAMETER ForceRestart
    If specified, restarts hosts even if they have active sessions (NOT RECOMMENDED)

.PARAMETER MaxSessionsBeforeRestart
    Maximum number of active sessions allowed before skipping restart. Default: 0

.PARAMETER WaitForOnline
    Wait for VM to come back online after restart. Default: $true

.PARAMETER WaitTimeoutMinutes
    Maximum time to wait for VM to come back online. Default: 15 minutes

.PARAMETER WhatIf
    If specified, shows what would happen without making any actual changes. Safe for testing.

.NOTES
    Author: Shaun Hardneck | www.thatlazyadmin.com
    Requires: 
    - Azure Automation Account with Managed Identity
    - Managed Identity requires these permissions:
        * Desktop Virtualization Contributor (on host pools)
        * Virtual Machine Contributor (on session host VMs)
        * Reader (on subscription)
    
.EXAMPLE
    # Restart all session hosts in a specific host pool (only those with no sessions)
    .\Restart-AVDSessionHosts.ps1 -HostPoolName "prd-hp-prd-eastus-001" -HostPoolResourceGroup "rg-avd-prod"

.EXAMPLE
    # Restart all session hosts across all host pools
    .\Restart-AVDSessionHosts.ps1

.EXAMPLE
    # Restart hosts with up to 2 active sessions
    .\Restart-AVDSessionHosts.ps1 -HostPoolName "prd-hp-prd-eastus-001" -HostPoolResourceGroup "rg-avd-prod" -MaxSessionsBeforeRestart 2

.EXAMPLE
    # Test what would happen without making changes (WhatIf mode)
    .\Restart-AVDSessionHosts.ps1 -HostPoolName "prd-hp-prd-eastus-001" -HostPoolResourceGroup "rg-avd-prod" -WhatIf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $false)]
    [string]$HostPoolResourceGroup,

    [Parameter(Mandatory = $false)]
    [bool]$ForceRestart = $false,

    [Parameter(Mandatory = $false)]
    [int]$MaxSessionsBeforeRestart = 0,

    [Parameter(Mandatory = $false)]
    [bool]$WaitForOnline = $true,

    [Parameter(Mandatory = $false)]
    [int]$WaitTimeoutMinutes = 15,

    [Parameter(Mandatory = $false)]
    [bool]$WhatIf = $false
)

# Parameter validation
if ($HostPoolName -and -not $HostPoolResourceGroup) {
    throw "HostPoolResourceGroup is required when HostPoolName is specified"
}
if ($HostPoolResourceGroup -and -not $HostPoolName) {
    throw "HostPoolName is required when HostPoolResourceGroup is specified"
}

#region Module Imports (Required for Azure Automation)

Write-Output "Importing required Azure modules..."
try {
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Compute -ErrorAction Stop
    Import-Module Az.DesktopVirtualization -ErrorAction Stop
    Write-Output "All modules imported successfully"
}
catch {
    Write-Error "Failed to import required modules: $($_.Exception.Message)"
    Write-Error "Ensure Az.Accounts, Az.Compute, and Az.DesktopVirtualization modules are imported in the Automation Account"
    throw
}

#endregion

#region Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Error'   { Write-Error $logMessage }
        'Warning' { Write-Warning $logMessage }
        'Success' { Write-Output "$logMessage" }
        default   { Write-Output $logMessage }
    }
}

function Wait-ForVMOnline {
    param(
        [string]$VMName,
        [string]$ResourceGroup,
        [int]$TimeoutMinutes
    )
    
    Write-Log "Waiting for VM '$VMName' to come back online (timeout: $TimeoutMinutes minutes)..." -Level Info
    
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $online = $false
    
    while ((Get-Date) -lt $timeout -and -not $online) {
        Start-Sleep -Seconds 30
        
        try {
            $vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -Status -ErrorAction Stop
            $powerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code
            
            if ($powerState -eq "PowerState/running") {
                $online = $true
                Write-Log "VM '$VMName' is now online" -Level Success
            }
            else {
                Write-Log "VM '$VMName' current state: $powerState" -Level Info
            }
        }
        catch {
            Write-Log "Error checking VM status: $($_.Exception.Message)" -Level Warning
        }
    }
    
    if (-not $online) {
        Write-Log "VM '$VMName' did not come online within $TimeoutMinutes minutes" -Level Warning
        return $false
    }
    
    return $true
}

function Set-SessionHostDrainMode {
    param(
        [string]$HostPoolName,
        [string]$ResourceGroup,
        [string]$SessionHostName,
        [bool]$Enable
    )
    
    $status = if ($Enable) { "enabled" } else { "disabled" }
    
    if ($WhatIf) {
        Write-Log "[WHATIF] Would set drain mode $status for session host '$SessionHostName'" -Level Info
        return $true
    }
    
    try {
        Update-AzWvdSessionHost `
            -HostPoolName $HostPoolName `
            -ResourceGroupName $ResourceGroup `
            -Name $SessionHostName `
            -AllowNewSession:(-not $Enable) `
            -ErrorAction Stop
        
        Write-Log "Drain mode $status for session host '$SessionHostName'" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to set drain mode for '$SessionHostName': $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Restart-SessionHost {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [object]$SessionHost,
        [string]$HostPoolName,
        [string]$HostPoolResourceGroup
    )
    
    $sessionHostName = $SessionHost.Name.Split('/')[1]
    $vmName = $sessionHostName.Split('.')[0]
    
    Write-Log "========================================" -Level Info | Out-Null
    Write-Log "Processing session host: $sessionHostName" -Level Info | Out-Null
    
    # Get current session count
    $sessions = Get-AzWvdUserSession `
        -HostPoolName $HostPoolName `
        -ResourceGroupName $HostPoolResourceGroup `
        -SessionHostName $sessionHostName `
        -ErrorAction SilentlyContinue
    
    $sessionCount = if ($sessions) { $sessions.Count } else { 0 }
    Write-Log "Current active sessions: $sessionCount" -Level Info | Out-Null
    
    # Check if we should skip this host based on session count
    if (-not $ForceRestart -and $sessionCount -gt $MaxSessionsBeforeRestart) {
        Write-Log "Skipping restart - session count ($sessionCount) exceeds threshold ($MaxSessionsBeforeRestart)" -Level Warning | Out-Null
        return "skipped"
    }
    
    # Get VM resource group
    $vmResourceId = $SessionHost.ResourceId
    if ($vmResourceId -match '/resourceGroups/([^/]+)/') {
        $vmResourceGroup = $Matches[1]
    }
    else {
        Write-Log "Could not parse VM resource group from: $vmResourceId" -Level Error | Out-Null
        return "failed"
    }
    
    # Set drain mode
    Write-Log "Setting drain mode (prevent new sessions)..." -Level Info | Out-Null
    $drainResult = Set-SessionHostDrainMode `
        -HostPoolName $HostPoolName `
        -ResourceGroup $HostPoolResourceGroup `
        -SessionHostName $sessionHostName `
        -Enable $true
    
    if (-not $drainResult) {
        Write-Log "Failed to set drain mode - aborting restart" -Level Error | Out-Null
        return "failed"
    }
    
    # Restart the VM
    Write-Log "Restarting VM: $vmName" -Level Info | Out-Null
    
    if ($WhatIf) {
        Write-Log "[WHATIF] Would restart VM: $vmName in resource group: $vmResourceGroup" -Level Info | Out-Null
        Write-Log "[WHATIF] Would wait for VM to come back online (timeout: $WaitTimeoutMinutes minutes)" -Level Info | Out-Null
        Write-Log "[WHATIF] Would re-enable new sessions after restart" -Level Info | Out-Null
        Write-Log "[WHATIF] Session host restart simulation completed" -Level Success | Out-Null
        return "success"
    }
    
    try {
        Restart-AzVM -Name $vmName -ResourceGroupName $vmResourceGroup -NoWait -ErrorAction Stop | Out-Null
        Write-Log "Restart command sent successfully" -Level Success | Out-Null
        
        # Small delay to ensure restart command is processed
        Start-Sleep -Seconds 10
    }
    catch {
        Write-Log "Failed to restart VM: $($_.Exception.Message)" -Level Error | Out-Null
        
        # Re-enable new sessions since restart failed
        Set-SessionHostDrainMode `
            -HostPoolName $HostPoolName `
            -ResourceGroup $HostPoolResourceGroup `
            -SessionHostName $sessionHostName `
            -Enable $false | Out-Null
        
        return "failed"
    }
    
    # Wait for VM to come back online
    if ($WaitForOnline) {
        $isOnline = Wait-ForVMOnline -VMName $vmName -ResourceGroup $vmResourceGroup -TimeoutMinutes $WaitTimeoutMinutes
        
        if ($isOnline) {
            # Re-enable new sessions
            Write-Log "Re-enabling new sessions..." -Level Info | Out-Null
            Set-SessionHostDrainMode `
                -HostPoolName $HostPoolName `
                -ResourceGroup $HostPoolResourceGroup `
                -SessionHostName $sessionHostName `
                -Enable $false | Out-Null
        }
        else {
            Write-Log "VM did not come online - leaving drain mode enabled" -Level Warning | Out-Null
        }
    }
    
    Write-Log "Session host restart completed successfully" -Level Success | Out-Null
    return "success"
}

#endregion

#region Main Script

try {
    Write-Log "========================================" -Level Info
    Write-Log "AVD Session Host Restart Automation" -Level Info
    Write-Log "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info
    
    if ($WhatIf) {
        Write-Log "*** WHATIF MODE ENABLED - No actual changes will be made ***" -Level Warning
    }
    
    Write-Log "========================================" -Level Info
    
    # Connect using Managed Identity
    Write-Log "Connecting to Azure using Managed Identity..." -Level Info
    try {
        Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
        Write-Log "Successfully authenticated with Managed Identity" -Level Success
    }
    catch {
        Write-Log "Failed to authenticate with Managed Identity: $($_.Exception.Message)" -Level Error
        throw
    }
    
    # Get host pools to process
    $hostPools = @()
    
    if ($HostPoolName -and $HostPoolResourceGroup) {
        Write-Log "Processing specific host pool: $HostPoolName" -Level Info
        try {
            $hostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $HostPoolResourceGroup -ErrorAction Stop
            $hostPools += $hostPool
        }
        catch {
            Write-Log "Failed to get host pool '$HostPoolName': $($_.Exception.Message)" -Level Error
            throw
        }
    }
    else {
        Write-Log "Discovering all host pools in subscription..." -Level Info
        try {
            $hostPools = Get-AzWvdHostPool -ErrorAction Stop
            Write-Log "Found $($hostPools.Count) host pool(s)" -Level Info
        }
        catch {
            Write-Log "Failed to get host pools: $($_.Exception.Message)" -Level Error
            throw
        }
    }
    
    if ($hostPools.Count -eq 0) {
        Write-Log "No host pools found to process" -Level Warning
        exit 0
    }
    
    # Process each host pool
    [int]$totalRestarted = 0
    [int]$totalSkipped = 0
    [int]$totalFailed = 0
    
    foreach ($hostPool in $hostPools) {
        Write-Log "`n========================================" -Level Info
        Write-Log "Processing Host Pool: $($hostPool.Name)" -Level Info
        Write-Log "Resource Group: $($hostPool.Id.Split('/')[4])" -Level Info
        
        $hpResourceGroup = $hostPool.Id.Split('/')[4]
        
        # Get session hosts
        try {
            $sessionHosts = Get-AzWvdSessionHost `
                -HostPoolName $hostPool.Name `
                -ResourceGroupName $hpResourceGroup `
                -ErrorAction Stop
            
            Write-Log "Found $($sessionHosts.Count) session host(s)" -Level Info
        }
        catch {
            Write-Log "Failed to get session hosts: $($_.Exception.Message)" -Level Error
            $totalFailed += 1
            continue
        }
        
        # Restart each session host
        foreach ($sessionHost in $sessionHosts) {
            $result = Restart-SessionHost `
                -SessionHost $sessionHost `
                -HostPoolName $hostPool.Name `
                -HostPoolResourceGroup $hpResourceGroup
            
            switch ($result) {
                "success" { $totalRestarted++ }
                "skipped" { $totalSkipped++ }
                "failed"  { $totalFailed++ }
                default   { $totalFailed++ }
            }
            
            # Small delay between restarts
            Start-Sleep -Seconds 5
        }
    }
    
    # Summary
    Write-Output "`n========================================"
    Write-Output "AVD Session Host Restart Summary"
    Write-Output "Author: Shaun Hardneck | www.thatlazyadmin.com"
    Write-Output "========================================"
    
    if ($WhatIf) {
        Write-Output "*** WHATIF MODE - No actual changes were made ***`n"
    }
    
    Write-Output "✅ Successfully restarted: $totalRestarted"
    Write-Output "⏭️  Skipped (active sessions): $totalSkipped"
    Write-Output "❌ Failed: $totalFailed"
    Write-Output "========================================"
    Write-Output "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output "Script by: Shaun Hardneck | www.thatlazyadmin.com"
    
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error
    throw
}

#endregion

