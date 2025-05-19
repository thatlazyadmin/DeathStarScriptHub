#region BANNER
Clear-Host
$banner = @"
╔════════════════════════════════════════════════════════════╗
║        ENTRA USERS WITHOUT MFA/AUTH METHODS REPORT         ║
║          Scripted by Shaun Hardneck - ThatLazyAdmin        ║
╚════════════════════════════════════════════════════════════╝
"@
Write-Host $banner -ForegroundColor Cyan
#endregion

#region Connect to Microsoft Graph Beta
Write-Host "Connecting to Microsoft Graph Beta..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All", "Reports.Read.All" -Environment Global -NoWelcome
Select-MgProfile -Name "beta"
#endregion

#region Initialize
$results = @()
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$errorLog = ".\ErrorLog_$timestamp.txt"
#endregion

#region Get all users’ MFA/Auth registration details
Write-Host "Fetching authentication registration details..." -ForegroundColor Yellow
try {
    $authUsers = Get-MgBetaReportAuthenticationMethodUserRegistrationDetail -All -ErrorAction Stop
} catch {
    Write-Error "❌ Failed to retrieve authentication method registration details."
    $_ | Out-File $errorLog -Append
    return
}
#endregion

#region Loop through each user with no registered auth methods
Write-Host "Scanning users without authentication methods..." -ForegroundColor Yellow

foreach ($user in $authUsers) {
    try {
        if (-not $user.IsMfaRegistered -and ($user.UserPrincipalName -ne $null)) {

            # Get latest sign-in info
            try {
                $signin = Get-MgAuditLogSignIn -Filter "userId eq '$($user.Id)'" -Top 1 | Sort-Object CreatedDateTime -Descending
                $lastSignIn = $signin[0].CreatedDateTime
            } catch {
                $lastSignIn = "No sign-in info"
                $_ | Out-File $errorLog -Append
            }

            $results += [PSCustomObject]@{
                DisplayName        = $user.DisplayName
                UserPrincipalName  = $user.UserPrincipalName
                AuthMethods        = "None"
                MFARegistered      = "No"
                LastSignIn         = $lastSignIn
            }
        }
    } catch {
        Write-Warning "⚠️ Failed processing user: $($user.UserPrincipalName)"
        $_ | Out-File $errorLog -Append
    }
}
#endregion

#region Export
if ($results.Count -gt 0) {
    $csvPath = ".\Users_Without_AuthMethods_$timestamp.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "`n✅ Report generated: $csvPath" -ForegroundColor Green
} else {
    Write-Host "`n✅ No users without auth methods found!" -ForegroundColor Green
}
#endregion