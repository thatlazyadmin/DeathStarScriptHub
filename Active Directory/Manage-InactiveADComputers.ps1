# Import Active Directory Module
Import-Module ActiveDirectory

# Get current date
$CurrentDate = Get-Date

# Define 90 days
$DaysInactive = 90

# Calculate the target date
$InactiveDate = $CurrentDate.AddDays(-$DaysInactive)

# Search for computers inactive for more than 90 days
$InactiveComputers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $InactiveDate -and Enabled -eq $true} -Properties Name, LastLogonTimeStamp

# Check if there are any inactive computers
if ($InactiveComputers) {
    # Prompt to export results
    $ExportChoice = Read-Host "Do you want to export the list of inactive computers to a text file? (Y/N)"
    if ($ExportChoice -eq 'Y') {
        $InactiveComputers | Select-Object Name | Out-File -FilePath "InactiveComputers.txt"
        Write-Host "List of inactive computers exported to InactiveComputers.txt"
    }

    # Prompt for disabling and moving computers
    $DisableMoveChoice = Read-Host "Do you want to disable and move the inactive computers to the Disabled Computers OU? (Y/N)"
    if ($DisableMoveChoice -eq 'Y') {
        Write-Host "Ensure you have a Disabled Computer OU created before proceeding."
        $DisabledOUPath = Read-Host "Enter the LDAP path for the Disabled Computers OU (e.g., 'OU=Disabled Computers,DC=domain,DC=com')"
        
        foreach ($Computer in $InactiveComputers) {
            # Disable the computer account
            Disable-ADAccount -Identity $Computer

            # Move the computer account to the Disabled Computers OU
            Move-ADObject -Identity $Computer -TargetPath $DisabledOUPath

            Write-Host "Computer $($Computer.Name) has been disabled and moved to the Disabled Computers OU."
        }

        # Export the results
        $InactiveComputers | Select-Object Name | Out-File -FilePath "DisabledAndMovedComputers.txt"
        Write-Host "List of disabled and moved computer accounts exported to DisabledAndMovedComputers.txt"
    }
} else {
    Write-Host "No inactive computers found for more than $DaysInactive days."
}
