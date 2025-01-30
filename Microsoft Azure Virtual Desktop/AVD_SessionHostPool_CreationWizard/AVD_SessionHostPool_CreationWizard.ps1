<#
.SYNOPSIS
    This script creates a new Azure Virtual Desktop (AVD) Session Host Pool with customizable options.
.DESCRIPTION
    The script prompts the user for input regarding Host Pool Type, App Group Type, Start VM on Connect, Validation Environment, Max Session Limit, and more.
    It clears the console when executed and includes explanations for the choices made by the user.
    Created by: Shaun Hardneck
#>

# Clear the PowerShell window
Clear-Host

# Add some color to the script
Write-Host -ForegroundColor Cyan "Azure Virtual Desktop - New Session Host Pool Creation"
Write-Host ""

# Brief Explanation of Host Pool Types
Write-Host -ForegroundColor Green "Host Pool Types:"
Write-Host "1. Pooled: Multiple users share a set of session hosts, reducing resource cost."
Write-Host "2. Personal: Each user gets their own dedicated session host for more predictable performance."
Write-Host ""
$hostPoolType = Read-Host "Please select the Host Pool Type (1 for Pooled, 2 for Personal)"

# Validate Host Pool Type
if ($hostPoolType -eq 1) {
    $hostPoolType = "Pooled"
    Write-Host -ForegroundColor Yellow "You have selected 'Pooled'."
} elseif ($hostPoolType -eq 2) {
    $hostPoolType = "Personal"
    Write-Host -ForegroundColor Yellow "You have selected 'Personal'."
} else {
    Write-Host -ForegroundColor Red "Invalid selection. Exiting script."
    exit
}

Write-Host ""

# Brief Explanation of Load Balancing Algorithms
Write-Host -ForegroundColor Green "Load Balancing Algorithms:"
Write-Host "1. Breadth-first: Distribute user sessions evenly across session hosts."
Write-Host "2. Depth-first: Fill one session host to its limit before assigning users to the next."
Write-Host ""
$loadBalancingAlgorithm = Read-Host "Please select the Load Balancing Algorithm (1 for Breadth-first, 2 for Depth-first)"

# Validate Load Balancing Algorithm
if ($loadBalancingAlgorithm -eq 1) {
    $loadBalancingAlgorithm = "Breadth-first"
    Write-Host -ForegroundColor Yellow "You have selected 'Breadth-first'."
} elseif ($loadBalancingAlgorithm -eq 2) {
    $loadBalancingAlgorithm = "Depth-first"
    Write-Host -ForegroundColor Yellow "You have selected 'Depth-first'."
} else {
    Write-Host -ForegroundColor Red "Invalid selection. Exiting script."
    exit
}

Write-Host ""

# Brief Explanation of Max Session Limit
Write-Host -ForegroundColor Green "Max Session Limit:"
Write-Host "This defines how many users can log in to a single session host at a time."
$maxSessionLimit = Read-Host "Please enter the Max Session Limit (e.g., 10)"

Write-Host ""

# Prompt for Host Pool Name
$hostPoolName = Read-Host "Enter the Host Pool Name"
$friendlyName = $hostPoolName  # Friendly Name based on the Host Pool Name

# Preferred App Group Type
Write-Host -ForegroundColor Green "App Group Type:"
Write-Host "1. Desktop: Provides users with a full desktop experience."
Write-Host "2. RemoteApp: Publishes specific apps instead of a full desktop."
Write-Host ""
$appGroupType = Read-Host "Please select the App Group Type (1 for Desktop, 2 for RemoteApp)"

# Validate App Group Type
if ($appGroupType -eq 1) {
    $appGroupType = "Desktop"
    Write-Host -ForegroundColor Yellow "You have selected 'Desktop' App Group."
} elseif ($appGroupType -eq 2) {
    $appGroupType = "RemoteApp"
    Write-Host -ForegroundColor Yellow "You have selected 'RemoteApp' App Group."
} else {
    Write-Host -ForegroundColor Red "Invalid selection. Exiting script."
    exit
}

Write-Host ""

# Start VM on Connect Option
$startVMOnConnect = Read-Host "Do you want to enable 'Start VM on Connect'? (Yes/No)"
if ($startVMOnConnect -eq "Yes") {
    Write-Host -ForegroundColor Yellow "'Start VM on Connect' enabled."
} else {
    Write-Host -ForegroundColor Yellow "'Start VM on Connect' disabled."
}

Write-Host ""

# Validation Environment
$validationEnvironment = Read-Host "Is this a validation environment? (Yes/No)"
if ($validationEnvironment -eq "Yes") {
    Write-Host -ForegroundColor Yellow "This is a validation environment."
} else {
    Write-Host -ForegroundColor Yellow "This is not a validation environment."
}

Write-Host ""

# Simulate Host Pool Creation
Write-Host -ForegroundColor Cyan "Creating the session host pool..."
# Command to create the session host pool (replace with actual logic)
# New-AzWvdHostPool -Name $hostPoolName -HostPoolType $hostPoolType -LoadBalancingAlgorithm $loadBalancingAlgorithm -MaxSessionLimit $maxSessionLimit -Location 'your-location' -FriendlyName $friendlyName -StartVMOnConnect $startVMOnConnect -ValidationEnvironment $validationEnvironment -AppGroupType $appGroupType

# Simulating successful creation
Write-Host -ForegroundColor Green "Host Pool '$hostPoolName' has been successfully created with the following details:"
Write-Host "Host Pool Type: $hostPoolType"
Write-Host "Load Balancing Algorithm: $loadBalancingAlgorithm"
Write-Host "Max Session Limit: $maxSessionLimit"
Write-Host "App Group Type: $appGroupType"
Write-Host "Friendly Name: $friendlyName"
Write-Host "Start VM on Connect: $startVMOnConnect"
Write-Host "Validation Environment: $validationEnvironment"
