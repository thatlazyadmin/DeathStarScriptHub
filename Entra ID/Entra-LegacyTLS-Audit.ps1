$tId = "1ef7750f-783b-430a-bcc2-75a799247c48"  # Add tenant ID from Azure Active Directory page on portal.
$agoDays = 7  # Will filter the log for $agoDays from the current date and time.
$startDate = (Get-Date).AddDays(-($agoDays)).ToString('yyyy-MM-dd')  # Get filter start date.
$pathForExport = "./"  # The path to the local filesystem for export of the CSV file.

Connect-MgGraph -Scopes "AuditLog.Read.All" -TenantId $tId  # Or use Directory.Read.All.
Select-MgProfile "beta"  # Low TLS is available in Microsoft Graph preview endpoint.

# Define the filtering strings for interactive and non-interactive sign-ins.
$procDetailFunction = "x: x/key eq 'legacy tls (tls 1.0, 1.1, 3des)' and x/value eq '1'"
$clauses = (
    "createdDateTime ge $startDate",
    "signInEventTypes/any(t: t eq 'nonInteractiveUser')",
    "signInEventTypes/any(t: t eq 'servicePrincipal')",
    "(authenticationProcessingDetails/any($procDetailFunction))"
)

# Get the interactive and non-interactive sign-ins based on filtering clauses.
$signInsInteractive = Get-MgAuditLogSignIn -Filter ($clauses[0,3] -Join " and ") -All
$signInsNonInteractive = Get-MgAuditLogSignIn -Filter ($clauses[0,1,3] -Join " and ") -All
$signInsWorkloadIdentities = Get-MgAuditLogSignIn -Filter ($clauses[0,2,3] -Join " and ") -All

$columnList = @{  # Enumerate the list of properties to be exported to the CSV files.
    Property = "CorrelationId", "createdDateTime", "userPrincipalName", "userId",
              "UserDisplayName", "AppDisplayName", "AppId", "IPAddress", "isInteractive",
              "ResourceDisplayName", "ResourceId", "UserAgent"
}

$columnListWorkloadId = @{ #Enumerate the list of properties for workload identities to be exported to the CSV files.
    Property = "CorrelationId", "createdDateTime", "AppDisplayName", "AppId", "IPAddress",
              "ResourceDisplayName", "ResourceId", "ServicePrincipalId", "ServicePrincipalName"
}

$signInsInteractive | ForEach-Object {
    foreach ($authDetail in $_.AuthenticationProcessingDetails)
    {
        if (($authDetail.Key -match "Legacy TLS") -and ($authDetail.Value -eq "True"))
        {
            $_ | Select-Object @columnList
        }
    }
} | Export-Csv -Path ($pathForExport + "Interactive_lowTls_$tId.csv") -NoTypeInformation

$signInsNonInteractive | ForEach-Object {
    foreach ($authDetail in $_.AuthenticationProcessingDetails)
    {
        if (($authDetail.Key -match "Legacy TLS") -and ($authDetail.Value -eq "True"))
        {
            $_ | Select-Object @columnList
        }
    }
} | Export-Csv -Path ($pathForExport + "NonInteractive_lowTls_$tId.csv") -NoTypeInformation

$signInsWorkloadIdentities | ForEach-Object {
    foreach ($authDetail in $_.AuthenticationProcessingDetails)
    {
        if (($authDetail.Key -match "Legacy TLS") -and ($authDetail.Value -eq "True"))
        {
            $_ | Select-Object @columnListWorkloadId
        }
    }
} | Export-Csv -Path ($pathForExport + "WorkloadIdentities_lowTls_$tId.csv") -NoTypeInformation