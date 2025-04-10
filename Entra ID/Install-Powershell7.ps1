# Step 1: Check for Administrator Privileges
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an Administrator." -ForegroundColor Red
    Break
}

# Step 2: Set Execution Policy (if needed)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Step 3: Download PowerShell 7 Installer
Write-Host "Downloading PowerShell 7 Installer..." -ForegroundColor Cyan
$installerPath = "$env:TEMP\PowerShell-7.3.7-win-x64.msi"
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.3.7/PowerShell-7.3.7-win-x64.msi" -OutFile $installerPath -UseBasicParsing

# Step 4: Install PowerShell 7
Write-Host "Installing PowerShell 7..." -ForegroundColor Green
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $installerPath /quiet /norestart" -Wait

# Step 5: Verify Installation
Write-Host "Verifying PowerShell 7 Installation..." -ForegroundColor Yellow
$powershell7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
If (Test-Path $powershell7Path) {
    Write-Host "PowerShell 7 installed successfully! Path: $powershell7Path" -ForegroundColor Green
} Else {
    Write-Host "PowerShell 7 installation failed." -ForegroundColor Red
}

# Step 6: Launch PowerShell 7
Write-Host "Launching PowerShell 7..." -ForegroundColor Cyan
Start-Process $powershell7Path
