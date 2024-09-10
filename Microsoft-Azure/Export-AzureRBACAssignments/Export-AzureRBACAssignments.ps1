# Azure RBAC Role Assignment Export Script
# Created by: Shaun Hardneck
# This script loops through all Azure subscriptions and exports RBAC role assignments to a CSV file.
# The script also collects role assignments at the Resource Group level.

# Import necessary modules
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module -Name Az -Force -Scope CurrentUser -AllowClobber
}
Import-Module Az.Accounts
if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    Install-Module -Name Az.Resources -Force -Scope CurrentUser -AllowClobber
}
Import-Module Az.Resources

# Login to Azure
Connect-AzAccount

# Function to get role assignments for a subscription
function Get-RoleAssignmentsForSubscription {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    # Set the Azure context to the current subscription
    Set-AzContext -SubscriptionId $SubscriptionId

    # Get all role assignments for the subscription
    $roleAssignments = Get-AzRoleAssignment

    # Prepare the output for CSV
    $roleAssignmentResults = foreach ($assignment in $roleAssignments) {
        $roleDefinition = Get-AzRoleDefinition -RoleDefinitionId $assignment.RoleDefinitionId
        [pscustomobject]@{
            SubscriptionId   = $SubscriptionId
            SubscriptionName = (Get-AzSubscription -SubscriptionId $SubscriptionId).Name
            PrincipalName    = (Get-AzADUser -ObjectId $assignment.PrincipalId).UserPrincipalName
            RoleName         = $roleDefinition.RoleName
            ResourceGroup    = $assignment.Scope -replace "/subscriptions/.+?/resourceGroups/", "" -replace "/.+", ""
            Scope            = $assignment.Scope
        }
    }

    return $roleAssignmentResults
}

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Loop through each subscription and collect role assignments
$allRoleAssignments = @()
foreach ($subscription in $subscriptions) {
    Write-Host "Processing subscription: $($subscription.Name)"
    $roleAssignments = Get-RoleAssignmentsForSubscription -SubscriptionId $subscription.Id
    $allRoleAssignments += $roleAssignments
}

# Export the role assignments to a CSV file
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outputPath = "AzureRoleAssignments_$timestamp.csv"
$allRoleAssignments | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "Role assignments have been exported to: $outputPath"