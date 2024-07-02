# Import Active Directory Module
Import-Module ActiveDirectory

# Function to get last logon from all domain controllers
function Get-LastLogon($username) {
    try {
        $user = Get-ADUser -Identity $username -Properties LastLogon
        if ($user.LastLogon -eq $null) {
            return "Never logged on"
        } else {
            return [datetime]::FromFileTime($user.LastLogon).ToString('yyyy-MM-dd HH:mm:ss')
        }
    } catch {
        Write-Host "Error retrieving last logon for user: $username"
        return "Error retrieving logon"
    }
}

# Prompt for group name
$groupName = Read-Host "Please enter the AD group name"

# Initialize array to hold results
$results = @()

try {
    # Retrieve group members including nested group members
    $groupMembers = Get-ADGroupMember -Identity $groupName -Recursive | Where-Object {$_.objectClass -eq 'user'}

    if ($groupMembers) {
        foreach ($member in $groupMembers) {
            if ($member.SamAccountName) {
                # Retrieve user details using SamAccountName
                $userDetails = Get-ADUser -Identity $member.SamAccountName -Properties DisplayName, UserPrincipalName, LastLogon
                # Create custom object for each user
                $userObject = [PSCustomObject]@{
                    DisplayName = $userDetails.DisplayName
                    UPN         = $userDetails.UserPrincipalName
                    LastLogon   = Get-LastLogon $userDetails.SamAccountName
                }
                # Add to results array
                $results += $userObject
            } else {
                Write-Host "SamAccountName is missing for a member in group: $groupName"
            }
        }
    } else {
        Write-Host "No members found in group: $groupName"
    }
} catch {
    Write-Host "Failed to retrieve members for group: $groupName. Please ensure the group name is correct and you have sufficient permissions."
}

# Define path for export with group name included
$exportPath = "$(Get-Location)\${groupName}_Group_Members_Last_Logon.csv"

# Export results to CSV
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Export completed. File is located at: $exportPath"
} else {
    Write-Host "No data to export. Please check the group name." -ForegroundColor Green
}
