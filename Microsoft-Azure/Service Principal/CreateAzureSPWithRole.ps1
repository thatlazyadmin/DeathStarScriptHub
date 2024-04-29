# Ensures you are logged into your Azure account
Connect-AzAccount

# Display all available subscriptions
$subscriptions = Get-AzSubscription

# Create a menu for subscription selection
for ($i = 0; $i -lt $subscriptions.Count; $i++) {
    Write-Host "$($i+1). $($subscriptions[$i].Name) - $($subscriptions[$i].SubscriptionId)"
}

# User input for selection
$userChoice = Read-Host "Please select a subscription by entering the corresponding number"
$selectedSubscription = $subscriptions[$userChoice - 1]

# Set the Azure context to the selected subscription
Set-AzContext -SubscriptionId $selectedSubscription.SubscriptionId

# Variables
$appName = "PerfCopilotAzureAccessSP"
$roleName = "Privileged IT Admin" # Default role assigned here is Reader for safety

# Register a new Azure AD application and create a service principal
$sp = New-AzADServicePrincipal -DisplayName $appName

# Output the credentials - Important to secure these
$secret = $sp.PasswordCredentials.SecretText
if ($null -ne $secret) {
    Write-Host "Secret: $secret" -ForegroundColor Red
    Write-Host "Store this value securely; it won't be displayed again!" -ForegroundColor Yellow
}

# Assign the role to the service principal (change role as needed)
New-AzRoleAssignment -ApplicationId $sp.ApplicationId -RoleDefinitionName $roleName

# Output the service principal details
Write-Output "Service Principal created:"
Write-Output "Application ID: $($sp.ApplicationId)"
Write-Output "Service Principal ID: $($sp.Id)"
Write-Output "Assigned Role: $roleName"
Write-Output "Selected Subscription: $($selectedSubscription.Name)"

# Get the active tenant ID after creation
$tenantId = (Get-AzContext).Tenant.Id
Write-Output "Tenant ID: $tenantId"