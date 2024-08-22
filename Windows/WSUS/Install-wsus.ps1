<#
.SYNOPSIS
    Installs Windows Server Update Services (WSUS) on a server with the installation path set to the D: drive.

.DESCRIPTION
    This script installs WSUS with its content directory on the D: drive. It configures the necessary features and roles
    for WSUS to function properly.

.NOTES
    Created by: [Your Name]
    Blog: www.thatlazyadmin.com
#>

# Suppress warning messages
$ErrorActionPreference = "SilentlyContinue"

# Install required roles and features for WSUS
Write-Host "Installing WSUS and required features..." -ForegroundColor Yellow
Install-WindowsFeature -Name UpdateServices, UpdateServices-UI, UpdateServices-WidDB, UpdateServices-Services -IncludeManagementTools -Verbose

# Configure WSUS with content directory on D: drive
$wsusContentPath = "D:\WSUS"

if (-Not (Test-Path -Path $wsusContentPath)) {
    Write-Host "Creating WSUS content directory at $wsusContentPath..." -ForegroundColor Yellow
    New-Item -Path $wsusContentPath -ItemType Directory -Force
}

Write-Host "Configuring WSUS with content directory on D: drive..." -ForegroundColor Yellow
Invoke-Expression "C:\Program Files\Update Services\Tools\WsusUtil.exe postinstall CONTENT_DIR=$wsusContentPath"

# Check if the installation was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "WSUS installation and configuration complete. Content directory is set to $wsusContentPath" -ForegroundColor Green
} else {
    Write-Host "WSUS installation failed. Please check the logs for more details." -ForegroundColor Red
}

# Summary of installation
Write-Host "WSUS has been successfully installed on the D: drive." -ForegroundColor Green
