# Requires Active Directory module
Import-Module ActiveDirectory

# Define the path to the input text file and the output CSV file
$inputFilePath = "C:\Path\To\Your\File.txt"
$outputCsvPath = "C:\Path\To\Your\Output.csv"

# Prepare an empty array to store the results
$userDetails = @()

# Read each line from the text file
Get-Content $inputFilePath | ForEach-Object {
    # Split the line into username and domain
    $parts = $_ -split ','
    $username = $parts[0].Trim()
    $domain = $parts[1].Trim()

    # Query Active Directory for user details
    $adUser = Get-ADUser -Filter "SamAccountName -eq '$username'" -Properties DisplayName, UserPrincipalName, LastLogon -Server "$domain"
    
    if ($adUser) {
        # Convert LastLogon timestamp to readable format
        $lastLogonDate = [DateTime]::FromFileTime($adUser.LastLogon)

        # Create a custom object with the desired properties
        $userDetail = [PSCustomObject]@{
            UPN         = $adUser.UserPrincipalName
            DisplayName = $adUser.DisplayName
            Domain      = $domain
            LastLogon   = $lastLogonDate
        }

        # Add the custom object to the details array
        $userDetails += $userDetail
    } else {
        Write-Host "User not found: $username"
    }
}

# Export the array of user details to a CSV file
$userDetails | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Host "Export completed successfully. Check the output file at $outputCsvPath" -ForegroundColor Green