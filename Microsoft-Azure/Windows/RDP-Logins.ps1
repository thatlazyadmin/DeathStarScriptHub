# PowerShell Script to Export Remote Desktop Logins over the Last 30 Days

# Define the timeframe (last 30 days)
$startDate = (Get-Date).AddDays(-30)

# Define the event log criteria
$logName = 'Security'
$eventID = 4624 # Event ID for successful logon
$logonType = 10 # Logon type 10 for Remote Desktop

# Collecting the relevant logon events
$logonEvents = Get-EventLog -LogName $logName -After $startDate -InstanceId $eventID | 
    Where-Object { $_.ReplacementStrings[8] -eq $logonType.ToString() }

# Initialize a list to hold login information
$loginInfo = @()

foreach ($event in $logonEvents) {
    try {
        # Extract username and IP address from the ReplacementStrings
        $username = $event.ReplacementStrings[5]
        $ipAddress = $event.ReplacementStrings[18]

        # Add the extracted information to the list
        $loginInfo += New-Object PSObject -Property @{
            Username = $username
            IPAddress = $ipAddress
            Time = $event.TimeGenerated
        }
    } catch {
        Write-Warning "An error occurred processing an event: $_"
    }
}

# Grouping and counting the unique logins
$uniqueLogins = $loginInfo | Group-Object Username, IPAddress | Measure-Object
$totalLogins = $uniqueLogins.Count

# Display total number of logins in green
Write-Host "Total Remote Desktop Logins in the Last 30 Days: $totalLogins" -ForegroundColor Green

# Display the login details
$loginInfo | Format-Table Username, IPAddress, Time -AutoSize

# Optionally, export this information to a CSV file
# $loginInfo | Export-Csv -Path "RemoteDesktopLogins.csv" -NoTypeInformation