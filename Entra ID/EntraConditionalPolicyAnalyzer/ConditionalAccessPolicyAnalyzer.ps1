# Function to ensure modules are installed and loaded
function Ensure-Module($moduleName) {
    try {
        Import-Module $moduleName -ErrorAction Stop
    } catch {
        Install-Module $moduleName -Force
        Import-Module $moduleName
    }
    Write-Host "$moduleName module loaded." -ForegroundColor Cyan
}

# Load necessary modules
Ensure-Module "MSAL.PS"
Ensure-Module "ImportExcel"

# Function to authenticate and fetch Conditional Access Policies using Graph API
function Fetch-CAPoliciesViaGraph {
    $scopes = "https://graph.microsoft.com/.default"  # Default scope for Graph API

    try {
        # Perform interactive authentication
        $tokenRequest = Get-MsalToken -Scopes $scopes -Interactive
        if (-not $tokenRequest) {
            Write-Host "Authentication failed. Unable to acquire token." -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "Authentication issue: $_" -ForegroundColor Red
        return @()
    }

    $headers = @{
        "Authorization" = "Bearer $($tokenRequest.AccessToken)"
        "Content-Type" = "application/json"
    }

    $graphUrl = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
    try {
        $response = Invoke-RestMethod -Headers $headers -Uri $graphUrl -Method Get
        return $response.value
    } catch {
        Write-Host "Failed to fetch policies: $_" -ForegroundColor Red
        return @()
    }
}

# Authenticate and fetch policies
$policies = Fetch-CAPoliciesViaGraph

# Function to evaluate policy against best practices
function Evaluate-Policy($policy) {
    $findings = @()

    # Example check: Ensure MFA is enforced
    if ('mfa' -notin $policy.grantControls.builtInControls) {
        $findings += "Recommendation: Enforce MFA for high-risk operations."
    }

    # Example check: Block legacy authentication
    if ($policy.conditions.clientAppTypes -contains "Other") {
        $findings += "Risk: Legacy authentication methods are allowed. Consider blocking these."
    }

    return $findings
}

# Evaluate policies and handle Excel export
if ($policies.Count -gt 0) {
    $excelPackage = New-ExcelPackage
    $workbook = $excelPackage.Workbook

    foreach ($policy in $policies) {
        $worksheet = $workbook.Worksheets.Add($policy.displayName)
        $findings = Evaluate-Policy -policy $policy
        $worksheet.Cells["A1"].LoadFromCollection($findings, $true)
    }

    try {
        $excelFilePath = ".\ConditionalAccessPoliciesAnalysis.xlsx"
        $excelPackage.SaveAs($excelFilePath)
        Write-Host "Analysis completed. Findings are saved in $excelFilePath" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to save Excel file: $_" -ForegroundColor Red
    } finally {
        $excelPackage.Dispose()
    }
} else {
    Write-Host "No policies retrieved or processed." -ForegroundColor Yellow
}
