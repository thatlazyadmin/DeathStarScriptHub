# Load required modules
Import-Module ActiveDirectory

# Define the time limit (90 days in the past from today)
$TimeLimit = (Get-Date).AddDays(-90)

# Part 1: Identify Stale Computer and Server Accounts
$ComputersAndServers = Get-ADComputer -Filter {LastLogonDate -lt $TimeLimit} -Property Name, LastLogonDate, OperatingSystem, DistinguishedName | ForEach-Object {
    $isServer = $_.OperatingSystem -like "*Server*"
    $type = if ($isServer) {"Server"} else {"Computer"}
    [PSCustomObject]@{
        Name            = $_.Name
        LastLogonDate   = $_.LastLogonDate
        Type            = $type
        OU              = $_.DistinguishedName.split(',',2)[1]
    }
}

# Export to HTML with highlighted sections
$HtmlReportPart1 = $ComputersAndServers | ConvertTo-Html -Head "<style>th {background-color: #4CAF50;color: white;} .stale {background-color: #FF6347;}</style><h2>Created by URBANNERD CONSULTING</h2><h3>Active Directory Domain: $($env:USERDNSDOMAIN)</h3>" -PreContent "<h1>Stale Computer and Server Accounts</h1>" -PostContent "<p>Report generated on $(Get-Date)</p>" | ForEach-Object { $_ -replace "<tr>", "<tr class='stale'>" }

# Part 2: Audit Security Group Memberships
$CriticalGroups = @("Domain Admins", "Enterprise Admins") # Add more critical group names as needed
$GroupMemberships = foreach ($group in $CriticalGroups) {
    Get-ADGroupMember -Identity $group -Recursive | Get-ADObject -Properties * | Select-Object Name, ObjectClass, DistinguishedName
}

# Export to HTML
$HtmlReportPart2 = $GroupMemberships | ConvertTo-Html -Head "<style>th {background-color: #4CAF50;color: white;} .critical {background-color: #FFFF00;}</style><h2>Security Group Audit</h2><h3>Active Directory Domain: $($env:USERDNSDOMAIN)</h3>" -PreContent "<h1>Critical Security Group Memberships</h1>" -PostContent "<p>Report generated on $(Get-Date)</p>" | ForEach-Object { $_ -replace "<tr>", "<tr class='critical'>" }

# Part 3: Identifying Potential Stale DNS Records (Based on Stale AD Computer Accounts)
# Note: Actual DNS cleanup should be performed carefully and may require direct interaction with DNS servers
$PotentialStaleDNS = $ComputersAndServers | Where-Object { $_.Type -eq "Computer" } | Select-Object Name

# Export to HTML
$HtmlReportPart3 = $PotentialStaleDNS | ConvertTo-Html -Head "<style>th {background-color: #4CAF50;color: white;} .dns {background-color: #ADD8E6;}</style><h2>Potential Stale DNS Records</h2><h3>Active Directory Domain: $($env:USERDNSDOMAIN)</h3>" -PreContent "<h1>List of Computers with Potential Stale DNS Records</h1>" -PostContent "<p>Report generated on $(Get-Date)</p>" | ForEach-Object { $_ -replace "<tr>", "<tr class='dns'>" }

# Combine and Save the HTML reports
$FinalHtmlReport = $HtmlReportPart1 + $HtmlReportPart2 + $HtmlReportPart3
$FinalHtmlReport | Out-File "ADHousekeepingReport.html"
