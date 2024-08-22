# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

# Define the SKU Part Number for the E3 license
$E3SkuPartNumber = "ENTERPRISEPACK"

# Fetch users and filter for those with E3 licenses
$users = Get-MgUser -All -Property id, displayName, assignedLicenses | Where-Object {
    $_.AssignedLicenses.SkuId -match $E3SkuPartNumber
}

# Fetch details for each user with an E3 license
$licenseDetails = foreach ($user in $users) {
    # Fetch license assignment details for the user
    $licenseInfo = $user.AssignedLicenses | Where-Object {
        $_.SkuId -match $E3SkuPartNumber
    }

    # Create a custom object to hold user and license info
    foreach ($license in $licenseInfo) {
        [PSCustomObject]@{
            UserId            = $user.Id
            UserDisplayName   = $user.DisplayName
            LicenseSkuId      = $license.SkuId
            AssignedDate      = $license.AssignedDateTime
        }
    }
}

# Export the data to a CSV file
$licenseDetails | Export-Csv -Path "./E3LicenseDetails.csv" -NoTypeInformation

# Disconnect from Microsoft Graph
Disconnect-MgGraph

# Display a completion message
Write-Host "E3 license details exported to E3LicenseDetails.csv"