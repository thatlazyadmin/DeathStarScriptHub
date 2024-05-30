# PowerShell Script to Search Audit Logs in Microsoft Purview

# Import required modules
Import-Module ExchangeOnlineManagement
Import-Module AzureAD

# Function to connect to Microsoft 365 services
function Connect-M365Services {
    $UserCredential = Get-Credential
    Connect-ExchangeOnline -Credential $UserCredential
    Connect-AzureAD -Credential $UserCredential
}

# Function to search Audit Logs
function Search-AuditLogs {
    param (
        [Parameter(Mandatory = $true)]
        [datetime]$StartDate,

        [Parameter(Mandatory = $true)]
        [datetime]$EndDate,

        [Parameter(Mandatory = $true)]
        [string[]]$Activities
    )

    # Convert dates to the required format
    $formattedStartDate = $StartDate.ToString("yyyy-MM-ddTHH:mm:ss")
    $formattedEndDate = $EndDate.ToString("yyyy-MM-ddTHH:mm:ss")

    # Search Audit Logs
    $searchResults = Search-UnifiedAuditLog -StartDate $formattedStartDate -EndDate $formattedEndDate -Operations $Activities

    # Output the results
    return $searchResults
}

# Main script
Connect-M365Services

# Define search parameters
$startDate = Read-Host -Prompt "Enter the start date (e.g., 2023-01-01)"
$endDate = Read-Host -Prompt "Enter the end date (e.g., 2023-01-31)"
$activities = @("FileAccessed", "FileModified") # Update this array based on required activities

# Execute search
$results = Search-AuditLogs -StartDate $startDate -EndDate $endDate -Activities $activities

# Display results
$results | Format-Table -AutoSize
