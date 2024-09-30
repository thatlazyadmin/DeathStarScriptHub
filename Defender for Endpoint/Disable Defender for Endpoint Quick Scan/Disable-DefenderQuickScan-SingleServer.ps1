# Synopsis: This script disables Microsoft Defender Quick Scan, Full Scan, and other related features on the current server.
# Created by: Shaun Hardneck
# Blog: www.thatlazyadmin.com
# GitHub: https://github.com/thatlazyadmin

# Clear the screen
Clear-Host

# Display script banner
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "        Disable Defender Scanning Features          " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Get the server name of the current machine
$ServerName = $env:COMPUTERNAME
Write-Host "Executing on server: $ServerName" -ForegroundColor Yellow

try {
    # Disable Defender Scan features on the local server
    Write-Host "Disabling Microsoft Defender scanning features on server $ServerName..." -ForegroundColor Yellow

    # Disable Quick Scans
    Set-MpPreference -DisableCatchupQuickScan $true
    Set-MpPreference -ScanScheduleQuickScanTime 0
    Set-MpPreference -ScanParameters 1  # 1 is for full scan, 2 is for quick scan
    Set-MpPreference -ScanScheduleDay 0  # 0 means no scheduled scan day
    Set-MpPreference -ScanScheduleTime 0  # Disable scheduled scan time

    # Disable Full Scan Catch-up
    Set-MpPreference -DisableCatchupFullScan $true

    # Disable scanning of mapped network drives during full scans
    Set-MpPreference -DisableScanningMappedNetworkDrivesForFullScan $true

    # Disable scanning of network files (Optional, modify based on need)
    Set-MpPreference -DisableScanningNetworkFiles $true

    # Optional: Disable scanning of archive files
    Set-MpPreference -DisableArchiveScanning $true

    # Verify the settings are applied
    $MpPrefs = Get-MpPreference
    if ($MpPrefs.DisableCatchupQuickScan -and $MpPrefs.DisableCatchupFullScan -and $MpPrefs.ScanScheduleQuickScanTime -eq 0) {
        Write-Host "Microsoft Defender scanning features are now disabled on $ServerName." -ForegroundColor Green
    } else {
        Write-Host "Failed to disable Microsoft Defender scanning features on $ServerName." -ForegroundColor Red
    }

} catch {
    Write-Host "Error occurred while disabling Defender scanning features on $ServerName. Error: $_" -ForegroundColor Red
}

# End script message
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "            Script Execution Completed              " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
