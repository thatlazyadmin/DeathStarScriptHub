<#
.SYNOPSIS
    MFA Phone Method Exporter Script.

.DESCRIPTION
    This script connects to Microsoft Graph, retrieves user MFA phone methods, and exports the details to a CSV file.
    It suppresses error messages related to access issues and provides a success message upon completion.

.AUTHOR
    Shaun Hardneck (ThatLazyAdmin)
    Blog: www.thatlazyadmin.com
#>

# Permanent banner with a funky nerdy logo
$banner = @"
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@##++............++++##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##++....    ....++####@@@@@@@@@@@@
@@@@##++..              ..........      ..++##@@@@@@@@@@@@@@####....    ..........              ..++##@@@@
@@..          ++##@@@@@@@@@@@@@@@@@@@@##..                        ++##@@@@@@@@@@@@@@@@@@##++..        ..@@
@@..        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..                ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++      ..@@
@@++      ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      ..@@
@@@@..    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..    @@@@
@@@@@@    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  ++####    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..  ##@@@@
@@@@@@..  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..  @@@@@@##  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@
@@@@@@##  ++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ++@@@@@@@@  ++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ..@@@@@@
@@@@@@@@  ..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  ##@@@@@@@@..  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##  ##@@@@@@
@@@@@@@@..  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@##  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  @@@@@@@@
@@@@@@@@##  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@++  ##@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ..@@@@@@@@
@@@@@@@@@@  ..@@@@@@@@@@@@@@@@@@@@@@@@@@##  ..@@@@@@@@@@@@@@##  ..@@@@@@@@@@@@@@@@@@@@@@@@@@##  ##@@@@@@@@
@@@@@@@@@@++  ++@@@@@@@@@@@@@@@@@@@@@@##    @@@@@@@@@@@@@@@@@@++  ++@@@@@@@@@@@@@@@@@@@@@@@@  ..@@@@@@@@@@
@@@@@@@@@@@@..  ++@@@@@@@@@@@@@@@@@@++    @@@@@@@@@@@@@@@@@@@@@@++  ..##@@@@@@@@@@@@@@@@##  ..@@@@@@@@@@@@
@@@@@@@@@@@@@@++    ..++++####++..    ..@@@@@@@@@@@@@@@@@@@@@@@@@@##      ++++####++..    ++@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@++..            ..##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##..          ..++@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
"@

Write-Host $banner -ForegroundColor Cyan

# Connect to Microsoft Graph with the required permissions
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All" -NoWelcome

$token = Get-MgContext
Write-Host "Token: $($token.Token)" -ForegroundColor Green

# Fetch users and their MFA phone methods
$users = Get-MgUser -All

# Get current date for file naming
$currentDate = Get-Date -Format "yyyy-MM-dd"
$outputFile = "UserMfaPhoneNumbers_$currentDate.csv"

foreach ($user in $users) {
    try {
        $phoneMethods = Get-MgUserAuthenticationPhoneMethod -UserId $user.Id -ErrorAction Stop
        foreach ($phoneMethod in $phoneMethods) {
            [PSCustomObject]@{
                UserID = $user.Id
                UserPrincipalName = $user.UserPrincipalName
                PhoneType = $phoneMethod.PhoneType
                PhoneNumber = $phoneMethod.PhoneNumber
                CountryCode = $phoneMethod.CountryCode
            } | Export-Csv -Path $outputFile -NoTypeInformation -Append
        }
    } catch {
        # Suppress error messages by continuing silently
        $ErrorActionPreference = "SilentlyContinue"
    }
}

# Success message
Write-Host "Details have been successfully exported to $outputFile" -ForegroundColor Green

# Disconnect from the Graph session
Disconnect-MgGraph
