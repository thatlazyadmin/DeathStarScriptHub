# Synopsis: This script disables the Microsoft Defender Quick Scan feature on a single server.
# Created by: Shaun Hardneck
# Blog: www.urbannerd-consulting.com
# GitHub: 

# Clear the screen
Clear-Host

# Display script banner
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "        Disable Defender Quick Scan Feature          " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Prompt for the server name
$ServerName = Read-Host -Prompt "Enter the server name where you want to disable Defender Quick Scan"

# Check if the server is reachable
if (Test-Connection -ComputerName $ServerName -Count 2 -Quiet) {
    Write-Host "`nServer $ServerName is reachable." -ForegroundColor Green

    try {
        # Invoke command to disable Defender Quick Scan feature on the remote server
        Invoke-Command -ComputerName $ServerName -ScriptBlock {
            Write-Host "Disabling Microsoft Defender Quick Scan on server $env:COMPUTERNAME..." -ForegroundColor Yellow

            # Disable Quick Scan using Set-MpPreference
            Set-MpPreference -DisableScanningMappedNetworkDrivesForFullScan $true

            # Verify the setting is applied
            $MpPrefs = Get-MpPreference
            if ($MpPrefs.DisableScanningMappedNetworkDrivesForFullScan) {
                Write-Host "Microsoft Defender Quick Scan feature is now disabled on $env:COMPUTERNAME." -ForegroundColor Green
            } else {
                Write-Host "Failed to disable Microsoft Defender Quick Scan feature on $env:COMPUTERNAME." -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "Error occurred while disabling Defender Quick Scan on $ServerName. Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "`nServer $ServerName is not reachable. Please check the network connection or server status." -ForegroundColor Red
}

# End script message
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "            Script Execution Completed              " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
