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
# CPU, Memory, Disks, and Network Adapters in one go.
#
# Use SpecSpy for a colorful snapshot of your server's
# hardware details, all without opening Task Manager!
# =============================================================

# Display Banner
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   _____                        _____               " -ForegroundColor Green
Write-Host "  (      \,___,   ___    ___   (      \,___, ,    . " -ForegroundColor Green
Write-Host "   `--.  |    \ .'   \` .'   \`   `--.  |    \ |    ` " -ForegroundColor Green
Write-Host "      |  |    | |----' |           |  |    | |    | " -ForegroundColor Green
Write-Host " \___.'  |`---' `.___,  `._.' \___.'  |`---'  `---| " -ForegroundColor Green
Write-Host "         \                            \       \___/ " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Created by: Shaun Hardneck" -ForegroundColor Yellow
Write-Host "Website: www.thatlazyadmin.com" -ForegroundColor Yellow
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

Write-Host "Specification Overview Complete!" -ForegroundColor Green
