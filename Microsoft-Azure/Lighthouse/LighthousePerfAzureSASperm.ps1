# ==============================================================================
# Script Name: Deploy-AzureLighthouseToAllSubscriptions.ps1
# Synopsis: This script connects to Azure, iterates through all subscriptions, 
#           sets the context for each subscription, and deploys the Microsoft Azure Lighthouse JSON file.
# Created By: Shaun Hardneck
# Blog: www.thatlazyadmin.com
# ==============================================================================

<#
.SYNOPSIS
    Connects to Azure, iterates through all subscriptions, sets the context for each subscription, and deploys the Microsoft Azure Lighthouse JSON file.

.DESCRIPTION
    This script uses the Azure PowerShell module to:
    1. Connect to an Azure account.
    2. Retrieve all subscriptions associated with the account.
    3. Set the context to each subscription.
    4. Deploy the Microsoft Azure Lighthouse JSON file to each subscription.

.NOTES
    Author: Shaun Hardneck
    Blog: www.thatlazyadmin.com

.PARAMETER None

.EXAMPLE
    .\Deploy-AzureLighthouseToAllSubscriptions.ps1
    This will connect to Azure, retrieve all subscriptions, and deploy the specified Azure Lighthouse JSON file to each subscription.

#>

# Connect to Azure account
Connect-AzAccount

# Retrieve all subscriptions
$Subs = Get-AzSubscription

# Loop through each subscription and deploy the Azure Lighthouse JSON file
foreach ($sub in $Subs) {
    # Set the context to the current subscription
    Set-AzContext -Subscription $sub.id
    
    # Deploy the Azure Lighthouse JSON file
    New-AzDeployment -Name "AzureLighthouseDeployment" -Location "uksouth" -TemplateFile "AzureLighthouse.json" -Verbose
}

# End of script
