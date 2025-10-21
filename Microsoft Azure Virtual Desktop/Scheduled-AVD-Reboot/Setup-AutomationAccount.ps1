<#
.SYNOPSIS
    Setup Azure Automation Account for AVD session host scheduled reboots

.DESCRIPTION
    This script automates the complete setup of Azure Automation Account including:
    - Creates Automation Account with Managed Identity
    - Assigns required RBAC permissions
    - Imports necessary PowerShell modules
    - Imports the restart runbook
    - Creates a weekly schedule
    - Links schedule to runbook

.PARAMETER SubscriptionId
    Azure subscription ID

.PARAMETER ResourceGroupName
    Resource group for Automation Account (will be created if doesn't exist)

.PARAMETER AutomationAccountName
    Name for the Automation Account

.PARAMETER Location
    Azure region for Automation Account

.PARAMETER HostPoolResourceGroup
    Resource group containing AVD host pools

.PARAMETER SessionHostResourceGroup
    Resource group containing AVD session host VMs

.PARAMETER ScheduleDayOfWeek
    Day of week for scheduled restart (default: Sunday)

.PARAMETER ScheduleTime
    Time for scheduled restart in 24h format (default: 02:00)

.NOTES
    Author: Shaun Hardneck | www.thatlazyadmin.com
    Requires: Az.Automation, Az.Resources, Az.Accounts modules

.EXAMPLE
    .\Setup-AutomationAccount.ps1 `
        -SubscriptionId "12345678-1234-1234-1234-123456789012" `
        -ResourceGroupName "rg-automation" `
        -AutomationAccountName "aa-avd-reboot" `
        -Location "eastus" `
        -HostPoolResourceGroup "rg-avd-prod" `
        -SessionHostResourceGroup "rg-avd-sessionhosts-prod"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$HostPoolResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$SessionHostResourceGroup,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
    [string]$ScheduleDayOfWeek = 'Sunday',

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$ScheduleTime = '02:00'
)

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        'Error'   { Write-Host "[$timestamp] ❌ $Message" -ForegroundColor Red }
        'Warning' { Write-Host "[$timestamp] ⚠️  $Message" -ForegroundColor Yellow }
        'Success' { Write-Host "[$timestamp] ✅ $Message" -ForegroundColor Green }
        default   { Write-Host "[$timestamp] ℹ️  $Message" -ForegroundColor Cyan }
    }
}

try {
    Write-Log "Starting Azure Automation Account setup for AVD scheduled reboots" -Level Info
    Write-Log "========================================" -Level Info

    # Connect to Azure
    Write-Log "Connecting to Azure..." -Level Info
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount -SubscriptionId $SubscriptionId | Out-Null
    }
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Log "Connected to subscription: $SubscriptionId" -Level Success

    # Create Resource Group if it doesn't exist
    Write-Log "Checking resource group: $ResourceGroupName" -Level Info
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Log "Creating resource group: $ResourceGroupName" -Level Info
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
        Write-Log "Resource group created" -Level Success
    }
    else {
        Write-Log "Resource group already exists" -Level Info
    }

    # Create Automation Account
    Write-Log "Checking Automation Account: $AutomationAccountName" -Level Info
    $aa = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction SilentlyContinue
    
    if (-not $aa) {
        Write-Log "Creating Automation Account with Managed Identity..." -Level Info
        $aa = New-AzAutomationAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $AutomationAccountName `
            -Location $Location `
            -AssignSystemIdentity `
            -ErrorAction Stop
        
        Write-Log "Automation Account created" -Level Success
        
        # Wait for Managed Identity to be fully provisioned
        Write-Log "Waiting 60 seconds for Managed Identity to provision..." -Level Info
        Start-Sleep -Seconds 60
    }
    else {
        Write-Log "Automation Account already exists" -Level Info
        
        # Ensure System Identity is enabled
        if (-not $aa.Identity.PrincipalId) {
            Write-Log "Enabling System Assigned Managed Identity..." -Level Info
            Set-AzAutomationAccount `
                -ResourceGroupName $ResourceGroupName `
                -Name $AutomationAccountName `
                -AssignSystemIdentity | Out-Null
            Write-Log "Managed Identity enabled" -Level Success
            Start-Sleep -Seconds 30
        }
    }

    # Get the Managed Identity Principal ID
    $aa = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName
    $principalId = $aa.Identity.PrincipalId
    Write-Log "Managed Identity Principal ID: $principalId" -Level Info

    # Assign RBAC permissions
    Write-Log "Assigning RBAC permissions..." -Level Info

    # Reader at subscription level
    Write-Log "Assigning Reader role at subscription level..." -Level Info
    try {
        New-AzRoleAssignment `
            -ObjectId $principalId `
            -RoleDefinitionName "Reader" `
            -Scope "/subscriptions/$SubscriptionId" `
            -ErrorAction Stop | Out-Null
        Write-Log "Reader role assigned" -Level Success
    }
    catch {
        if ($_.Exception.Message -like "*already exists*") {
            Write-Log "Reader role already assigned" -Level Info
        }
        else {
            Write-Log "Failed to assign Reader role: $($_.Exception.Message)" -Level Warning
        }
    }

    # Desktop Virtualization Contributor on host pool RG
    Write-Log "Assigning Desktop Virtualization Contributor on $HostPoolResourceGroup..." -Level Info
    try {
        New-AzRoleAssignment `
            -ObjectId $principalId `
            -RoleDefinitionName "Desktop Virtualization Contributor" `
            -Scope "/subscriptions/$SubscriptionId/resourceGroups/$HostPoolResourceGroup" `
            -ErrorAction Stop | Out-Null
        Write-Log "Desktop Virtualization Contributor role assigned" -Level Success
    }
    catch {
        if ($_.Exception.Message -like "*already exists*") {
            Write-Log "Desktop Virtualization Contributor already assigned" -Level Info
        }
        else {
            Write-Log "Failed to assign Desktop Virtualization Contributor: $($_.Exception.Message)" -Level Warning
        }
    }

    # Virtual Machine Contributor on session host RG
    Write-Log "Assigning Virtual Machine Contributor on $SessionHostResourceGroup..." -Level Info
    try {
        New-AzRoleAssignment `
            -ObjectId $principalId `
            -RoleDefinitionName "Virtual Machine Contributor" `
            -Scope "/subscriptions/$SubscriptionId/resourceGroups/$SessionHostResourceGroup" `
            -ErrorAction Stop | Out-Null
        Write-Log "Virtual Machine Contributor role assigned" -Level Success
    }
    catch {
        if ($_.Exception.Message -like "*already exists*") {
            Write-Log "Virtual Machine Contributor already assigned" -Level Info
        }
        else {
            Write-Log "Failed to assign Virtual Machine Contributor: $($_.Exception.Message)" -Level Warning
        }
    }

    # Import PowerShell modules
    Write-Log "Importing required PowerShell modules..." -Level Info
    
    $modules = @('Az.Accounts', 'Az.Compute', 'Az.DesktopVirtualization')
    
    foreach ($moduleName in $modules) {
        Write-Log "Checking module: $moduleName" -Level Info
        
        $existingModule = Get-AzAutomationModule `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name $moduleName `
            -ErrorAction SilentlyContinue
        
        if ($existingModule -and $existingModule.ProvisioningState -eq 'Succeeded') {
            Write-Log "Module $moduleName already imported" -Level Info
        }
        else {
            Write-Log "Importing module: $moduleName (this may take several minutes)..." -Level Info
            
            $moduleUri = "https://www.powershellgallery.com/api/v2/package/$moduleName"
            
            New-AzAutomationModule `
                -ResourceGroupName $ResourceGroupName `
                -AutomationAccountName $AutomationAccountName `
                -Name $moduleName `
                -ContentLinkUri $moduleUri `
                -ErrorAction Stop | Out-Null
            
            # Wait for module import to complete
            $timeout = 600 # 10 minutes
            $elapsed = 0
            $interval = 30
            
            while ($elapsed -lt $timeout) {
                Start-Sleep -Seconds $interval
                $elapsed += $interval
                
                $module = Get-AzAutomationModule `
                    -ResourceGroupName $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName `
                    -Name $moduleName `
                    -ErrorAction SilentlyContinue
                
                if ($module.ProvisioningState -eq 'Succeeded') {
                    Write-Log "Module $moduleName imported successfully" -Level Success
                    break
                }
                elseif ($module.ProvisioningState -eq 'Failed') {
                    Write-Log "Module $moduleName import failed" -Level Error
                    break
                }
                else {
                    Write-Log "Module $moduleName import in progress... ($($module.ProvisioningState))" -Level Info
                }
            }
        }
    }

    # Import Runbook
    Write-Log "Importing runbook: Restart-AVDSessionHosts" -Level Info
    $runbookPath = Join-Path $PSScriptRoot "Restart-AVDSessionHosts.ps1"
    
    if (-not (Test-Path $runbookPath)) {
        Write-Log "Runbook script not found at: $runbookPath" -Level Error
        throw "Runbook script not found"
    }

    $existingRunbook = Get-AzAutomationRunbook `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Name "Restart-AVDSessionHosts" `
        -ErrorAction SilentlyContinue

    if ($existingRunbook) {
        Write-Log "Runbook already exists, updating..." -Level Info
    }

    Import-AzAutomationRunbook `
        -Name "Restart-AVDSessionHosts" `
        -Path $runbookPath `
        -Type PowerShell `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Force `
        -ErrorAction Stop | Out-Null

    Publish-AzAutomationRunbook `
        -Name "Restart-AVDSessionHosts" `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -ErrorAction Stop | Out-Null

    Write-Log "Runbook imported and published" -Level Success

    # Create Schedule
    Write-Log "Creating schedule: Weekly-$ScheduleDayOfWeek-${ScheduleTime}-Reboot" -Level Info
    
    $scheduleName = "Weekly-$ScheduleDayOfWeek-${ScheduleTime}-Reboot"
    
    # Calculate next occurrence
    $today = Get-Date
    $targetDayOfWeek = [System.DayOfWeek]::$ScheduleDayOfWeek
    $daysUntilTarget = (([int]$targetDayOfWeek - [int]$today.DayOfWeek + 7) % 7)
    if ($daysUntilTarget -eq 0) { $daysUntilTarget = 7 }
    
    $nextRun = $today.Date.AddDays($daysUntilTarget).Add([TimeSpan]::Parse($ScheduleTime))
    
    $existingSchedule = Get-AzAutomationSchedule `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Name $scheduleName `
        -ErrorAction SilentlyContinue

    if ($existingSchedule) {
        Write-Log "Schedule already exists" -Level Info
    }
    else {
        New-AzAutomationSchedule `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name $scheduleName `
            -StartTime $nextRun `
            -DayInterval 7 `
            -TimeZone (Get-TimeZone).Id `
            -ErrorAction Stop | Out-Null
        
        Write-Log "Schedule created: Next run on $($nextRun.ToString('yyyy-MM-dd HH:mm:ss'))" -Level Success
    }

    # Link Schedule to Runbook
    Write-Log "Linking schedule to runbook..." -Level Info
    
    $existingLink = Get-AzAutomationScheduledRunbook `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -RunbookName "Restart-AVDSessionHosts" `
        -ScheduleName $scheduleName `
        -ErrorAction SilentlyContinue

    if ($existingLink) {
        Write-Log "Schedule already linked to runbook" -Level Info
    }
    else {
        Register-AzAutomationScheduledRunbook `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -RunbookName "Restart-AVDSessionHosts" `
            -ScheduleName $scheduleName `
            -ErrorAction Stop | Out-Null
        
        Write-Log "Schedule linked to runbook" -Level Success
    }

    # Summary
    Write-Log "========================================" -Level Info
    Write-Log "Setup completed successfully!" -Level Success
    Write-Log "========================================" -Level Info
    Write-Log "Automation Account: $AutomationAccountName" -Level Info
    Write-Log "Resource Group: $ResourceGroupName" -Level Info
    Write-Log "Location: $Location" -Level Info
    Write-Log "Managed Identity ID: $principalId" -Level Info
    Write-Log "Schedule: $scheduleName" -Level Info
    Write-Log "Next Run: $($nextRun.ToString('yyyy-MM-dd HH:mm:ss'))" -Level Info
    Write-Log "========================================" -Level Info
    Write-Log "Next steps:" -Level Info
    Write-Log "1. Verify modules imported successfully in Azure Portal" -Level Info
    Write-Log "2. Test runbook manually before scheduled run" -Level Info
    Write-Log "3. Monitor job history after first scheduled run" -Level Info

}
catch {
    Write-Log "Setup failed: $($_.Exception.Message)" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error
    throw
}
