# Azure Role Assignments Export Script

This PowerShell script exports all Role Assignments for your Azure Subscriptions, providing detailed information on users, groups, and service principals assigned to roles. The output includes details like DisplayName, SignInName, ObjectType (User, Group, Service Principal), the assigned role, and whether it's a custom or built-in role.

## Features
- Exports Role Assignments for all subscriptions in your tenant or for a selected subscription.
- Provides detailed information about each role assignment.
- Exports the results to a CSV file in the same directory as the script or a specified output path.
- Logs any errors encountered during execution to a `.txt` file.
- Handles both custom roles and built-in roles.
  
## Prerequisites
- **Azure PowerShell Module**: Ensure that you have the Azure PowerShell module installed. You can install it using:
  
  ```powershell
  Install-Module -Name Az -AllowClobber -Force

## Azure Subscription Access: 
 - You need appropriate access to view role assignments in the subscriptions you want to query.

## Parameters
- OutPutPath: (Optional) Specify the path where the CSV export file should be saved. If not provided, the file will be saved in the same directory where the script is executed.

- SelectCurrentSubscription: (Optional) If provided, only the currently selected subscription will be queried for role assignments. Otherwise, all subscriptions in the tenant will be queried.

## How to Use
## Export Role Assignments for All Subscriptions
To export role assignments for all subscriptions in your tenant, run the script without any parameters:

 ```powershell
.\Export-RoleAssignments.ps1
 ```
This will export the role assignments to a CSV file in the same directory where the script is executed.

## Export Role Assignments for All Subscriptions to a Specific Directory
If you want to specify a directory for the export, use the -OutPutPath parameter:

 ```powershell
.\Export-RoleAssignments.ps1 -OutPutPath C:\temp
 ```
## Export Role Assignments for the Current Subscription Only
To export role assignments for the currently selected subscription:

 ```powershell
.\Export-RoleAssignments.ps1 -SelectCurrentSubscription
 ```
## Export Role Assignments for the Current Subscription to a Specific Directory
To export the role assignments for the current subscription and specify the export directory:

 ```powershell
.\Export-RoleAssignments.ps1 -SelectCurrentSubscription -OutPutPath C:\temp
 ```
## Error Handling
 - Errors encountered during execution (e.g., empty RoleDefinitionNames or API issues) will be logged to a .txt file in the same directory where the script is executed.
 - The log file is named with the format RoleAssignmentErrors_yyyyMMdd_HHmmss.txt based on the time of execution.

## Output
The output of the script is a CSV file with the following columns:

 - SubscriptionName: The name of the subscription.
 - SubscriptionID: The ID of the subscription.
 - DisplayName: The display name of the principal (user, group, or service principal).
 - SignInName: The sign-in name (UPN) of the principal.
 - ObjectType: The type of the principal (User, Group, Service Principal).
 - RoleDefinitionName: The name of the role (e.g., Contributor, Reader).
 - CustomRole: Whether the role is a custom role or built-in.
 - AssignmentScope: The scope of the role assignment (e.g., subscription, resource group).

## Known Issues
 - Empty RoleDefinitionName: If some role assignments have an empty RoleDefinitionName, they will be skipped and logged in the error file.
 - API Rate Limits: If you are running the script for a large number of subscriptions or roles, you may encounter rate limit issues. Retry after some time if needed.

## Contact & Support
For any issues, updates, or requests for additional features, please feel free to contact Shaun Hardneck via:

Blog: [That Lazy Admin Blog](https://www.thatlazyadmin.com)
Author: Shaun Hardneck
Version: 1.3
Date: 2024-09-10


This `README.md` provides clear instructions on using the script, highlights its features, and offers guidance on how to run it with different options. It also covers error handling and outputs, making it easy for users to get started.

