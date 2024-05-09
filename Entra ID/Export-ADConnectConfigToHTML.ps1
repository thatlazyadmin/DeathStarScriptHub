# Ensure the ADSync module is loaded
Import-Module ADSync

# Prepare to capture the configuration data
$connectors = Get-ADSyncConnector
$scheduler = Get-ADSyncScheduler

# Convert configuration data to JSON, then to an HTML table
$JsonData = @($connectors, $scheduler) | ConvertTo-Json
$JsonObj = ConvertFrom-Json -InputObject $JsonData

$HtmlContent = "<html><head><title>Azure AD Connect Configuration</title></head><body><h1>Azure AD Connect Configuration</h1>"
$HtmlContent += "<h2>Connectors</h2><table border='1'><tr><th>Name</th><th>Type</th><th>Enabled</th></tr>"

foreach ($connector in $JsonObj[0]) {
    $HtmlContent += "<tr><td>$($connector.Name)</td><td>$($connector.Type)</td><td>$($connector.Enabled)</td></tr>"
}

$HtmlContent += "</table><h2>Scheduler</h2><table border='1'><tr><th>PropertyName</th><th>Value</th></tr>"

foreach ($property in $JsonObj[1].PSObject.Properties) {
    $HtmlContent += "<tr><td>$($property.Name)</td><td>$($property.Value)</td></tr>"
}

$HtmlContent += "</table></body></html>"

# Specify the path for the HTML output
$HtmlPath = "C:\\Path\\To\\Save\\AADConnectConfig.html"
Set-Content -Path $HtmlPath -Value $HtmlContent

# Display the exported configuration
Write-Output "HTML configuration has been exported to: $HtmlPath"
