# Connect to Microsoft Graph with the required permissions
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All" -NoWelcome

# Function to fetch users and their registered MFA phone methods
function Get-UsersWithMfaPhone {
    # Initialize an array to store user details
    $userDetails = @()

    # Fetch users and iterate through each one
    $users = Get-MgUser -All
    foreach ($user in $users) {
        # Fetch phone authentication methods for each user
        try {
            $phoneMethods = Get-MgUserAuthenticationPhoneMethod -UserId $user.Id
            foreach ($phoneMethod in $phoneMethods) {
                $detail = [PSCustomObject]@{
                    UserId = $user.Id
                    UserPrincipalName = $user.UserPrincipalName
                    PhoneType = $phoneMethod.PhoneType
                    PhoneNumber = $phoneMethod.PhoneNumber
                    CountryCode = $phoneMethod.CountryCode
                }
                $userDetails += $detail
            }
        } catch {
            Write-Host "Failed to retrieve phone method for user: $($user.UserPrincipalName)"
        }
    }

    # Return the user details array
    return $userDetails
}

# Execute the function and store results
$userMfaDetails = Get-UsersWithMfaPhone

# Display the results in a formatted table
$userMfaDetails | Format-Table -AutoSize

# Optionally, export to CSV
$userMfaDetails | Export-Csv -Path "UserMfaPhoneNumbers.csv" -NoTypeInformation

# Disconnect from the Graph session
Disconnect-MgGraph