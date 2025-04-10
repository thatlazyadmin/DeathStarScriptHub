# ==================== CONFIGURATION =========================

$TenantId     = "f8a9f5a5-fbb5-4c50-9f67-84b1899a9f74"
$ClientId     = "7c17f89e-695b-4b7d-b08b-3d69d49cfbfb"
$ClientSecret = "qbR8Q~qo6AzWg~WhqH8mEzNq6myUW6rpSd00Zbx3" # Store securely!
$GroupId      = "5bdc8e0e-6180-406a-8231-d2380cfd3734" # Entra MFA Exclusion Group
$WebhookUrl   = "https://logicapp-mfa-groupcleanup-notify.azurewebsites.net:443/api/HTTP_Request/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=la7zXLoUVsrB_YP542E7W3KvvGo_ND-Hh9Z-SOZLHss"  # Optional
$Now          = Get-Date

# ==================== GET GRAPH TOKEN ========================

$TokenBody = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $ClientId
    client_secret = $ClientSecret
}

try {
    $TokenResponse = Invoke-RestMethod -Method POST `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Body $TokenBody `
        -ContentType "application/x-www-form-urlencoded"

    $AccessToken = $TokenResponse.access_token
    Write-Host "✅ Access token retrieved" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to retrieve access token: $_"
    return
}

# ==================== SET GRAPH HEADER =======================

$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type"  = "application/json"
}

# ==================== GET GROUP INFO =========================

try {
    $Group = Invoke-RestMethod -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId" `
        -Headers $Headers

    $GroupDisplayName = $Group.displayName
    Write-Host "✅ Group found: $GroupDisplayName" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to access group: $_"
    return
}

# ==================== GET GROUP MEMBERS ======================

try {
    $GroupMembers = Invoke-RestMethod -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId/members?$top=999" `
        -Headers $Headers

    $Members = $GroupMembers.value
    Write-Host "👥 Members found: $($Members.Count)" -ForegroundColor Cyan
} catch {
    Write-Error "❌ Failed to retrieve group members: $_"
    return
}

# ==================== GET AUDIT LOGS =========================

try {
    $AuditUri = "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits" +
        "?`$filter=activityDisplayName eq 'Add member to group' and targetResources/any(tr: tr/id eq '$GroupId')&`$top=1000"

    $AuditLogs = Invoke-RestMethod -Method GET -Uri $AuditUri -Headers $Headers
    $AddEvents = $AuditLogs.value
    Write-Host "📄 Audit logs retrieved: $($AddEvents.Count)" -ForegroundColor Yellow
} catch {
    Write-Error "❌ Failed to get audit logs: $_"
    return
}

# ==================== CLEANUP LOGIC ==========================

$RemovedUsers     = @()
$RecentAdditions  = @()

foreach ($User in $Members) {
    $UserId      = $User.id
    $DisplayName = $User.displayName

    $AddedEvent = $AddEvents | Where-Object {
        $_.targetResources[1].id -eq $UserId
    } | Sort-Object activityDateTime -Descending | Select-Object -First 1

    if ($AddedEvent) {
        $HoursInGroup = ($Now - [datetime]$AddedEvent.activityDateTime).TotalHours
        if ($HoursInGroup -ge 24) {
            try {
                $RemoveUri = "https://graph.microsoft.com/v1.0/groups/$GroupId/members/$UserId/`$ref"
                Invoke-RestMethod -Method DELETE -Uri $RemoveUri -Headers $Headers
                $RemovedUsers += "$(${DisplayName}) - $([math]::Round($HoursInGroup, 1)) hrs"
                Write-Host "🗑️ Removed: $(${DisplayName}) - $([math]::Round($HoursInGroup,1)) hrs" -ForegroundColor Red
            } catch {
                Write-Warning "⚠️ Failed to remove $(${DisplayName}): $_"
            }
        } else {
            $RecentAdditions += "$(${DisplayName}) - $([math]::Round($HoursInGroup,1)) hrs ago"
        }
    } else {
        Write-Warning "⚠️ No audit log found for $(${DisplayName})"
    }
}

# ==================== LOGIC APP NOTIFICATION =================

if ($WebhookUrl -and $WebhookUrl -ne "<your-logic-app-webhook-url>") {
    $Subject = "MFA Exclusion Cleanup - $GroupDisplayName"
    $HtmlBody = @"
<h2>Group: $GroupDisplayName</h2>
<p><strong>🗑️ Removed Users (Over 24h):</strong></p>
<ul>
$(if ($RemovedUsers.Count -gt 0) { $RemovedUsers | ForEach-Object { "<li>$_</li>" } } else { "<li>None</li>" })
</ul>
<p><strong>🆕 Recently Added (Last 24h):</strong></p>
<ul>
$(if ($RecentAdditions.Count -gt 0) { $RecentAdditions | ForEach-Object { "<li>$_</li>" } } else { "<li>None</li>" })
</ul>
<p><em>Run Time: $($Now.ToString("yyyy-MM-dd HH:mm"))</em></p>
"@

    $Payload = @{
        subject = $Subject
        body    = $HtmlBody
    } | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod -Method POST -Uri $WebhookUrl -Body $Payload -ContentType "application/json"
        Write-Host "✅ Notification sent to Logic App" -ForegroundColor Green
    } catch {
        Write-Warning "❌ Failed to send notification to Logic App: $_"
    }
}