<#
.SYNOPSIS
    This script exports all Role Assignments for your Azure Subscriptions and provides details on the users, groups, and service principals assigned to roles.

.DESCRIPTION
    This script loops through all subscriptions (or a single selected subscription) in the tenant and exports Role Assignments, including user details like DisplayName, SignInName, and ObjectType (User, Group, Service Principal). 
    It also provides whether the assigned role is a custom role or a built-in role and the scope of the role assignment.

.NOTES
    Author:         Shaun Hardneck
    Version:        1.3
    Date:           2024-09-10
    Blog:           www.thatlazyadmin.com

.PARAMETER OutPutPath
    Export Role Assignments to a CSV file to the selected path. If not provided, the script will export to the same directory where the script is executed.

.PARAMETER SelectCurrentSubscription
    Will only Export Role Assignments from the current subscription you have selected.

.EXAMPLE
    Export Role assignments for all subscriptions:
    .\Export-RoleAssignments.ps1 

    Export Role assignments for all subscriptions and export to CSV file in "C:\temp" folder:
    .\Export-RoleAssignments.ps1 -OutPutPath C:\temp

    Only Export Role assignments for the current subscription:
    .\Export-RoleAssignments.ps1 -SelectCurrentSubscription

    Only Export Role assignments for the current subscription and export to CSV file in "C:\temp" folder:
    .\Export-RoleAssignments.ps1 -SelectCurrentSubscription -OutPutPath C:\temp
#>

#Parameters
Param (
    [Parameter(Mandatory=$false)]    
    [string]$OutputPath = '',
    [Parameter(Mandatory=$false)]    
    [Switch]$SelectCurrentSubscription
)

# Error log file setup in the script execution directory
$scriptPath = $PSScriptRoot
$errorLogFile = Join-Path $scriptPath "RoleAssignmentErrors_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Get Current Context
$CurrentContext = Get-AzContext

# Get Azure Subscriptions
if ($SelectCurrentSubscription) {
    Write-Verbose "Only running for selected subscription $($CurrentContext.Subscription.Name)" -Verbose
    $Subscriptions = Get-AzSubscription -SubscriptionId $CurrentContext.Subscription.Id -TenantId $CurrentContext.Tenant.Id
} else {
    Write-Verbose "Running for all subscriptions in Tenant" -Verbose
    $Subscriptions = Get-AzSubscription -TenantId $CurrentContext.Tenant.Id
}

# Initialize report array
$report = @()

# Loop through all subscriptions
foreach ($Subscription in $Subscriptions) {
    # Set context to each subscription
    Write-Verbose "Changing to Subscription $($Subscription.Name)" -Verbose
    Set-AzContext -TenantId $Subscription.TenantId -SubscriptionId $Subscription.SubscriptionId -Force

    # Get Role Assignments for the current subscription
    Write-Verbose "Getting role assignments for subscription $($Subscription.Name)..." -Verbose
    $roles = Get-AzRoleAssignment | Select-Object RoleDefinitionName, DisplayName, SignInName, ObjectId, ObjectType, Scope,
    @{name="TenantId";expression = {$Subscription.TenantId}}, 
    @{name="SubscriptionName";expression = {$Subscription.Name}}, 
    @{name="SubscriptionId";expression = {$Subscription.SubscriptionId}}

    foreach ($role in $roles) {
        try {
            # Check if RoleDefinitionName is empty
            if ([string]::IsNullOrEmpty($role.RoleDefinitionName)) {
                Write-Verbose "Skipping role assignment with empty RoleDefinitionName" -Verbose
                Add-Content -Path $errorLogFile -Value "Skipping role assignment with empty RoleDefinitionName in subscription $($Subscription.Name)"
                continue
            }

            # Extract role details
            $DisplayName = $role.DisplayName
            $SignInName = $role.SignInName
            $ObjectType = $role.ObjectType
            $RoleDefinitionName = $role.RoleDefinitionName
            $AssignmentScope = $role.Scope
            $SubscriptionName = $Subscription.Name
            $SubscriptionID = $Subscription.SubscriptionId

            # Check for Custom Role
            $CheckForCustomRole = Get-AzRoleDefinition -Name $RoleDefinitionName
            $CustomRole = $CheckForCustomRole.IsCustom

            # Create new PSObject
            $obj = New-Object -TypeName PSObject
            $obj | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value $SubscriptionName
            $obj | Add-Member -MemberType NoteProperty -Name SubscriptionID -Value $SubscriptionID
            $obj | Add-Member -MemberType NoteProperty -Name DisplayName -Value $DisplayName
            $obj | Add-Member -MemberType NoteProperty -Name SignInName -Value $SignInName
            $obj | Add-Member -MemberType NoteProperty -Name ObjectType -Value $ObjectType
            $obj | Add-Member -MemberType NoteProperty -Name RoleDefinitionName -Value $RoleDefinitionName
            $obj | Add-Member -MemberType NoteProperty -Name CustomRole -Value $CustomRole
            $obj | Add-Member -MemberType NoteProperty -Name AssignmentScope -Value $AssignmentScope

            # Add object to report
            $report += $obj
        } catch {
            # Log errors to the error log file
            $errorMsg = "Error processing role assignment in subscription $($Subscription.Name): $_"
            Add-Content -Path $errorLogFile -Value $errorMsg
            Write-Verbose $errorMsg
        }
    }
}

# Export the report to CSV in the script directory if no custom path is provided
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if (-not $OutputPath) {
    $OutputPath = $PSScriptRoot
}

$csvFilePath = Join-Path $OutputPath "RoleExport_$timestamp.csv"

Write-Verbose "Exporting CSV file to $csvFilePath" -Verbose
$report | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Role assignments exported to $csvFilePath"
Write-Host "Error log written to: $errorLogFile"