# Script Name: Export-ConditionalAccessPoliciesToExcel.ps1
# Created by: Shaun Hardneck
# Description: This script exports all available Conditional Access policies in Microsoft Entra ID to an Excel file with enhanced readability.

# Import the Microsoft Graph module and ImportExcel module
# Import-Module Microsoft.Graph
Import-Module ImportExcel

# Define the output Excel file path
$outputPath = ".\ConditionalAccessPolicies.xlsx"

# Authenticate to Microsoft Graph with interactive login
Write-Host "Please log in to Microsoft Graph..."
Connect-MgGraph -Scopes "Policy.Read.All", "Group.Read.All", "User.Read.All", "Application.Read.All", "Directory.Read.All" -NoWelcome

# Function to fetch Conditional Access policies
function Get-ConditionalAccessPolicies {
    try {
        $policies = @()
        $response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
        
        if ($response.value) {
            $policies += $response.value
            while ($response.'@odata.nextLink') {
                $response = Invoke-MgGraphRequest -Method GET -Uri $response.'@odata.nextLink'
                $policies += $response.value
            }
        }
        return $policies
    } catch {
        Write-Host "Error fetching Conditional Access policies: $_" -ForegroundColor Red
        throw
    }
}

# Function to get application name from ID
function Get-ApplicationName {
    param ($id)
    try {
        $response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/applications/$id"
        return $response.displayName
    } catch {
        return $id
    }
}

# Function to get display name from ID
function Get-DisplayName {
    param ($id)
    try {
        $response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/directoryObjects/$id"
        switch ($response.'@odata.type') {
            "#microsoft.graph.group" { return $response.displayName }
            "#microsoft.graph.user" { return $response.displayName }
            "#microsoft.graph.application" { return Get-ApplicationName -id $id }
            "#microsoft.graph.device" { return $response.displayName }
            default { return $id }
        }
    } catch {
        return $id
    }
}

# Function to format conditions
function Format-Conditions {
    param ($conditions)
    $result = [ordered]@{}
    if ($conditions) {
        if ($conditions.applications) {
            $result.ApplicationsInclude = ($conditions.applications.includeApplications | ForEach-Object { Get-ApplicationName -id $_ }) -join ', '
            $result.ApplicationsExclude = ($conditions.applications.excludeApplications | ForEach-Object { Get-ApplicationName -id $_ }) -join ', '
        }
        if ($conditions.users) {
            $result.UsersInclude = ($conditions.users.includeUsers | ForEach-Object { Get-DisplayName -id $_ }) -join ', '
            $result.UsersExclude = ($conditions.users.excludeUsers | ForEach-Object { Get-DisplayName -id $_ }) -join ', '
        }
        if ($conditions.locations) {
            $result.LocationsInclude = ($conditions.locations.includeLocations | ForEach-Object { Get-DisplayName -id $_ }) -join ', '
            $result.LocationsExclude = ($conditions.locations.excludeLocations | ForEach-Object { Get-DisplayName -id $_ }) -join ', '
        }
        if ($conditions.platforms) {
            $result.PlatformsInclude = $conditions.platforms.includePlatforms -join ', '
            $result.PlatformsExclude = $conditions.platforms.excludePlatforms -join ', '
        }
        if ($conditions.clientAppTypes) {
            $result.ClientAppTypes = $conditions.clientAppTypes -join ', '
        }
        if ($conditions.signInRiskLevels) {
            $result.SignInRiskLevels = $conditions.signInRiskLevels -join ', '
        }
        if ($conditions.deviceStates) {
            $result.DeviceStatesInclude = $conditions.deviceStates.includeStates -join ', '
            $result.DeviceStatesExclude = $conditions.deviceStates.excludeStates -join ', '
        }
    }
    return $result
}

# Function to format grant controls
function Format-GrantControls {
    param ($grantControls)
    $result = [ordered]@{}
    if ($grantControls) {
        if ($grantControls.builtInControls) {
            $result.BuiltInControls = $grantControls.builtInControls -join ', '
        }
        if ($grantControls.customAuthenticationFactors) {
            $result.CustomAuthenticationFactors = $grantControls.customAuthenticationFactors -join ', '
        }
        if ($grantControls.operator) {
            $result.Operator = $grantControls.operator
        }
    }
    return $result
}

# Function to format session controls
function Format-SessionControls {
    param ($sessionControls)
    $result = [ordered]@{}
    if ($sessionControls) {
        foreach ($control in $sessionControls.psobject.Properties) {
            $result.$($control.Name) = $control.Value
        }
    }
    return $result
}

# Fetch all Conditional Access policies
$conditionalAccessPolicies = Get-ConditionalAccessPolicies

# Prepare data for export
$exportData = @()

foreach ($policy in $conditionalAccessPolicies) {
    $conditions = Format-Conditions -conditions $policy.conditions
    $grantControls = Format-GrantControls -grantControls $policy.grantControls
    $sessionControls = Format-SessionControls -sessionControls $policy.sessionControls

    $exportData += [PSCustomObject]@{
        ID                   = $policy.id
        DisplayName          = $policy.displayName
        State                = $policy.state
        ApplicationsInclude  = $conditions.ApplicationsInclude
        ApplicationsExclude  = $conditions.ApplicationsExclude
        UsersInclude         = $conditions.UsersInclude
        UsersExclude         = $conditions.UsersExclude
        LocationsInclude     = $conditions.LocationsInclude
        LocationsExclude     = $conditions.LocationsExclude
        PlatformsInclude     = $conditions.PlatformsInclude
        PlatformsExclude     = $conditions.PlatformsExclude
        ClientAppTypes       = $conditions.ClientAppTypes
        SignInRiskLevels     = $conditions.SignInRiskLevels
        DeviceStatesInclude  = $conditions.DeviceStatesInclude
        DeviceStatesExclude  = $conditions.DeviceStatesExclude
        BuiltInControls      = $grantControls.BuiltInControls
        CustomAuthFactors    = $grantControls.CustomAuthenticationFactors
        Operator             = $grantControls.Operator
        SessionControls      = ($sessionControls.psobject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) -join ', '
    }
}

# Export data to Excel with color formatting
$exportData | Export-Excel -Path $outputPath -AutoSize -WorksheetName "ConditionalAccessPolicies" -TableStyle Medium9

# Add color formatting to specific columns
$excel = Open-ExcelPackage -Path $outputPath
$workSheet = $excel.Workbook.Worksheets["ConditionalAccessPolicies"]

# Apply color formatting to headings
$headerCells = "A1:Q1"
$workSheet.Cells[$headerCells].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
$workSheet.Cells[$headerCells].Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::DarkBlue)
$workSheet.Cells[$headerCells].Style.Font.Color.SetColor([System.Drawing.Color]::White)
$workSheet.Cells[$headerCells].Style.Font.Bold = $true

# Auto-fit columns for better readability
$workSheet.Cells[$workSheet.Dimension.Address].AutoFitColumns()

Close-ExcelPackage $excel

# Output the location of the Excel file
Write-Host "Conditional Access policies have been exported to $outputPath" -ForegroundColor Green

# End of script