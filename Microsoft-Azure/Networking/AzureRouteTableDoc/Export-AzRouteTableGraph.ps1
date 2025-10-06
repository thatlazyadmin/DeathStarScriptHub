# Suppress Warnings & Errors for Clean Execution
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:SuppressAzurePowerShellBreakingChangeWarnings = "true"

# Clear PowerShell Window and Display Banner
Clear-Host
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host "#       Azure Route Table Documentation      #" -ForegroundColor Cyan
Write-Host "#      Script by Shaun Hardneck | v3.0       #" -ForegroundColor Cyan
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host ""

# Output File Names
$OutputCSV = "AzureRouteTables.csv"
$OutputJSON = "AzureRouteTables.json"
$OutputHTML = "AzureRouteTables.html"

# Get All Subscriptions and Filter by Prefix
$subscriptionPrefix = Read-Host "Enter Subscription Prefix (or press Enter for all)"
Write-Host "`nRetrieving Subscriptions..." -ForegroundColor Cyan
$subscriptions = Get-AzSubscription | Where-Object { $_.Name -like "$subscriptionPrefix*" }

if (-not $subscriptions) {
    Write-Host "No matching subscriptions found." -ForegroundColor Yellow
    exit
}

# **Initialize Data Collection as an Array of Objects**
$finalData = @()

foreach ($sub in $subscriptions) {
    Write-Host "`nSwitching to Subscription: $($sub.Name)" -ForegroundColor Green
    Select-AzSubscription -SubscriptionId $sub.Id | Out-Null

    # Get All Route Tables in Subscription
    $routeTables = Get-AzRouteTable

    if (-not $routeTables) {
        Write-Host "No route tables found in Subscription: $($sub.Name)" -ForegroundColor Yellow
        continue
    }

    foreach ($routeTable in $routeTables) {
        $rtName = $routeTable.Name
        $rg = $routeTable.ResourceGroupName
        $rtDescription = if ($routeTable.Tags) { ($routeTable.Tags | Out-String).Trim() } else { "No Description" }

        # Get Routes & Categorize Next-Hop Types
        $routeList = @()
        foreach ($route in $routeTable.Routes) {
            $routeType = switch ($route.NextHopType) {
                "Internet" { "Default Route" }
                "VirtualNetwork" { "Internal Route" }
                "VirtualAppliance" { "Firewall Route" }
                "VirtualNetworkGateway" { "Forced VPN Route" }
                default { "Other" }
            }
            $routeList += "$($route.AddressPrefix) → $($route.NextHopType) ($routeType)"
        }

        if (-not $routeList) { $routeList = @("0.0.0.0/0 → Internet (Default Route)") }
        $routes = $routeList -join "; "

        # Get Subnets Using This Route Table & Their VNets
        $vNets = Get-AzVirtualNetwork
        $subnets = $vNets | ForEach-Object {
            $_.Subnets | Where-Object { $_.RouteTable.Id -eq $routeTable.Id } | 
            Select-Object Name, Id, @{Name="VNet";Expression={$_.VirtualNetworkName}}
        }

        if (-not $subnets) {
            Write-Host "No subnets found for Route Table: $rtName" -ForegroundColor Yellow
            $subnets = @(@{Name="None"; VNet="None"; Id="None"})
        }

        foreach ($subnet in $subnets) {
            $subnetName = $subnet.Name
            $vnetName = $subnet.VNet

            # Fix VM Count (Map VM NICs to Subnets)
            $vmCount = 0
            $vms = Get-AzVM
            foreach ($vm in $vms) {
                foreach ($nic in $vm.NetworkProfile.NetworkInterfaces) {
                    $nicDetails = Get-AzNetworkInterface -Name ($nic.Id -split "/")[-1] -ResourceGroupName ($nic.Id -split "/")[4]
                    if ($nicDetails.IpConfigurations.Subnet.Id -eq $subnet.Id) {
                        $vmCount++
                    }
                }
            }

            # Get NSG Assigned to Subnet
            $nsg = (Get-AzNetworkSecurityGroup | Where-Object { $_.Subnets.Id -contains $subnet.Id }).Name
            if (-not $nsg) { $nsg = "None" }

            # Store Data in `[PSCustomObject]`
            $finalData += [PSCustomObject]@{
                Subscription  = $sub.Name
                RouteTable    = $rtName
                ResourceGroup = $rg
                VNet          = $vnetName
                Routes        = $routes
                Subnet        = $subnetName
                NSG           = $nsg
                VMCount       = $vmCount
                Description   = $rtDescription
            }
        }
    }
}

# **Export Data to CSV & JSON**
if ($finalData.Count -gt 0) {
    $finalData | ConvertTo-Json -Depth 5 | Out-File $OutputJSON
    $finalData | Export-Csv -Path $OutputCSV -NoTypeInformation
    Write-Host "Exported data to JSON and CSV successfully." -ForegroundColor Green
} else {
    Write-Host "No route tables found. Skipping export." -ForegroundColor Yellow
}

Write-Host "`nGenerating HTML Report..." -ForegroundColor Green

# **Improved HTML Report**
$graphData = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        h2 { text-align: center; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; border: 1px solid black; text-align: left; }
        th { background-color: #0078D4; color: white; }
    </style>
</head>
<body>
    <h2>Azure Route Table Documentation</h2>
    <table>
        <tr>
            <th>Subscription</th>
            <th>Route Table</th>
            <th>Resource Group</th>
            <th>VNet</th>
            <th>Routes</th>
            <th>Subnet</th>
            <th>NSG</th>
            <th>VMs in Subnet</th>
            <th>Description</th>
        </tr>
"@

foreach ($entry in $finalData) {
    $graphData += @"
        <tr>
            <td>$($entry.Subscription)</td>
            <td>$($entry.RouteTable)</td>
            <td>$($entry.ResourceGroup)</td>
            <td>$($entry.VNet)</td>
            <td>$($entry.Routes)</td>
            <td>$($entry.Subnet)</td>
            <td>$($entry.NSG)</td>
            <td>$($entry.VMCount)</td>
            <td>$($entry.Description)</td>
        </tr>
"@
}

$graphData += @"
    </table>
</body>
</html>
"@

$graphData | Out-File $OutputHTML
Write-Host "Report generated: $OutputHTML" -ForegroundColor Yellow