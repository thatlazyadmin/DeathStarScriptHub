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
    $apiUrl = "https://api.securitycenter.windows.com/api/indicators"

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
        "Authorization" = "Bearer YOUR_API_TOKEN"
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
    $apiUrl = "https://api.securitycenter.windows.com/api/indicators"

    $headers = @{
        "Authorization" = "Bearer YOUR_API_TOKEN"
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
