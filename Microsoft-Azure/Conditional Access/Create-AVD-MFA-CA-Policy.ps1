
#Connect to Azure AD to create the New Conditional Access Policy
Connect-AzureAD

$policyName = "CA:Secure-AVD-With-MFA"
$userGroup = Get-AzureADGroup -SearchString "rsg-vdi-users"
$azureVDAppId = "9cdead84-a844-4324-93f2-b2e6bb768d07"  # Azure Virtual Desktop App ID
$MsftRDskAppEnID = "a4a365df-50f1-4397-bc59-1a1564b8bb9c" #Microsoft Remote Desktop Entra ID cloud app
$WinCloudAppID = "270efc09-cd0d-444b-a71f-39af4910ec45" #Windows Cloud Login Entra ID cloud app

$condition = New-Object -TypeName "Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet"
$condition.Applications = New-Object -TypeName "Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition"
$condition.Applications.IncludeApplications = @($azureVDAppId, $MsftRDskAppEnID, $WinCloudAppID)

$condition.Users = New-Object -TypeName "Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition"
$condition.Users.IncludeUsers = @($userGroup.ObjectId)

$condition.ClientAppTypes = @("Browser", "MobileAppsAndDesktopClients")

$grantControl = New-Object -TypeName "Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls"
$grantControl._Operator = "OR"
$grantControl.BuiltInControls = @("Mfa")  # Updated to use "Mfa"

# Since there were errors with Session Controls, it's better to omit this part if it's causing issues
# or consult the latest AzureAD or Microsoft Graph documentation on how to correctly implement session controls

New-AzureADMSConditionalAccessPolicy -DisplayName $policyName -State "Enabled" -Conditions $condition -GrantControls $grantControl

# Display success message
Write-Host "$policyName has successfully been created." -ForegroundColor Green