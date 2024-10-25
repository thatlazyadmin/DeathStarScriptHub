#####################################################################
# Script Name: Update-UPN.ps1
# Synopsis: This script updates the User Principal Name (UPN) for a user in Microsoft Entra ID.
#           The script provides an option to select different environments like Commercial or GCC.
# Author: Shaun Hardneck
# Date: September 2024
#####################################################################

# Install the required module (if not already installed)
Install-Module Microsoft.Graph.Users -AllowClobber -Force

# Import the Microsoft Graph Users module
Import-Module Microsoft.Graph.Users

# Define a function to connect to Microsoft Graph based on the selected environment
function Connect-MgGraphEnvironment {
    $environment = @("Commercial", "GCC (USGov)")
    $choice = $environment | Out-GridView -Title "Select Microsoft Entra ID Environment" -PassThru

    if ($choice -eq "Commercial") {
        # Connect to the Global environment with the required scopes
        Connect-MgGraph -Environment Global -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
        Write-Host "Connected to Commercial Environment" -ForegroundColor Green
    } elseif ($choice -eq "GCC (USGov)") {
        # Connect to the USGov environment with the required scopes
        Connect-MgGraph -Environment USGov -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
        Write-Host "Connected to GCC (USGov) Environment" -ForegroundColor Green
    } else {
        Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
        Exit
    }
}

# Connect to the selected environment
Connect-MgGraphEnvironment

# Define the old and new UPNs
$oldUPN = Read-Host "Enter the current UPN"
$newUPN = Read-Host "Enter the desired new UPN"

# Update the UPN using the Microsoft Graph cmdlet
try {
    Update-MgUser -UserId $oldUPN -UserPrincipalName $newUPN
    Write-Host "Successfully updated UPN from $oldUPN to $newUPN." -ForegroundColor Green
} catch {
    Write-Host "Error updating UPN: $_" -ForegroundColor Red
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Yellow
#####################################################################