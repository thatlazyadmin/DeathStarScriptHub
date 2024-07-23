<#
.SYNOPSIS
    This script retrieves all domains in Microsoft 365 using the Microsoft Graph PowerShell module.

    Created by: Shaun Hardneck
    Contact: Shaun@thatlazyadmin.com
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Microsoft Graph using the provided scope "Domain.Read.All".
    2. Retrieves the list of all domains in the Microsoft 365 tenant.
    3. Displays the list of domains.
    4. Exports the list of domains to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Get-M365Domains.ps1
    This example runs the script to retrieve all domains in Microsoft 365 and export the results to a CSV file.
#>

# Import required modules
# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "Domain.Read.All" -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and network connection." -ForegroundColor Red
    exit
}

# Function to get all domains
function Get-M365Domains {
    try {
        $domains = Get-MgDomain -ErrorAction Stop
        $domainList = @()

        foreach ($domain in $domains) {
            $domainList += [PSCustomObject]@{
                DomainName = $domain.Id
                AuthenticationType = $domain.AuthenticationType
                IsVerified = $domain.IsVerified
            }
        }

        $totalCount = $domainList.Count

        if ($totalCount -gt 0) {
            Write-Host "Total domains found: $totalCount" -ForegroundColor Green
            $domainList | Format-Table DomainName, AuthenticationType, IsVerified

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "M365Domains_$currentDate.csv"
            $domainList | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported domain list to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No domains found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve domain information. Please ensure you have the necessary permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Execute the function
Get-M365Domains