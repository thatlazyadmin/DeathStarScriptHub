# Ensure the Az and AzureAD modules are loaded
#Import-Module Az
#Import-Module AzureAD

# Function to get the new domain name using Read-Host for command-line input
function Get-NewDomainName {
    $domainName = Read-Host "Enter the new domain name (e.g., example.com)"
    if ([string]::IsNullOrEmpty($domainName)) {
        Write-Host "Domain name cannot be empty." -ForegroundColor Red
        exit
    }
    return $domainName
}

# Function to choose Azure subscription using command-line interface
function Select-AzureSubscription {
    $subscriptions = Get-AzSubscription | Select-Object Name, Id

    Write-Host "Available Subscriptions:" -ForegroundColor Green
    $index = 1
    $subscriptions | ForEach-Object { 
        Write-Host "$index`: $($_.Name)" -ForegroundColor Green
        $index++
    }

    $selectedNumber = Read-Host "Select a subscription by number"
    $selectedSubscription = $subscriptions[$selectedNumber - 1]

    Set-AzContext -SubscriptionId $selectedSubscription.Id

    Write-Host "Selected subscription: $($selectedSubscription.Name)" -ForegroundColor Green
    return $selectedSubscription
}

# Function to add the domain to Azure AD with specified capabilities
function Add-DomainToAzureAD {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DomainName,
        [string[]]$SupportedServices
    )

    # Connect to Azure AD
    Connect-AzureAD

    # Add the custom domain to Azure AD with specified capabilities
    $newDomain = New-AzureADDomain -Name $DomainName -SupportedServices $SupportedServices

    if ($null -ne $newDomain) {
        Write-Host "Domain '$DomainName' was added to Azure AD with the specified capabilities. Please verify it by adding the provided DNS record." -ForegroundColor Green

        # Inform the user about the DNS verification requirement
        Write-Host "Please add the provided DNS record to your domain's DNS settings to verify domain ownership." -ForegroundColor Green
    }
    else {
        Write-Host "Failed to add domain '$DomainName' to Azure AD." -ForegroundColor Red
    }
}

# Main function to create a new Azure domain
function Create-NewAzureDomain {
    # Authenticate and select Azure Subscription
    Connect-AzAccount
    $selectedSubscription = Select-AzureSubscription

    # Get the new domain name from user input
    $newDomainName = Get-NewDomainName

    # Define the supported services for the new domain
    $supportedServices = @("Email", "OfficeCommunicationsOnline")

    # Add the domain to Azure AD with the specified capabilities
    Add-DomainToAzureAD -DomainName $newDomainName -SupportedServices $supportedServices
}

# Invoke the main function
Create-NewAzureDomain
