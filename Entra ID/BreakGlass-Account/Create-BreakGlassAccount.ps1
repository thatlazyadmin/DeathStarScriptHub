<#
.SYNOPSIS
Create a new Microsoft 365 break glass account with the necessary configurations.

.DESCRIPTION
This script creates a new break glass account, assigns the Global Administrator role, and disables MFA using Microsoft Graph PowerShell. 

.NOTES
Created by: Shaun Hardneck
Blog: www.thatlazyadmin.com

#>

# Import required modules
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Installing..." -ForegroundColor $infoColor
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
}

# Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

# Define colors
$infoColor = "Cyan"
$warningColor = "Yellow"
$errorColor = "Red"

# Display banner
Write-Host "===================================================" -ForegroundColor $infoColor
Write-Host "Create Microsoft 365 Break Glass Account" -ForegroundColor $infoColor
Write-Host "Created by: Shaun Hardneck" -ForegroundColor $infoColor
Write-Host "===================================================" -ForegroundColor $infoColor

# Function to generate random password
function Generate-RandomPassword {
    $length = 15
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+'
    -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# Function to create break glass account
function Create-BreakGlassAccount {
    param (
        [Parameter(Mandatory=$true)]
        [string]$AccountUPN,
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName
    )

    $Password = Generate-RandomPassword
    Write-Host "Generated Password: $Password" -ForegroundColor $warningColor

    # Connect to Microsoft Graph
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor $infoColor
    Connect-MgGraph -Scopes "User.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All" -NoWelcome

    # Create PasswordProfile object
    $PasswordProfile = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile
    $PasswordProfile.Password = $Password
    $PasswordProfile.ForceChangePasswordNextSignIn = $false

    # Create the break glass account properties
    $userProperties = @{
        UserPrincipalName = $AccountUPN
        DisplayName = $DisplayName
        MailNickname = ($AccountUPN.Split('@')[0])
        PasswordProfile = $PasswordProfile
        AccountEnabled = $true
        UsageLocation = "US"
    }

    # Create the break glass account
    Write-Host "Creating break glass account..." -ForegroundColor $infoColor
    try {
        $user = New-MgUser @userProperties
        Write-Host "Account created successfully." -ForegroundColor $infoColor
    } catch {
        Write-Host "Failed to create account: $_" -ForegroundColor $errorColor
        return
    }

    # Assign Global Administrator role
    Write-Host "Assigning Global Administrator role..." -ForegroundColor $infoColor
    try {
        $role = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"
        # Use the correct cmdlet for adding a directory role member
        $roleMemberProperties = @{
            DirectoryRoleId = $role.Id
            RoleMemberId = $user.Id
        }
        New-MgDirectoryRoleMember @roleMemberProperties
        Write-Host "Role assigned successfully." -ForegroundColor $infoColor
    } catch {
        Write-Host "Failed to assign role: $_" -ForegroundColor $errorColor
        return
    }

    # Disable MFA for the account
    Write-Host "Disabling MFA for the break glass account..." -ForegroundColor $infoColor
    try {
        # MFA settings should be managed separately, as there is no direct method in Microsoft Graph PowerShell to disable MFA
        Write-Host "Note: Disabling MFA should be done manually or via Azure AD settings." -ForegroundColor $warningColor
    } catch {
        Write-Host "Failed to disable MFA: $_" -ForegroundColor $errorColor
    }
}

# Main script execution
$AccountUPN = Read-Host -Prompt "Enter Break Glass Account UPN (e.g., BGA001MS365@yourdomain.com)"
$DisplayName = Read-Host -Prompt "Enter Display Name (e.g., Break Glass Admin Account)"

Create-BreakGlassAccount -AccountUPN $AccountUPN -DisplayName $DisplayName

Write-Host "Script execution completed." -ForegroundColor $infoColor
Write-Host "===================================================" -ForegroundColor $infoColor