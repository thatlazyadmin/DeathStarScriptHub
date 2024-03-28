# Created By: Shaun Hardneck (ThatLazyAdmin)
# www.thatlazyadmin.com
# PowerShell Script: EntraExternalToInternalConverter.ps1

########################################################################################################################
# Requires the Microsoft Graph PowerShell SDK
# Install it using: Install-Module Microsoft.Graph

# Authenticate and suppress the welcome message
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.AccessAsUser.All" -NoWelcome

# Prompt for the external account name with an example
Write-Host "Please enter the external account name to convert (e.g., john.doe@external.com):" -ForegroundColor Cyan
$externalAccountName = Read-Host

# Validate non-empty input for externalAccountName
if (-not $externalAccountName) {
    Write-Host "No external account name entered. Exiting script." -ForegroundColor Red
    exit
}

# Prompt for the new UPN prefix with an example
Write-Host "Enter the new UPN prefix (e.g., john.doe):" -ForegroundColor Cyan
$newUPNPrefix = Read-Host

# Get and list domains for selection
Write-Host "Available domains:" -ForegroundColor Magenta
$domains = Get-MgDomain
$domainIndex = 0
foreach ($domain in $domains) {
    Write-Host "$domainIndex`: $($domain.Id)" -ForegroundColor Yellow
    $domainIndex++
}

# Prompt for the domain selection
Write-Host "Select the number for the desired UPN domain:" -ForegroundColor Cyan
$selectedDomainIndex = Read-Host
if ($selectedDomainIndex -lt 0 -or $selectedDomainIndex -ge $domains.Count) {
    Write-Host "Invalid domain selection. Exiting script." -ForegroundColor Red
    exit
}
$selectedDomain = $domains[$selectedDomainIndex].Id

# Prompt for a strong password
Write-Host "Enter a strong password for the new internal user account:" -ForegroundColor Cyan
$strongPassword = Read-Host -AsSecureString

# Complete the UPN with the selected domain
$completeNewUPN = "$newUPNPrefix@$selectedDomain"

# Convert the external user to an internal user with the provided strong password
try {
    Update-MgUser -UserId $externalAccountName -UserPrincipalName $completeNewUPN -PasswordProfile @{ForceChangePasswordNextSignIn = $true; Password = $strongPassword}
    Write-Host "User $externalAccountName has been successfully converted to an internal user with UPN $completeNewUPN." -ForegroundColor Green
} catch {
    Write-Host "Failed to update user: $_" -ForegroundColor Red
}

# Disconnect the Graph session
Disconnect-MgGraph