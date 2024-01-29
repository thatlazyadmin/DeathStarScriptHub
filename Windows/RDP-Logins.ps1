# PowerShell Script to Export Remote Desktop Logins over the Last 30 Days

# Define the timeframe (last 30 days)
$startDate = (Get-Date).AddDays(-30)

# Define the event log criteria
$logName = 'Security'
$eventID = 4624 # Event ID for successful logon
$logonType = 10 # Logon type 10 for Remote Desktop

# Collecting the relevant logon events
$logonEvents = Get-WinEvent -LogName $logName | Where-Object {
    $_.Id -eq $eventID -and
    $_.TimeCreated -gt $startDate -and
    $_.Properties[8].Value -eq $logonType
}

# Extracting usernames and IP addresses
$loginInfo = $logonEvents | ForEach-Object {
    $eventXml = [xml] $_.ToXml()
    $username = $eventXml.Event.EventData.Data[5].'#text'
    $ipAddress = $eventXml.Event.EventData.Data[18].'#text'

    # Return an object with the necessary information
    New-Object PSObject -Property @{
        Username = $username
        IPAddress = $ipAddress
        Time = $_.TimeCreated
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
$loginInfo | Export-Csv -Path "RemoteDesktopLogins.csv" -NoTypeInformation
