<#
.SYNOPSIS
    AzureAdminRoleExporter - Export Azure Subscription Administrator Roles to CSV.

.DESCRIPTION
    This PowerShell script iteratively accesses all Azure subscriptions available to the user, extracts users with Owner, Contributor, and Reader roles, and compiles the information into a neatly formatted CSV file. It's designed to provide security architects and consultants with a quick overview of access roles across Azure environments. The script also displays the information on-screen for immediate review.

    The export includes detailed information such as the subscription ID, subscription name, user ID, user display name, user role, and the scope of the assignment. This tool is invaluable for auditing, compliance checks, and ensuring that the principle of least privilege is maintained across your Azure subscriptions.

.REQUIREMENTS
    - PowerShell 5.1 or higher.
    - Azure PowerShell module (Az Module).
    - User must have read access to all subscriptions and the necessary permissions to query Azure Active Directory.

.PARAMETERS
    None required. The script automatically handles the authentication and enumeration of subscriptions.

.EXAMPLE
    .\AzureAdminRoleExporter.ps1
    This command runs the script, enumerating all subscriptions the authenticated user has access to, and exports the roles to a CSV file named 'AzureAdminRoles.csv'.

.OUTPUTS
    AzureAdminRoles.csv: A CSV file containing the detailed role assignments across all accessed Azure subscriptions. It's saved in the same directory from which the script is executed.

.NOTES
    Version:        1.0
    Author:         Shaun Hardneck (ThatLazyAdmin)
    GitHub Repo:    https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main
    Blog:           www.thatlazyadmin.com
    Purpose/Change: Initial script development for auditing Azure subscription access roles.

#>
# Login to Azure Account
Connect-AzAccount

# Fetch all subscriptions the user has access to
$subscriptions = Get-AzSubscription

# Prepare an array to hold user role assignments across all subscriptions
$userRoleAssignments = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Select the subscription to work on
    Set-AzContext -SubscriptionId $subscription.Id

    # Get role assignments for the current subscription
    $roleAssignments = Get-AzRoleAssignment | Where-Object { $_.RoleDefinitionName -eq 'Owner' -or $_.RoleDefinitionName -eq 'Contributor' -or $_.RoleDefinitionName -eq 'Reader' }

    # Loop through each role assignment
    foreach ($roleAssignment in $roleAssignments) {
        # Fetch user details from Azure AD
        $user = Get-AzADUser -ObjectId $roleAssignment.ObjectId

        # Construct a custom object for each role assignment
        $userRoleAssignment = [PSCustomObject]@{
            SubscriptionId = $subscription.Id
            SubscriptionName = $subscription.Name
            UserId = $user.Id
            UserDisplayName = $user.DisplayName
            UserRole = $roleAssignment.RoleDefinitionName
            AssignmentScope = $roleAssignment.Scope
        }

        # Add the custom object to the array
        $userRoleAssignments += $userRoleAssignment
    }
}

# Display the results on screen
$userRoleAssignments | Format-Table -Property SubscriptionName, UserDisplayName, UserRole, AssignmentScope -AutoSize

# Export the results to a CSV file
$csvPath = "AzureAdminRoles.csv"
$userRoleAssignments | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "Export completed. The details are available in '$csvPath'."
