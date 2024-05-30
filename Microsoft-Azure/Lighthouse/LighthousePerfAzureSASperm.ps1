Connect-AzAccount
$Subs = Get-AzSubscription
foreach ($sub in $subs) {
Set-AzContext -Subscription $sub.id
New-AzDeployment -Name "Performanta Azure SAS" -Location uksouth -TemplateFile "PerfAzureSAS.json" -Verbose
}