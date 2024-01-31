$ResourceGroupName = "packt-demo-webapp"
$webappname="packt-demo-webapp"
$location="West Europe"
$NumberOfWebApps= 2

New-AzResourceGroup -Name $ResourceGroupName `
-Location $location


$i=1

Do

{

New-AzWebApp -Name $webappname'-0'$i `
-Location $location `
-AppServicePlan $webappname `
-ResourceGroupName $ResourceGroupName

} While (($i=$I+1) -le $NumberOfWebApps)