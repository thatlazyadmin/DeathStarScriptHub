# =============================================================
#   _____                        _____               
#  (      \,___,   ___    ___   (      \,___, ,    . 
#   `--.  |    \ .'   ` .'   `   `--.  |    \ |    ` 
#      |  |    | |----' |           |  |    | |    | 
# \___.'  |`---' `.___,  `._.' \___.'  |`---'  `---|.
#         \                            \       \___/ 
#
#             SpecSpy - Quick Spec Overview
# =============================================================
# Created by: Shaun Hardneck
# Website: www.thatlazyadmin.com
# 
# This script provides a quick look at the server’s specs:
# CPU, Memory, Disks, Network Adapters, and more.
#
# Use SpecSpy for a colorful snapshot of your server's
# hardware details, all without opening Task Manager!
# =============================================================

function ShowMainMenu {
    Clear-Host
    Write-Host "================== SpecSpy - Server Health Check ==================" -ForegroundColor Cyan
    Write-Host "Please choose the mode you'd like to run:"
    Write-Host "1. Full Overview - Displays CPU, Memory, Disk, Network, Uptime, etc."
    Write-Host "2. Memory Snapshot - Quick memory snapshot for all processes."
    Write-Host "3. Memory Tracking - Track process memory changes over time."
    Write-Host "4. Exit"
    $global:mode = Read-Host "Enter the number for your choice (1, 2, 3, or 4):"
}

function RunFullOverview {
    Clear-Host
    Write-Host "Running Full Overview Mode..." -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan

    # CPU Information
    Write-Host "CPU Information:" -ForegroundColor Yellow
    $cpuInfo = Get-WmiObject -Class Win32_Processor
    foreach ($cpu in $cpuInfo) {
        Write-Host "CPU Name: $($cpu.Name)"
        Write-Host "Cores: $($cpu.NumberOfCores)"
        Write-Host "Logical Processors: $($cpu.NumberOfLogicalProcessors)"
        Write-Host "Max Clock Speed: $($cpu.MaxClockSpeed) MHz"
    }
    Write-Host "=================================================" -ForegroundColor Cyan

    # Memory Information
    Write-Host "Memory Information:" -ForegroundColor Yellow
    $memInfo = Get-WmiObject -Class Win32_PhysicalMemory
    $totalMemory = [math]::round(($memInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    Write-Host "Total Physical Memory: $totalMemory GB"
    Write-Host "=================================================" -ForegroundColor Cyan

    # Disk Information
    Write-Host "Disk Information:" -ForegroundColor Yellow
    $diskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($disk in $diskInfo) {
        $diskSize = [math]::round($disk.Size / 1GB, 2)
        $freeSpace = [math]::round($disk.FreeSpace / 1GB, 2)
        Write-Host "Drive $($disk.DeviceID): $diskSize GB (Free: $freeSpace GB)"
    }
    Write-Host "=================================================" -ForegroundColor Cyan

    # Network Adapter Information
    Write-Host "Network Adapter Information:" -ForegroundColor Yellow
    $nicInfo = Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetConnectionStatus=2"
    $nicCount = ($nicInfo | Measure-Object).Count
    Write-Host "Number of Active Network Adapters: $nicCount"
    foreach ($nic in $nicInfo) {
        Write-Host "Adapter Name: $($nic.Name)"
        Write-Host "MAC Address: $($nic.MACAddress)"
        Write-Host "Speed: $([math]::round($nic.Speed / 1MB, 2)) Mbps"
    }
    Write-Host "=================================================" -ForegroundColor Cyan

    # Server Uptime
    Write-Host "Server Uptime:" -ForegroundColor Yellow
    $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    Write-Host "Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
    Write-Host "=================================================" -ForegroundColor Cyan

    # Last Reboot Date
    Write-Host "Last Reboot Date:" -ForegroundColor Yellow
    $lastReboot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    Write-Host "Last Reboot: $($lastReboot)"
    Write-Host "=================================================" -ForegroundColor Cyan

    # Top Memory-Consuming Processes
    Write-Host "Top 5 Memory-Consuming Processes:" -ForegroundColor Yellow
    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "$($_.ProcessName): $([math]::round($_.WorkingSet / 1MB, 2)) MB"
    }
    Write-Host "=================================================" -ForegroundColor Cyan

    # Pending Windows Updates
    Write-Host "Pending Windows Updates:" -ForegroundColor Yellow
    $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
    if ($updates.Count -eq 0) {
        Write-Host "No pending updates." -ForegroundColor Green
    } else {
        $updates | ForEach-Object { Write-Host "$($_.Title)" }
    }
    Write-Host "=================================================" -ForegroundColor Cyan

    Write-Host "Specification Overview Complete!" -ForegroundColor Green
    Read-Host "Press Enter to return to the main menu"
    ShowMainMenu
}

function RunMemorySnapshot {
    Clear-Host
    Write-Host "Running Memory Snapshot Mode..." -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan

    # Capture Memory Snapshot for All Processes
    Get-Process | Sort-Object WorkingSet -Descending | ForEach-Object {
        Write-Host "$($_.ProcessName): $([math]::round($_.WorkingSet / 1MB, 2)) MB"
    }
    Write-Host "=================================================" -ForegroundColor Cyan

    Read-Host "Press Enter to return to the main menu"
    ShowMainMenu
}

function RunMemoryTracking {
    Clear-Host
    Write-Host "Running Memory Tracking Mode..." -ForegroundColor Green
    $interval = [int](Read-Host "Enter tracking interval in minutes (default 5):")
    $duration = [int](Read-Host "Enter tracking duration in minutes (default 60):")

    # Calculate the number of iterations based on interval and duration
    $iterations = [math]::floor($duration / $interval)
    $trackingLog = @()

    for ($i = 0; $i -lt $iterations; $i++) {
        $timestamp = Get-Date
        Get-Process | ForEach-Object {
            $trackingLog += [PSCustomObject]@{
                Timestamp = $timestamp
                ProcessName = $_.ProcessName
                MemoryUsageMB = [math]::round($_.WorkingSet / 1MB, 2)
            }
        }
        Start-Sleep -Seconds ($interval * 60)
    }

    # Export to CSV
    $trackingLog | Export-Csv -Path ".\MemoryTrackingLog.csv" -NoTypeInformation -Force
    Write-Host "Memory tracking complete. Log saved as MemoryTrackingLog.csv" -ForegroundColor Green

    Read-Host "Press Enter to return to the main menu"
    ShowMainMenu
}

# Main Script Execution
ShowMainMenu
while ($true) {
    switch ($mode) {
        "1" { RunFullOverview }
        "2" { RunMemorySnapshot }
        "3" { RunMemoryTracking }
        "4" { Write-Host "Exiting SpecSpy. Goodbye!" -ForegroundColor Green; break }
        default { Write-Host "Invalid choice. Please select 1, 2, 3, or 4." -ForegroundColor Red; ShowMainMenu }
    }
}
