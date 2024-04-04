<#
.SYNOPSIS
AzureSubscriptionPicker: A PowerShell script for connecting to Microsoft Azure, listing all available subscriptions for the signed-in user, and allowing the user to select a subscription interactively.

.DESCRIPTION
The script initiates a connection to Microsoft Azure, retrieves all subscriptions available to the signed-in user, and displays them. The user can then select a subscription to set as the current context, enhancing the management of Azure resources through a user-friendly interface. The script personalizes the experience by incorporating the signed-in user's name in the output.

.AUTHOR
Shaun Hardneck - ThatLazyAdmin
Blog: www.thatlazyadmin.com
Email: shaun@thatlazyadmin.com

.NOTES
Version:        1.0
#>
# PowerShell Script to Connect to Azure, List Subscriptions, and Allow User Selection

# Display Script Header
Write-Host "`nConnecting to Microsoft Azure..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Suppress warnings for the script
$WarningPreference = 'SilentlyContinue'

# Connect to Azure with a popup login window
$azureAccount = Connect-AzAccount -WarningAction SilentlyContinue

# Get the signed-in username
$username = $azureAccount.Context.Account.Id

# Retrieve and list all subscriptions available to the signed-in user
$subscriptions = Get-AzSubscription -WarningAction SilentlyContinue

# Personalized header with the signed-in user's name
Write-Host "`nMicrosoft Azure Subscriptions Available to ${username}:" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

# Display each subscription with an index
for ($i=0; $i -lt $subscriptions.Count; $i++) {
    Write-Host "$($i+1): $($subscriptions[$i].Name) [SubscriptionId: $($subscriptions[$i].Id)]" -ForegroundColor Yellow
}

# Ask the user to select a subscription by number
Write-Host "`nPlease select a subscription by entering the corresponding number:" -ForegroundColor Cyan
$selectedSubscriptionIndex = Read-Host "Enter number (1-$($subscriptions.Count))"

# Validate user input
while (-not ($selectedSubscriptionIndex -match '^\d+$') -or 
       [int]$selectedSubscriptionIndex -lt 1 -or 
       [int]$selectedSubscriptionIndex -gt $subscriptions.Count) {
    Write-Host "Invalid selection. Please select a number between 1 and $($subscriptions.Count)." -ForegroundColor Red
    $selectedSubscriptionIndex = Read-Host "Enter number (1-$($subscriptions.Count))"
}

# Set the context to the selected subscription
$selectedSubscription = $subscriptions[[int]$selectedSubscriptionIndex - 1]
Set-AzContext -SubscriptionId $selectedSubscription.Id

Write-Host "`nYou are now connected to subscription: $($selectedSubscription.Name) [SubscriptionId: $($selectedSubscription.Id)]" -ForegroundColor Green