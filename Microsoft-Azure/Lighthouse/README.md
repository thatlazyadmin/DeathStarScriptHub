# Deploy-AzureLighthouseToAllSubscriptions.ps1

## Overview

This PowerShell script, `Deploy-AzureLighthouseToAllSubscriptions.ps1`, is designed to automate the deployment of the Microsoft Azure Lighthouse JSON file across all Azure subscriptions associated with a single Azure account. The script connects to Azure, iterates through all subscriptions, sets the context for each subscription, and deploys the specified Azure Lighthouse JSON file.

## Purpose

Created by: Shaun Hardneck  
Blog: [ThatLazyAdmin](https://www.thatlazyadmin.com)

The primary purpose of this script is to streamline the process of deploying Azure Lighthouse across multiple subscriptions. Azure Lighthouse enables cross-tenant management, allowing service providers to manage resources in their customers' environments at scale. By automating this deployment, we ensure consistency, reduce manual errors, and save time.

## Benefits

### Automation

- **Efficiency**: Automates the deployment process, saving time and reducing manual effort.
- **Consistency**: Ensures the Azure Lighthouse JSON file is deployed uniformly across all subscriptions.

### Scalability

- **Mass Deployment**: Capable of deploying to numerous subscriptions within minutes, making it ideal for large-scale environments.
- **Repeatability**: The script can be reused whenever there is a need to deploy or update the Azure Lighthouse configuration.

### Error Reduction

- **Minimize Human Error**: By automating the process, the risk of manual errors is significantly reduced.
- **Validation**: Includes verbose logging to help track the deployment process and troubleshoot any issues.

## How to Use

1. **Prerequisites**:
   - Azure PowerShell Module: Ensure you have the Azure PowerShell module installed. If not, you can install it using `Install-Module -Name Az -AllowClobber -Force`.

2. **Execution**:
   - Open PowerShell and navigate to the directory where the script is located.
   - Run the script using the following command:
     ```powershell
     .\Deploy-AzureLighthouseToAllSubscriptions.ps1
     ```

3. **Parameters**:
   - The script does not require any parameters. It will automatically connect to Azure, retrieve all subscriptions, and deploy the Azure Lighthouse JSON file to each subscription.

## Script Details

```powershell
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
```
### Conclusion
This script is a powerful tool for administrators and managed service providers who need to deploy Azure Lighthouse configurations across multiple subscriptions efficiently. By leveraging automation, this script ensures a consistent and error-free deployment process, enhancing operational efficiency and scalability.

For more information and other useful scripts, visit [ThatLazyAdmin](https://www.thatlazyadmin.com).

This `README.md` file provides a comprehensive overview of the script, its purpose, benefits, usage instructions, and the actual script details. It is designed to help users understand the importance and functionality of the script quickly.
