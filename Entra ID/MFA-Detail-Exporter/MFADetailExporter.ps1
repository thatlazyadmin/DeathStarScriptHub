# Connect to Azure AD with modern authentication methods
Connect-AzureAD

# Fetch all users; consider adding filters to limit the scope in large environments
$Users = Get-AzureADUser -All $true

# Create output list
$Report = [System.Collections.Generic.List[Object]]::new()

Write-Host "Processing" $Users.Count "accounts..."

foreach ($User in $Users) {
    try {
        # Get MFA details and other properties via Graph API (needs proper permissions setup)
        $authMethods = Get-MgUserAuthenticationMethod -UserId $User.ObjectId
        $defaultMethod = $authMethods | Where-Object { $_.IsDefault -eq $true } | Select-Object -First 1
        $MFADefaultMethod = $defaultMethod.MethodType
        $MFAPhoneNumber = $defaultMethod.PhoneNumber

        # Prepare SMTP and alias details
        $PrimarySMTP = $User.ProxyAddresses | Where-Object { $_ -clike "SMTP*" } | ForEach-Object { $_ -replace "SMTP:", "" }
        $Aliases = $User.ProxyAddresses | Where-Object { $_ -clike "smtp*" } | ForEach-Object { $_ -replace "smtp:", "" }

        # Determine MFA state and modify strings for readability
        $MFAState = if ($User.StrongAuthenticationRequirements) { $User.StrongAuthenticationRequirements.State } else { 'Disabled' }
        $MFADefaultMethod = switch ($MFADefaultMethod) {
            "OneWaySMS" { "Text code authentication phone" }
            "TwoWayVoiceMobile" { "Call authentication phone" }
            "TwoWayVoiceOffice" { "Call office phone" }
            "PhoneAppOTP" { "Authenticator app or hardware token" }
            "PhoneAppNotification" { "Microsoft authenticator app" }
            default { "Not enabled" }
        }

        # Include user manager and company name
        $ManagerDetails = Get-MgUserManager -UserId $User.ObjectId | Select-Object -ExpandProperty Mail
        $CompanyName = (Get-MgUser -UserId $User.ObjectId -Property CompanyName).CompanyName

        # Add details to the report
        $ReportLine = [PSCustomObject]@{
            UserPrincipalName = $User.UserPrincipalName
            DisplayName       = $User.DisplayName
            FirstName         = $User.GivenName
            LastName          = $User.Surname
            UserType          = $User.UserType
            Department        = $User.Department
            MFAState          = $MFAState
            MFADefaultMethod  = $MFADefaultMethod
            MFAPhoneNumber    = $MFAPhoneNumber
            PrimarySMTP       = ($PrimarySMTP -join ',')
            Aliases           = ($Aliases -join ',')
            AccountStatus     = if ($User.AccountEnabled) { "Enabled" } else { "Disabled" }
            Manager           = $ManagerDetails
            CompanyName       = $CompanyName
            License           = $User.IsLicensed
            Licensedetails    = $User.Licenses
        }
        $Report.Add($ReportLine)
    } catch {
        Write-Host "Failed to process user $($User.UserPrincipalName): $_"
    }
}

Write-Host "Report is in c:\temp\MFAUsers.csv"
$Report | Export-Csv -Path "c:\temp\MFAUsers.csv" -NoTypeInformation -Encoding UTF8