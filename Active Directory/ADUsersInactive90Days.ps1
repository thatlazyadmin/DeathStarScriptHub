# Import Active Directory Module
Import-Module ActiveDirectory

# Calculate the date 90 days ago from today
$Date90DaysAgo = (Get-Date).AddDays(-90)

# Get AD users who haven't signed in the last 90 days
$Users = Get-ADUser -Filter {LastLogonDate -lt $Date90DaysAgo -or LastLogonDate -eq $null} -Properties DisplayName, LastLogonDate, DistinguishedName | Where-Object { $_.Enabled -eq $true }

# Select Username, DisplayName, Organizational Unit (OU), and LastLogonDate for each user
$UserList = $Users | Select-Object @{Name="Username";Expression={$_.SamAccountName}}, 
                                    @{Name="DisplayName";Expression={$_.DisplayName}},
                                    @{Name="OU";Expression={($_.DistinguishedName -split ",",2)[1]}},
                                    @{Name="LastSignedOn";Expression={if($_.LastLogonDate) { $_.LastLogonDate.ToString("g") } else { "Never" }}}

# Export the list to a CSV file
$UserList | Export-Csv -Path "ADUsersInactive90Days.csv" -NoTypeInformation

# Output completion message
Write-Output "Export completed. The list of users inactive for more than 90 days, including their last sign-on date, is saved to ADUsersInactive90Days.csv."