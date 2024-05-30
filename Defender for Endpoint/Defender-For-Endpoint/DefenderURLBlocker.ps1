#Created By: Shaun Hardneck (ThatLazyAdmin)
#Blog: www.thatlazyadmin.com
#Github: https://github.com/thatlazyadmin/DeathStarScriptHub/tree/main
#Replace 'YOU_API_TOKEN'

# Display a banner
Write-Host "Block Unwanted Websites in Your Organization" -ForegroundColor Cyan

function Add-BlockedUrl {
    param(
        [string]$Url
    )
    # Example for API endpoint, adjust according to your actual API URL
    $apiUrl = "https://api.securitycenter.windows.com/.default"

    $body = @{
        action = "AlertAndBlock"
        indicatorValue = $Url
        indicatorType = "Url"
        title = "Blocked URL: $Url"
        description = "This URL was blocked via PowerShell script"
        severity = "High"
    }

    $json = $body | ConvertTo-Json

    $headers = @{
        "Authorization" = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlhSdmtvOFA3QTNVYVdTblU3Yk05blQwTWpoQSIsImtpZCI6IlhSdmtvOFA3QTNVYVdTblU3Yk05blQwTWpoQSJ9.eyJhdWQiOiJodHRwczovL2FwaS5zZWN1cml0eWNlbnRlci53aW5kb3dzLmNvbSIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2Y4YTlmNWE1LWZiYjUtNGM1MC05ZjY3LTg0YjE4OTlhOWY3NC8iLCJpYXQiOjE3MTE0NjM5MzYsIm5iZiI6MTcxMTQ2MzkzNiwiZXhwIjoxNzExNDY3ODM2LCJhaW8iOiJFMk5nWU9CMDBQSDhVTFpCUkozcDI3ODluR1VuQUE9PSIsImFwcF9kaXNwbGF5bmFtZSI6IkJsb2NrX1VybHMiLCJhcHBpZCI6IjMxOWYzYzM0LTA5MWUtNDZiNy1iZGZlLTkzMDI0NWUyMTdjOCIsImFwcGlkYWNyIjoiMSIsImlkcCI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2Y4YTlmNWE1LWZiYjUtNGM1MC05ZjY3LTg0YjE4OTlhOWY3NC8iLCJvaWQiOiJlNjc4NDlkOC1jYWU0LTQ2YWYtODE3My1kOThmYWY0YmVjNGMiLCJyaCI6IjAuQVJBQXBmV3AtTFg3VUV5Zlo0U3hpWnFmZEdVRWVQd1hJTlJBb01Vd2NDSkhHNUtYQUFBLiIsInN1YiI6ImU2Nzg0OWQ4LWNhZTQtNDZhZi04MTczLWQ5OGZhZjRiZWM0YyIsInRlbmFudF9yZWdpb25fc2NvcGUiOiJBRiIsInRpZCI6ImY4YTlmNWE1LWZiYjUtNGM1MC05ZjY3LTg0YjE4OTlhOWY3NCIsInV0aSI6IjJXbGpMVDEyMFU2YXhxM01BbHAzQUEiLCJ2ZXIiOiIxLjAifQ.o5J-CZQcfTk9b3KrPkupm-86b9kcmOU9hAJXC-6l9oygzQ2qdEXga9Y5-nKE2y5wAjPq2AYYbw2cv7bvg647W0gqxVAzz-W0lqxUFA2MOAw4-Qob1wFW8Hgrxp1aZdV1aBZjEvRxNjEuYAXBLVX2HTRwbxkKHce1a0zfQ6-w8g7gLS1PWu81cNV168XlvV6xVqpc5UNT7OryXEe8eX5x-k2c0gKiz4bjpnlG_5KXjMg7s1sMsLsDyrikDVted0nKDAQc1sZmM83csu4DU_hmQ0QZTrltFiIhrURH94qSCagwfXRy1Crw_nouHug0lmNpnlHsV-09WhpmxFR0wLjaSQ"
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $json
        Write-Host "Successfully added website to blocked list: $Url" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to add website to blocked list: $_" -ForegroundColor Red
    }
}

function Show-BlockedUrls {
    # Example for API endpoint, adjust according to your actual API URL for retrieving the list of indicators
    $apiUrl = "https://api.securitycenter.windows.com/.default"

    $headers = @{
        "Authorization" = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlhSdmtvOFA3QTNVYVdTblU3Yk05blQwTWpoQSIsImtpZCI6IlhSdmtvOFA3QTNVYVdTblU3Yk05blQwTWpoQSJ9.eyJhdWQiOiJodHRwczovL2FwaS5zZWN1cml0eWNlbnRlci53aW5kb3dzLmNvbSIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2Y4YTlmNWE1LWZiYjUtNGM1MC05ZjY3LTg0YjE4OTlhOWY3NC8iLCJpYXQiOjE3MTE0NjM5MzYsIm5iZiI6MTcxMTQ2MzkzNiwiZXhwIjoxNzExNDY3ODM2LCJhaW8iOiJFMk5nWU9CMDBQSDhVTFpCUkozcDI3ODluR1VuQUE9PSIsImFwcF9kaXNwbGF5bmFtZSI6IkJsb2NrX1VybHMiLCJhcHBpZCI6IjMxOWYzYzM0LTA5MWUtNDZiNy1iZGZlLTkzMDI0NWUyMTdjOCIsImFwcGlkYWNyIjoiMSIsImlkcCI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2Y4YTlmNWE1LWZiYjUtNGM1MC05ZjY3LTg0YjE4OTlhOWY3NC8iLCJvaWQiOiJlNjc4NDlkOC1jYWU0LTQ2YWYtODE3My1kOThmYWY0YmVjNGMiLCJyaCI6IjAuQVJBQXBmV3AtTFg3VUV5Zlo0U3hpWnFmZEdVRWVQd1hJTlJBb01Vd2NDSkhHNUtYQUFBLiIsInN1YiI6ImU2Nzg0OWQ4LWNhZTQtNDZhZi04MTczLWQ5OGZhZjRiZWM0YyIsInRlbmFudF9yZWdpb25fc2NvcGUiOiJBRiIsInRpZCI6ImY4YTlmNWE1LWZiYjUtNGM1MC05ZjY3LTg0YjE4OTlhOWY3NCIsInV0aSI6IjJXbGpMVDEyMFU2YXhxM01BbHAzQUEiLCJ2ZXIiOiIxLjAifQ.o5J-CZQcfTk9b3KrPkupm-86b9kcmOU9hAJXC-6l9oygzQ2qdEXga9Y5-nKE2y5wAjPq2AYYbw2cv7bvg647W0gqxVAzz-W0lqxUFA2MOAw4-Qob1wFW8Hgrxp1aZdV1aBZjEvRxNjEuYAXBLVX2HTRwbxkKHce1a0zfQ6-w8g7gLS1PWu81cNV168XlvV6xVqpc5UNT7OryXEe8eX5x-k2c0gKiz4bjpnlG_5KXjMg7s1sMsLsDyrikDVted0nKDAQc1sZmM83csu4DU_hmQ0QZTrltFiIhrURH94qSCagwfXRy1Crw_nouHug0lmNpnlHsV-09WhpmxFR0wLjaSQ"
    }

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers
        $response | ForEach-Object {
            Write-Host "Blocked URL: $($_.indicatorValue)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to retrieve blocked URLs: $_" -ForegroundColor Red
    }
}

while ($true) {
    Write-Host "1. Add Block URL"
    Write-Host "2. Show All Blocked URLs"
    Write-Host "3. Exit"
    $choice = Read-Host "Please select an option"

    switch ($choice) {
        "1" {
            $url = Read-Host "Enter the website to block (format: domain.com, example: example.com)"
            Add-BlockedUrl -Url $url
        }
        "2" {
            Show-BlockedUrls
        }
        "3" {
            Write-Host "Exiting script..."
            break
        }
        default {
            Write-Host "Invalid option, please try again." -ForegroundColor Red
        }
    }
}
