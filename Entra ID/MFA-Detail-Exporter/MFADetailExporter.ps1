
# Connect to Microsoft Graph with the required permissions
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All" -NoWelcome

$token = Get-MgContext
Write-Host "Token: $($token.Token)"

# Fetch users and their MFA phone methods
$users = Get-MgUser -All

foreach ($user in $users) {
    try {
        $phoneMethods = Get-MgUserAuthenticationPhoneMethod -UserId $user.Id
        foreach ($phoneMethod in $phoneMethods) {
            [PSCustomObject]@{
                UserID = $user.Id
                UserPrincipalName = $user.UserPrincipalName
                PhoneType = $phoneMethod.PhoneType
                PhoneNumber = $phoneMethod.PhoneNumber
                CountryCode = $phoneMethod.CountryCode
            } | Export-Csv -Path "UserMfaPhoneNumbers.csv" -NoTypeInformation -Append
        }
    } catch {
        Write-Error "Failed to retrieve phone method for user $($user.UserPrincipalName): $_"
    }
}

# Disconnect from the Graph session
Disconnect-MgGraph