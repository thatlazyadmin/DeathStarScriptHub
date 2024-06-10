# Script Name: Export-ConditionalAccessPolicies.ps1
# Created by: Shaun Hardneck
# Description: This script exports all available Conditional Access policies in Microsoft Entra ID to a CSV file.

# Import the Microsoft Graph module
Import-Module Microsoft.Graph

# Define the output CSV file path
$outputPath = ".\ConditionalAccessPolicies.csv"

# Authenticate to Microsoft Graph
Connect-MgGraph -Scopes "Policy.Read.All"

# Function to fetch Conditional Access policies
function Get-ConditionalAccessPolicies {
    $policies = @()
    $response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
    
    if ($response.value) {
        $policies += $response.value
        while ($response.'@odata.nextLink') {
            $response = Invoke-MgGraphRequest -Method GET -Uri $response.'@odata.nextLink'
            $policies += $response.value
        }
    }
    return $policies
}

# Fetch all Conditional Access policies
$conditionalAccessPolicies = Get-ConditionalAccessPolicies

# Select properties to export
$policiesToExport = $conditionalAccessPolicies | Select-Object id, displayName, state, conditions, grantControls

# Export policies to CSV
$policiesToExport | Export-Csv -Path $outputPath -NoTypeInformation

# Output the location of the CSV file
Write-Host "Conditional Access policies have been exported to $outputPath"

# End of script