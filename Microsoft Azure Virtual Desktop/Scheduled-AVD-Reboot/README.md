# Azure Virtual Desktop - Scheduled Session Host Reboot Automation

**Author:** Shaun Hardneck | [www.thatlazyadmin.com](https://www.thatlazyadmin.com)  
**Version:** 1.0  
**Last Updated:** October 2025

## Overview

Automated PowerShell runbook for Azure Automation Account to safely restart Azure Virtual Desktop (AVD) session hosts on a schedule. This solution ensures minimal disruption to users by only restarting hosts without active sessions and using drain mode to prevent new connections.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [Step 1: Create Automation Account](#step-1-create-automation-account)
  - [Step 2: Assign RBAC Permissions](#step-2-assign-rbac-permissions)
  - [Step 3: Import PowerShell Modules](#step-3-import-powershell-modules)
  - [Step 4: Import Runbook](#step-4-import-runbook)
  - [Step 5: Test with WhatIf Mode](#step-5-test-with-whatif-mode)
  - [Step 6: Create Schedule](#step-6-create-schedule)
- [Parameters Reference](#parameters-reference)
- [Usage Examples](#usage-examples)
- [Monitoring & Logs](#monitoring--logs)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Recommended Schedules](#recommended-schedules)
- [Support](#support)

## Features

- **Safe Restarts** - Only restarts session hosts with no active sessions (configurable threshold)
- **Drain Mode** - Sets hosts to drain mode before restart to prevent new connections
- **VM Monitoring** - Waits for VMs to come back online after restart (configurable timeout)
- **Flexible Targeting** - Target specific host pools or all host pools in subscription
- **WhatIf Mode** - Test end-to-end without making any actual changes
- **Managed Identity** - Uses Azure Automation Managed Identity (no credential storage)
- **Comprehensive Logging** - Detailed timestamped logs for auditing and troubleshooting
- **Error Recovery** - Re-enables sessions if restart fails

## Prerequisites

### Azure Resources

- Azure subscription with Contributor access
- Azure Virtual Desktop environment deployed
- Azure Automation Account (or permissions to create one)

### PowerShell Modules

The following modules must be imported in the Automation Account:

- `Az.Accounts` (v2.12.0 or later)
- `Az.Compute` (v5.0.0 or later)
- `Az.DesktopVirtualization` (v4.0.0 or later)

### Required Permissions

The Automation Account's Managed Identity needs:

- **Desktop Virtualization Contributor** - On host pool resource groups
- **Virtual Machine Contributor** - On session host VM resource groups
- **Reader** - At subscription level (to discover host pools)

## Quick Start

### Automated Setup (Recommended)

Use the included setup script to automate the entire configuration:

```powershell
# Download or navigate to the script folder
cd ".\Scheduled-AVD-Reboot"

# Run automated setup
.\Setup-AutomationAccount.ps1 `
    -SubscriptionId "YOUR-SUBSCRIPTION-ID" `
    -ResourceGroupName "rg-automation" `
    -AutomationAccountName "aa-avd-reboot" `
    -Location "eastus" `
    -HostPoolResourceGroup "rg-avd-prod" `
    -SessionHostResourceGroup "rg-avd-sessionhosts-prod"
```

The script will:

1. Create Automation Account with System Managed Identity
2. Assign required RBAC permissions
3. Import necessary PowerShell modules
4. Import and publish the runbook
5. Create a weekly schedule (Sunday 2 AM)
6. Link schedule to runbook

### Manual Setup

Follow the [Detailed Setup](#detailed-setup) section below.

## Detailed Setup

### Step 1: Create Automation Account

#### Using Azure Portal

1. Navigate to **Azure Portal** → **Automation Accounts** → **+ Create**
2. Configure basic settings:
   - **Subscription:** Select your subscription
   - **Resource Group:** Create new or use existing (e.g., `rg-automation`)
   - **Name:** `aa-avd-reboot-automation`
   - **Region:** Same as your AVD resources (e.g., `East US`)
3. Go to **Advanced** tab:
   - **Managed Identity:** Enable **System assigned**
4. Click **Review + Create** → **Create**
5. Wait for deployment to complete

#### Using PowerShell

```powershell
# Variables
$subscriptionId = "YOUR-SUBSCRIPTION-ID"
$resourceGroupName = "rg-automation"
$automationAccountName = "aa-avd-reboot-automation"
$location = "eastus"

# Set context
Set-AzContext -SubscriptionId $subscriptionId

# Create resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create Automation Account with Managed Identity
New-AzAutomationAccount `
    -Name $automationAccountName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AssignSystemIdentity
```

### Step 2: Assign RBAC Permissions

The Managed Identity needs specific permissions to manage AVD resources.

```powershell
# Variables
$automationAccountName = "aa-avd-reboot-automation"
$automationAccountRG = "rg-automation"
$subscriptionId = "YOUR-SUBSCRIPTION-ID"
$hostPoolRG = "rg-avd-prod"
$sessionHostRG = "rg-avd-sessionhosts-prod"

# Get the Managed Identity Principal ID
$automationAccount = Get-AzAutomationAccount `
    -Name $automationAccountName `
    -ResourceGroupName $automationAccountRG
$principalId = $automationAccount.Identity.PrincipalId

Write-Output "Managed Identity Principal ID: $principalId"

# Assign Desktop Virtualization Contributor (on host pool resource group)
New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName "Desktop Virtualization Contributor" `
    -Scope "/subscriptions/$subscriptionId/resourceGroups/$hostPoolRG"

Write-Output "Assigned Desktop Virtualization Contributor on $hostPoolRG"

# Assign Virtual Machine Contributor (on session host resource group)
New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName "Virtual Machine Contributor" `
    -Scope "/subscriptions/$subscriptionId/resourceGroups/$sessionHostRG"

Write-Output "Assigned Virtual Machine Contributor on $sessionHostRG"

# Assign Reader at subscription level (to discover host pools)
New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName "Reader" `
    -Scope "/subscriptions/$subscriptionId"

Write-Output "Assigned Reader at subscription level"
```

**Note:** If session hosts are in the same resource group as host pools, you only need to assign permissions once on that resource group.

### Step 3: Import PowerShell Modules

Modules must be imported in the correct order.

#### Using Azure Portal

1. Navigate to your Automation Account
2. Go to **Modules** → **Browse Gallery**
3. Import modules in this order:
   - Search for `Az.Accounts` → Click → **Import** → Wait for completion
   - Search for `Az.Compute` → Click → **Import** → Wait for completion
   - Search for `Az.DesktopVirtualization` → Click → **Import** → Wait for completion

**Important:** Wait for each module to show "Available" status before importing the next.

#### Using PowerShell

```powershell
$automationAccountName = "aa-avd-reboot-automation"
$automationAccountRG = "rg-automation"

# Import Az.Accounts first (required dependency)
New-AzAutomationModule `
    -Name "Az.Accounts" `
    -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/Az.Accounts" `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName

Write-Output "Importing Az.Accounts... (wait 2-3 minutes)"
Start-Sleep -Seconds 180

# Import Az.Compute
New-AzAutomationModule `
    -Name "Az.Compute" `
    -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/Az.Compute" `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName

Write-Output "Importing Az.Compute... (wait 2-3 minutes)"
Start-Sleep -Seconds 180

# Import Az.DesktopVirtualization
New-AzAutomationModule `
    -Name "Az.DesktopVirtualization" `
    -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization" `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName

Write-Output "All modules queued for import"
```

### Step 4: Import Runbook

#### Using Azure Portal

1. Navigate to your Automation Account
2. Go to **Runbooks** → **+ Create a runbook**
3. Configure runbook:
   - **Name:** `Restart-AVDSessionHosts`
   - **Runbook type:** PowerShell
   - **Runtime version:** 7.2 (recommended)
   - **Description:** Safely restart AVD session hosts on schedule
4. Click **Create**
5. In the editor, paste the entire content of `Restart-AVDSessionHosts.ps1`
6. Click **Save**
7. Click **Publish** → **Yes**

#### Using PowerShell

```powershell
$automationAccountName = "aa-avd-reboot-automation"
$automationAccountRG = "rg-automation"
$runbookName = "Restart-AVDSessionHosts"
$scriptPath = ".\Restart-AVDSessionHosts.ps1"

# Import runbook
Import-AzAutomationRunbook `
    -Name $runbookName `
    -Path $scriptPath `
    -Type PowerShell `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName `
    -Description "Safely restart AVD session hosts on schedule" `
    -Force

# Publish runbook
Publish-AzAutomationRunbook `
    -Name $runbookName `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName

Write-Output "Runbook imported and published"
```

### Step 5: Test with WhatIf Mode

**IMPORTANT:** Always test with WhatIf before running in production!

1. Navigate to **Automation Account** → **Runbooks** → **Restart-AVDSessionHosts**
2. Click **Start**
3. Configure parameters:
   - **HostPoolName:** Your test host pool name (e.g., `hp-test-001`)
   - **HostPoolResourceGroup:** Host pool resource group
   - **WhatIf:** `True` 
   - Leave other parameters as default
4. Click **OK**
5. View **Output** tab to see what would happen:

Expected output:

```text
Importing required Azure modules...
All modules imported successfully
[2025-10-21 14:30:15] [Info] AVD Session Host Restart Automation
[2025-10-21 14:30:15] [Warning] *** WHATIF MODE ENABLED - No actual changes will be made ***
[2025-10-21 14:30:16] [Success] Successfully authenticated with Managed Identity
[2025-10-21 14:30:18] [Info] Processing specific host pool: hp-test-001
[2025-10-21 14:30:19] [Info] Found 4 session host(s)
[2025-10-21 14:30:25] [Warning] Skipping restart - session count (2) exceeds threshold (0)
========================================
AVD Session Host Restart Summary
Author: Shaun Hardneck | www.thatlazyadmin.com
========================================
*** WHATIF MODE - No actual changes were made ***

✅ Successfully restarted: 1
⏭️  Skipped (active sessions): 3
❌ Failed: 0
========================================
Completed at: 2025-10-21 14:30:42
Script by: Shaun Hardneck | www.thatlazyadmin.com
```

### Step 6: Create Schedule

#### Using Azure Portal

1. Navigate to your Automation Account
2. Go to **Schedules** → **+ Add a schedule**
3. Click **+ Add a schedule**
4. Configure schedule:
   - **Name:** `Weekly-Sunday-2AM-AVD-Reboot`
   - **Description:** Weekly scheduled restart of AVD session hosts
   - **Starts:** Next Sunday at 02:00 (select date/time)
   - **Time zone:** Your timezone
   - **Recurrence:** Recurring
   - **Recur every:** 1 Week
   - **Set expiration:** No (or set end date if needed)
5. Click **Create**
6. Now link to runbook:
   - Go to **Runbooks** → **Restart-AVDSessionHosts**
   - Click **Schedules** → **+ Add a schedule**
   - Click **Link a schedule to your runbook**
   - Select **Weekly-Sunday-2AM-AVD-Reboot**
   - Click **OK**
7. Configure parameters (optional):
   - Leave blank to process ALL host pools
   - Or specify `HostPoolName` and `HostPoolResourceGroup` for specific targeting
   - Set `WhatIf` to `False` for production
8. Click **OK** → **OK**

#### Using PowerShell

```powershell
$automationAccountName = "aa-avd-reboot-automation"
$automationAccountRG = "rg-automation"
$runbookName = "Restart-AVDSessionHosts"
$scheduleName = "Weekly-Sunday-2AM-AVD-Reboot"
$timeZone = "Eastern Standard Time"  # Adjust for your timezone

# Create schedule (starts next Sunday at 2 AM)
$startTime = (Get-Date).Date.AddDays(7 - (Get-Date).DayOfWeek.value__)
$startTime = $startTime.AddHours(2)

New-AzAutomationSchedule `
    -Name $scheduleName `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName `
    -StartTime $startTime `
    -WeekInterval 1 `
    -DaysOfWeek Sunday `
    -TimeZone $timeZone

# Link schedule to runbook (restart ALL host pools)
Register-AzAutomationScheduledRunbook `
    -Name $runbookName `
    -ResourceGroupName $automationAccountRG `
    -AutomationAccountName $automationAccountName `
    -ScheduleName $scheduleName

Write-Output "Schedule created and linked to runbook"
```

## Parameters Reference

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `HostPoolName` | String | None | No | Name of specific host pool to target. If omitted, processes all host pools. |
| `HostPoolResourceGroup` | String | None | Conditional* | Resource group of the host pool. Required if `HostPoolName` is specified. |
| `ForceRestart` | Bool | `False` | No | **NOT RECOMMENDED** - Restarts hosts even with active sessions. |
| `MaxSessionsBeforeRestart` | Int | `0` | No | Maximum number of active sessions allowed before skipping restart. |
| `WaitForOnline` | Bool | `True` | No | Wait for VM to come back online after restart. |
| `WaitTimeoutMinutes` | Int | `15` | No | Maximum minutes to wait for VM to come online. |
| `WhatIf` | Bool | `False` | No | Test mode - shows what would happen without making changes. |

*Conditional: `HostPoolResourceGroup` is required when `HostPoolName` is provided.

## Usage Examples

### Example 1: Restart All Host Pools (Production)

**Scenario:** Restart all session hosts across all host pools that have zero active sessions.

**Parameters:**

- Leave all parameters blank/default
- `WhatIf`: `False`

**Behavior:**

- Discovers all host pools in subscription
- Processes each session host
- Only restarts hosts with 0 active sessions
- Sets drain mode before restart
- Waits for VMs to come back online
- Re-enables new sessions after restart

### Example 2: Test Specific Host Pool (WhatIf)

**Scenario:** Test what would happen for a specific host pool without making changes.

**Parameters:**

- `HostPoolName`: `hp-prod-eastus-001`
- `HostPoolResourceGroup`: `rg-avd-prod`
- `WhatIf`: `True`

**Behavior:**

- Simulates restart for specified host pool
- Shows which hosts would be restarted
- Shows which hosts would be skipped (and why)
- NO actual changes made

### Example 3: Allow Restart with Up to 2 Sessions

**Scenario:** Restart hosts that have 2 or fewer active sessions.

**Parameters:**

- `HostPoolName`: `hp-dev-westus-001`
- `HostPoolResourceGroup`: `rg-avd-dev`
- `MaxSessionsBeforeRestart`: `2`
- `WhatIf`: `False`

**Behavior:**

- Restarts hosts with 0, 1, or 2 active sessions
- Skips hosts with 3 or more active sessions
- Users with active sessions may be disconnected

### Example 4: Quick Restart Without Waiting

**Scenario:** Restart hosts but don't wait for them to come back online (faster execution).

**Parameters:**

- `HostPoolName`: `hp-test-001`
- `HostPoolResourceGroup`: `rg-avd-test`
- `WaitForOnline`: `False`
- `WhatIf`: `False`

**Behavior:**

- Sends restart command to VMs
- Does NOT wait for VMs to come back online
- Runbook completes faster
- Drain mode remains enabled until manual intervention

### Example 5: Force Restart (NOT RECOMMENDED)

**Scenario:** Restart hosts regardless of active sessions (emergency maintenance).

**Parameters:**

- `HostPoolName`: `hp-prod-eastus-001`
- `HostPoolResourceGroup`: `rg-avd-prod`
- `ForceRestart`: `True` ⚠️

**Behavior:**

- Restarts ALL hosts regardless of active sessions
- **WILL DISCONNECT ACTIVE USERS**
- Use only for emergency maintenance
- Notify users before running

## Monitoring & Logs

### View Runbook Job History

1. Navigate to **Automation Account** → **Runbooks** → **Restart-AVDSessionHosts**
2. Click **Jobs** (left menu)
3. Select a job from the list
4. View details:
   - **Overview:** Job status, duration, parameters used
   - **Output:** Full execution log
   - **Errors:** Any errors encountered
   - **All Logs:** Combined view

### Sample Successful Output

```text
Importing required Azure modules...
All modules imported successfully
[2025-10-21 02:00:15] [Info] ========================================
[2025-10-21 02:00:15] [Info] AVD Session Host Restart Automation
[2025-10-21 02:00:15] [Info] Started at: 2025-10-21 02:00:15
[2025-10-21 02:00:15] [Info] ========================================
[2025-10-21 02:00:16] [Info] Connecting to Azure using Managed Identity...
[2025-10-21 02:00:20] [Success] Successfully authenticated with Managed Identity
[2025-10-21 02:00:21] [Info] Processing specific host pool: hp-prod-eastus-001
[2025-10-21 02:00:22] [Info] 
========================================
[2025-10-21 02:00:22] [Info] Processing Host Pool: hp-prod-eastus-001
[2025-10-21 02:00:22] [Info] Resource Group: rg-avd-prod
[2025-10-21 02:00:23] [Info] Found 5 session host(s)
[2025-10-21 02:00:28] [Warning] Skipping restart - session count (3) exceeds threshold (0)
[2025-10-21 02:00:34] [Warning] Skipping restart - session count (1) exceeds threshold (0)

========================================
AVD Session Host Restart Summary
Author: Shaun Hardneck | www.thatlazyadmin.com
========================================
✅ Successfully restarted: 3
⏭️  Skipped (active sessions): 2
❌ Failed: 0
========================================
Completed at: 2025-10-21 02:15:42
Script by: Shaun Hardneck | www.thatlazyadmin.com
```

### Setting Up Alerts

Configure email alerts for job failures:

1. Navigate to **Automation Account** → **Alerts** → **+ Create** → **Alert rule**
2. **Condition:**
   - Signal: "Job Failed"
   - Resource: Select your runbook
3. **Actions:**
   - Create Action Group with email notifications
4. **Alert rule details:**
   - Name: `AVD-Reboot-Job-Failed`
   - Severity: Warning or Error
5. Click **Create alert rule**

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Failed to authenticate with Managed Identity"

**Error Message:**

```text
[Error] Failed to authenticate with Managed Identity: Run Connect-AzAccount to login
```

**Solution:**

1. Verify System Assigned Managed Identity is **enabled**:
   - Automation Account → **Identity** → **System assigned** → Status should be **On**
2. If disabled, enable it and wait 2-3 minutes for propagation
3. Re-run the job

#### Issue: "Failed to get host pool"

**Error Message:**

```text
[Error] Failed to get host pool 'hp-prod-001': The client 'xxx' with object id 'xxx' does not have authorization
```

**Solution:**

1. Verify Managed Identity has **Desktop Virtualization Contributor** role:

   ```powershell
   $automationAccount = Get-AzAutomationAccount -Name "aa-avd-reboot" -ResourceGroupName "rg-automation"
   $principalId = $automationAccount.Identity.PrincipalId
   
   Get-AzRoleAssignment -ObjectId $principalId
   ```

2. If missing, assign the role:

   ```powershell
   New-AzRoleAssignment `
       -ObjectId $principalId `
       -RoleDefinitionName "Desktop Virtualization Contributor" `
       -Scope "/subscriptions/YOUR-SUB-ID/resourceGroups/rg-avd-prod"
   ```

#### Issue: "Failed to restart VM"

**Error Message:**

```text
[Error] Failed to restart VM: The client 'xxx' with object id 'xxx' does not have authorization to perform action 'Microsoft.Compute/virtualMachines/restart/action'
```

**Solution:**

1. Verify Managed Identity has **Virtual Machine Contributor** role on session host resource group
2. Assign if missing:

   ```powershell
   $automationAccount = Get-AzAutomationAccount -Name "aa-avd-reboot" -ResourceGroupName "rg-automation"
   $principalId = $automationAccount.Identity.PrincipalId
   
   New-AzRoleAssignment `
       -ObjectId $principalId `
       -RoleDefinitionName "Virtual Machine Contributor" `
       -Scope "/subscriptions/YOUR-SUB-ID/resourceGroups/rg-avd-sessionhosts-prod"
   ```

#### Issue: Modules not found

**Error Message:**

```text
[Error] Failed to import required modules: The term 'Get-AzWvdHostPool' is not recognized
```

**Solution:**

1. Go to **Automation Account** → **Modules** → **Browse Gallery**
2. Import required modules in order:
   - `Az.Accounts` (wait for completion)
   - `Az.Compute` (wait for completion)
   - `Az.DesktopVirtualization` (wait for completion)
3. Each module should show **Available** status
4. Re-run the job after all modules are available

#### Issue: VM does not come back online

**Error Message:**

```text
[Warning] VM 'avd-vm-001' did not come online within 15 minutes
[Warning] VM did not come online - leaving drain mode enabled
```

**Solution:**

1. Check VM status in Azure Portal
2. If VM is stuck, manually investigate:
   - Check Boot Diagnostics
   - Check Activity Log for errors
   - Try manual start if needed
3. Manually re-enable sessions:

   ```powershell
   Update-AzWvdSessionHost `
       -HostPoolName "hp-prod-001" `
       -ResourceGroupName "rg-avd-prod" `
       -Name "avd-vm-001.domain.com" `
       -AllowNewSession $true
   ```

4. Consider increasing `WaitTimeoutMinutes` parameter if VMs consistently take longer

#### Issue: Schedule not triggering

**Symptoms:**

- Schedule exists but runbook never runs
- No jobs appear in job history

**Solution:**

1. Verify schedule is **linked** to runbook:
   - Runbooks → Restart-AVDSessionHosts → **Schedules**
   - Should show your schedule listed
2. Check schedule configuration:
   - Verify **Enabled** = Yes
   - Check **Next run** time
   - Verify timezone is correct
3. If missing link, manually link:
   - Schedules → Add a schedule → Link a schedule to your runbook
4. Wait for next scheduled time and monitor

## Security Considerations

### Managed Identity Benefits

- **No Credential Storage** - No passwords or secrets stored in Automation Account
- **Automatic Rotation** - Azure manages identity lifecycle
- **Least Privilege** - Assign only necessary permissions
- **Audit Trail** - All actions logged with Managed Identity principal ID

### RBAC Best Practices

1. **Limit Scope** - Assign permissions only to specific resource groups, not subscription-wide
2. **Use Custom Roles** - Create custom role with only required permissions:
   - `Microsoft.DesktopVirtualization/hostpools/read`
   - `Microsoft.DesktopVirtualization/hostpools/sessionhosts/read`
   - `Microsoft.DesktopVirtualization/hostpools/sessionhosts/write`
   - `Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read`
   - `Microsoft.Compute/virtualMachines/restart/action`
   - `Microsoft.Compute/virtualMachines/read`
3. **Regular Audits** - Review role assignments quarterly

### Recommendations

1. **Always Test with WhatIf** - Test new configurations in WhatIf mode first
2. **Monitor First Runs** - Watch job output for first few scheduled runs
3. **Avoid ForceRestart** - Only use in emergency maintenance with user notification
4. **Set Up Alerts** - Configure email alerts for job failures
5. **Document Changes** - Keep changelog of parameter modifications
6. **User Communication** - Notify users of scheduled maintenance windows

## Recommended Schedules

### Production Environment

**Schedule:** Weekly Sunday 2:00 AM

- **Recurrence:** Every 1 week
- **Day:** Sunday
- **Time:** 02:00 (2 AM)
- **Reason:** Low usage period, allows time for weekend updates

**Parameters:**

- `MaxSessionsBeforeRestart`: `0` (only restart if no sessions)
- `WaitForOnline`: `True`
- `WaitTimeoutMinutes`: `15`

### Development/Test Environment

**Schedule:** Daily 2:00 AM

- **Recurrence:** Every 1 day
- **Time:** 02:00 (2 AM)
- **Reason:** Faster update cycles, minimal user impact

**Parameters:**

- `MaxSessionsBeforeRestart`: `1` (more aggressive)
- `WaitForOnline`: `True`
- `WaitTimeoutMinutes`: `10`

### 24/7 Environment with Maintenance Window

**Schedule:** Bi-weekly Saturday 3:00 AM

- **Recurrence:** Every 2 weeks
- **Day:** Saturday
- **Time:** 03:00 (3 AM)
- **Reason:** Extended maintenance window, less frequent disruption

**Parameters:**

- `MaxSessionsBeforeRestart`: `0`
- `WaitForOnline`: `True`
- `WaitTimeoutMinutes`: `20`

### Seasonal Host Pool (Variable Usage)

**Schedule:** Monthly, First Sunday 1:00 AM

- **Recurrence:** Every 1 month
- **Week:** First
- **Day:** Sunday
- **Time:** 01:00 (1 AM)
- **Reason:** Less frequent restarts for lightly used pools

**Parameters:**

- `MaxSessionsBeforeRestart`: `0`
- `WaitForOnline`: `True`
- `WaitTimeoutMinutes`: `15`

## Files in This Repository

| File | Description |
|------|-------------|
| `Restart-AVDSessionHosts.ps1` | Main runbook script for restarting AVD session hosts |
| `Setup-AutomationAccount.ps1` | Automated setup script for complete environment configuration |
| `README.md` | This documentation file |

## Support

**Created by:** Shaun Hardneck  
**Website:** [www.thatlazyadmin.com](https://www.thatlazyadmin.com)  
**LinkedIn:** [Connect on LinkedIn](https://www.linkedin.com/in/shaunhardneck)

### Getting Help

1. **Check Documentation** - Review this README thoroughly
2. **Review Logs** - Check Automation Account job output and errors
3. **Verify Permissions** - Ensure Managed Identity has required RBAC roles
4. **Test with WhatIf** - Use WhatIf mode to diagnose issues
5. **Community Support** - Visit [www.thatlazyadmin.com](https://www.thatlazyadmin.com) for more Azure automation scripts

### Contributing

Feel free to:

- Report issues or bugs
- Suggest enhancements
- Share your configurations and improvements
- Provide feedback on documentation

## Changelog

### Version 1.0 (October 2025)

- Initial release
- Support for WhatIf mode
- Managed Identity authentication
- Drain mode implementation
- VM online monitoring
- Flexible host pool targeting
- Comprehensive logging
- Error recovery mechanisms

## License

This script is provided as-is for use within your organization. Feel free to modify and adapt to your specific requirements.

---

**© 2025 Shaun Hardneck | [www.thatlazyadmin.com](https://www.thatlazyadmin.com)**  
*Automating Azure, one script at a time.*


**Parameters:**
- `HostPoolName`: `prd-hp-prd-eastus-001`
- `HostPoolResourceGroup`: `rg-avd-prod`
- `MaxSessionsBeforeRestart`: `2`

### Example 4: Force Restart (NOT RECOMMENDED)

**Parameters:**
- `HostPoolName`: `prd-hp-prd-eastus-001`
- `HostPoolResourceGroup`: `rg-avd-prod`
- `ForceRestart`: `$true`

**WARNING:** This will restart hosts even with active user sessions!

## Monitoring & Troubleshooting

### View Runbook Execution Logs

1. Go to Automation Account → **Runbooks** → **Restart-AVDSessionHosts**
2. **Jobs** → Select a job
3. View **Output** and **Errors** streams

### Sample Output

```
[2025-10-21 02:00:15] [Info] ========================================
[2025-10-21 02:00:15] [Info] AVD Session Host Restart Automation
[2025-10-21 02:00:15] [Info] Started at: 2025-10-21 02:00:15
[2025-10-21 02:00:15] [Info] ========================================
[2025-10-21 02:00:16] [Success] Successfully authenticated with Managed Identity
[2025-10-21 02:00:18] [Info] Processing specific host pool: prd-hp-prd-eastus-001
[2025-10-21 02:00:19] [Info] Found 5 session host(s)
[2025-10-21 02:00:20] [Info] Processing session host: avd-vm-001.domain.com
[2025-10-21 02:00:21] [Info] Current active sessions: 0
[2025-10-21 02:00:22] [Success] Drain mode enabled for session host 'avd-vm-001.domain.com'
[2025-10-21 02:00:23] [Info] Restarting VM: avd-vm-001
[2025-10-21 02:00:25] [Success] Restart command sent successfully
[2025-10-21 02:00:26] [Info] Waiting for VM 'avd-vm-001' to come back online...
[2025-10-21 02:03:15] [Success] VM 'avd-vm-001' is now online
[2025-10-21 02:03:16] [Success] Drain mode disabled for session host 'avd-vm-001.domain.com'
[2025-10-21 02:03:17] [Success] Session host restart completed successfully
```

### Common Issues

**Issue:** "Failed to authenticate with Managed Identity"
- **Solution:** Ensure System Assigned Managed Identity is enabled on Automation Account

**Issue:** "Failed to get host pool"
- **Solution:** Verify Managed Identity has "Desktop Virtualization Contributor" role on host pool resource group

**Issue:** "Failed to restart VM"
- **Solution:** Verify Managed Identity has "Virtual Machine Contributor" role on session host resource group

**Issue:** Modules not found
- **Solution:** Import required modules: `Az.Accounts`, `Az.Compute`, `Az.DesktopVirtualization`

## Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `HostPoolName` | String | None | Target specific host pool |
| `HostPoolResourceGroup` | String | None | Resource group of host pool |
| `ForceRestart` | Switch | False | Restart even with active sessions (⚠️ NOT RECOMMENDED) |
| `MaxSessionsBeforeRestart` | Int | 0 | Maximum sessions allowed before skipping restart |
| `WaitForOnline` | Bool | True | Wait for VM to come back online |
| `WaitTimeoutMinutes` | Int | 15 | Timeout for waiting for VM online |

## Recommended Schedule

### Option 1: Weekly Maintenance Window
- **When:** Sunday 2:00 AM
- **Frequency:** Weekly
- **Best for:** Production environments with defined maintenance windows

### Option 2: Nightly Restarts (Non-Production)
- **When:** Daily 2:00 AM
- **Frequency:** Daily
- **Best for:** Dev/Test environments

### Option 3: Bi-Weekly (Lower Frequency)
- **When:** Every other Sunday 2:00 AM
- **Frequency:** Every 2 weeks
- **Best for:** Stable environments with minimal uptime requirements

## Security Considerations

1. **Managed Identity**: No credential storage or management required
2. **Least Privilege**: Only assign necessary permissions
3. **Audit Logs**: All actions logged in Automation Account job history
4. **Drain Mode**: Prevents new connections before restart
5. **Force Restart**: Use with extreme caution - disconnects active users

## Support

**Created by:** Shaun Hardneck | www.thatlazyadmin.com

For issues or questions:
1. Check Automation Account job logs
2. Verify Managed Identity permissions
3. Ensure required modules are imported
4. Review session host health in AVD

## License

Feel free to use and modify for your organization's needs.

