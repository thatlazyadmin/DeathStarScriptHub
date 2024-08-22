<#
.SYNOPSIS
    This script audits role assignment policies in Microsoft 365 to ensure "My Custom Apps", "My Marketplace Apps", and "My ReadWriteMailboxApps" are not present. The results are exported to a CSV file with a current date stamp.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    The script performs the following actions:
    1. Connects to Exchange Online using the provided credentials.
    2. Retrieves role assignment policies and checks for "My Custom Apps", "My Marketplace Apps", and "My ReadWriteMailboxApps".
    3. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Audit-RoleAssignmentPolicies.ps1
    This example runs the script to audit role assignment policies and verify that "My Custom Apps", "My Marketplace Apps", and "My ReadWriteMailboxApps" are not present. Results are exported to a CSV file.

.NOTES
    This script is necessary to ensure that the specified app roles are not assigned, enhancing the security and compliance posture of the organization.
#>

# Import required modules
# Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

# Connect to Exchange Online
try {
    Connect-ExchangeOnline -ShowProgress $true
    Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Exchange Online. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to audit role assignment policies
function Audit-RoleAssignmentPolicies {
    try {
        $mailboxes = Get-EXOMailbox | Select-Object -Unique RoleAssignmentPolicy
        $results = @()

        foreach ($mailbox in $mailboxes) {
            $rolePolicy = Get-RoleAssignmentPolicy -Identity $mailbox.RoleAssignmentPolicy
            $appRoles = $rolePolicy.AssignedRoles | Where-Object { $_ -like "*Apps*" }

            if ($appRoles) {
                foreach ($appRole in $appRoles) {
                    $results += [PSCustomObject]@{
                        Identity      = $rolePolicy.Identity
                        AssignedRoles = $appRole
                    }
                }
            }
        }

        if ($results.Count -gt 0) {
            Write-Host "Role assignment policies with app roles found." -ForegroundColor Red
            $results | Format-Table Identity, AssignedRoles

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "RoleAssignmentPoliciesAudit_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No role assignment policies with app roles found." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to retrieve role assignment policies. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Audit-RoleAssignmentPolicies