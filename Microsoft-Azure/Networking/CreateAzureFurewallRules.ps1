$RG="Packt-Networking-Portal"
$Location="West Europe"

#Add a rule to allow *packt.com
$Azfw = Get-AzFirewall -ResourceGroupName $RG
$Rule = New-AzFirewallApplicationRule -Name Rule1 -Protocol "http:80","https:443" -TargetFqdn "*packt.com"
$RuleCollection = New-AzFirewallApplicationRuleCollection -Name RuleCollection1 -Priority 100 -Rule $Rule -ActionType "Allow"
$Azfw.ApplicationRuleCollections = $RuleCollection
Set-AzFirewall -AzureFirewall $Azfw

#Add a rule to deny *google.com
$Azfw = Get-AzFirewall -ResourceGroupName $RG
$Rule = New-AzFirewallApplicationRule -Name Rule1 -Protocol "http:80","https:443" -TargetFqdn "*google.com"
$RuleCollection = New-AzFirewallApplicationRuleCollection -Name RuleCollection1 -Priority 100 -Rule $Rule -ActionType "Deny"
$Azfw.ApplicationRuleCollections = $RuleCollection
Set-AzFirewall -AzureFirewall $Azfw

#Create UDR rule
$Azfw = Get-AzFirewall -ResourceGroupName $RG
$config = $Azfw.IpConfigurations[0].PrivateIPAddress
$Route = New-AzRouteConfig -Name 'Route1' -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $config
$RouteTable = New-AzRouteTable -Name 'RouteTable1' -ResourceGroupName $RG -location $Location -Route $Route