<#
.SYNOPSIS
    This script verifies that Office 365 passwords are not set to expire by checking the PasswordValidityPeriodInDays property for each domain.
    It connects to Microsoft Graph and retrieves the password policy settings for specified domains.

    Created by: Shaun Hardneck
    Contact: Shaun@hrdneck.co.za
    Blog: www.thatlazyadmin.com

.DESCRIPTION
    This script performs the following actions:
    1. Connects to Microsoft Graph using the provided scope "Domain.Read.All".
    2. Retrieves the password policy settings for each domain, specifically the PasswordValidityPeriodInDays property.
    3. Displays the password validity period for each domain.
    4. Exports the results to a CSV file with a current date stamp.

.PARAMETER None

.EXAMPLE
    .\Check-PasswordExpirationPolicy.ps1
    This example runs the script to check if Office 365 passwords are set to expire and export the results to a CSV file.

.NOTES
    This script is necessary to ensure that password policies are aligned with organizational security requirements.
    By verifying that passwords are not set to expire, administrators can maintain compliance with best practices for password management.
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

# Function to check password expiration policy
function Check-PasswordExpirationPolicy {
    try {
        $domains = Get-MgDomain
        $results = @()

        foreach ($domain in $domains) {
            $domainDetails = Get-MgDomain -DomainId $domain.Id -Property PasswordValidityPeriodInDays
            $results += [PSCustomObject]@{
                DomainName                   = $domainDetails.Id
                PasswordValidityPeriodInDays = $domainDetails.PasswordValidityPeriodInDays
            }
        }

        $totalCount = $results.Count

        if ($totalCount -gt 0) {
            Write-Host "Password expiration policy retrieved for $totalCount domains." -ForegroundColor Green
            $results | Format-Table DomainName, PasswordValidityPeriodInDays

            # Export to CSV
            $currentDate = Get-Date -Format "yyyyMMdd"
            $fileName = "PasswordExpirationPolicy_$currentDate.csv"
            $results | Export-Csv -Path $fileName -NoTypeInformation
            Write-Host "Exported password expiration policy results to $fileName" -ForegroundColor Green
        } else {
            Write-Host "No domains found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to retrieve domain information. Please ensure you have the necessary permissions." -ForegroundColor Red
    }
}

# Execute the function
Check-PasswordExpirationPolicy