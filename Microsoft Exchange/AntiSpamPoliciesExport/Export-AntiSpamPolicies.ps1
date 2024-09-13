<#
.SYNOPSIS
    This script exports all allowed and blocked senders and domains from Anti-Spam inbound and outbound policies.
    The export shows the email addresses and the policy name where they have been created.
    It allows connections to both GCC and Commercial tenants.
    The export is saved in a CSV file with a date-stamp for easy tracking.
    Created by: Shaun Hardneck
    Blog: www.thatlazyadmin.com
#>

# Function to Connect to Microsoft 365
function Connect-Tenant {
    param (
        [string]$Environment
    )
    if ($Environment -eq "GCC") {
        Connect-ExchangeOnline -UserPrincipalName $User -ConnectionUri "https://outlook.office365.us/powershell-liveid/" -AzureADAuthorizationEndPointUri "https://login.microsoftonline.us/common"
    } else {
        Connect-ExchangeOnline -UserPrincipalName $User
    }
}

# Date-stamp for the export file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# CSV file path
$exportFile = "AntiSpamPolicies_Export_$timestamp.csv"

# Clear the screen before starting
Clear-Host

# Prompt user to connect to GCC or Commercial tenant
Write-Host "Please enter the tenant type to connect to (GCC or Commercial)" -ForegroundColor Cyan
$tenantChoice = Read-Host
$User = Read-Host -Prompt "Enter your User Principal Name (UPN) for authentication"

# Connect to the chosen tenant
Connect-Tenant -Environment $tenantChoice

# Initialize an empty array to store the results
$results = @()

# Fetch Inbound Anti-Spam Policies (Inbound Filtering)
$inboundPolicies = Get-HostedContentFilterPolicy

# Fetch Outbound Anti-Spam Policies
$outboundPolicies = Get-HostedOutboundSpamFilterPolicy

# Loop through Inbound Policies and extract allowed/blocked senders and domains
foreach ($policy in $inboundPolicies) {
    foreach ($allowedSender in $policy.AllowedSenders) {
        $results += [pscustomobject]@{
            PolicyType = "Inbound"
            PolicyName = $policy.Name
            SenderType = "Allowed"
            EmailAddress = $allowedSender
        }
    }

    foreach ($blockedSender in $policy.BlockedSenders) {
        $results += [pscustomobject]@{
            PolicyType = "Inbound"
            PolicyName = $policy.Name
            SenderType = "Blocked"
            EmailAddress = $blockedSender
        }
    }
}

# Loop through Outbound Policies and extract allowed/blocked senders and domains
foreach ($policy in $outboundPolicies) {
    foreach ($allowedSender in $policy.AllowedSenders) {
        $results += [pscustomobject]@{
            PolicyType = "Outbound"
            PolicyName = $policy.Name
            SenderType = "Allowed"
            EmailAddress = $allowedSender
        }
    }

    foreach ($blockedSender in $policy.BlockedSenders) {
        $results += [pscustomobject]@{
            PolicyType = "Outbound"
            PolicyName = $policy.Name
            SenderType = "Blocked"
            EmailAddress = $blockedSender
        }
    }
}

# Export results to CSV file
$results | Export-Csv -Path $exportFile -NoTypeInformation

# Show completion message
Write-Host "Export completed. Data saved in $exportFile" -ForegroundColor Green

# Disconnect after completion
Disconnect-ExchangeOnline -Confirm:$false