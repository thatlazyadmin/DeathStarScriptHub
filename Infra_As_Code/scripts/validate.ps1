<#
.SYNOPSIS
    Validates all Bicep templates in a directory.

.DESCRIPTION
    This script validates all Bicep template files in the specified path.
    Created by: Shaun Hardneck
    Website: thatlazyadmin.com

.PARAMETER Path
    Path to the directory containing Bicep templates (default: current directory).

.PARAMETER Recursive
    Search for templates recursively in subdirectories.

.EXAMPLE
    ./validate.ps1 -Path "modules" -Recursive

.NOTES
    Author: Shaun Hardneck
    Website: thatlazyadmin.com
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [switch]$Recursive
)

$ErrorActionPreference = "Continue"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Bicep Template Validation Script" -ForegroundColor Cyan
Write-Host "Created by: Shaun Hardneck" -ForegroundColor Cyan
Write-Host "Website: thatlazyadmin.com" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Find all Bicep files
if ($Recursive) {
    $bicepFiles = Get-ChildItem -Path $Path -Filter "*.bicep" -Recurse
} else {
    $bicepFiles = Get-ChildItem -Path $Path -Filter "*.bicep"
}

if ($bicepFiles.Count -eq 0) {
    Write-Host "No Bicep files found in: $Path" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($bicepFiles.Count) Bicep file(s) to validate`n" -ForegroundColor Cyan

$totalFiles = $bicepFiles.Count
$validFiles = 0
$invalidFiles = 0
$validationErrors = @()

foreach ($file in $bicepFiles) {
    Write-Host "Validating: $($file.FullName)" -ForegroundColor Yellow
    
    try {
        $result = az bicep build --file $file.FullName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Valid" -ForegroundColor Green
            $validFiles++
        } else {
            Write-Host "  ✗ Invalid" -ForegroundColor Red
            $invalidFiles++
            $validationErrors += @{
                File = $file.FullName
                Error = $result
            }
        }
    } catch {
        Write-Host "  ✗ Validation failed: $_" -ForegroundColor Red
        $invalidFiles++
        $validationErrors += @{
            File = $file.FullName
            Error = $_.Exception.Message
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Total files:   $totalFiles" -ForegroundColor White
Write-Host "Valid files:   $validFiles" -ForegroundColor Green
Write-Host "Invalid files: $invalidFiles" -ForegroundColor Red
Write-Host ""

# Display errors if any
if ($invalidFiles -gt 0) {
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($validationError in $validationErrors) {
        Write-Host "`nFile: $($validationError.File)" -ForegroundColor Yellow
        Write-Host "$($validationError.Error)" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "✓ All Bicep templates are valid!" -ForegroundColor Green
    exit 0
}
