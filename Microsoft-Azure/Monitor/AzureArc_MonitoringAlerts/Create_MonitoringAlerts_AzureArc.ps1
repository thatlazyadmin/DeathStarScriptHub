# Connect to Azure account
Connect-AzAccount

# Variables
$resourceGroupName = "lab-rsg104"
$actionGroupName = "UNERD-ARC-Monitoring"
$subscriptionId = "6052118b-adbb-4504-a41a-e8e1121163few"
$scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/YourVMName"

# Get Action Group ID
$actionGroup = Get-AzActionGroup -ResourceGroupName $resourceGroupName -Name $actionGroupName
$actionGroupId = $actionGroup.Id

# Create CPU Utilization Alert
$cpuAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "HighCPUAlert" -Description "Alert for high CPU usage" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Percentage CPU" -TimeAggregation "Average" -Operator "GreaterThan" -Threshold 80) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Memory Utilization Alert
$memoryAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "HighMemoryAlert" -Description "Alert for high memory usage" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Available Memory Bytes" -TimeAggregation "Average" -Operator "LessThan" -Threshold 20) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Disk Space Alert
$diskSpaceAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "LowDiskSpaceAlert" -Description "Alert for low disk space" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Free Disk Space Bytes" -TimeAggregation "Average" -Operator "LessThan" -Threshold 10) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Disk I/O Alert
$diskIOAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "HighDiskIOAlert" -Description "Alert for high disk I/O" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Disk Read Operations/Sec" -TimeAggregation "Average" -Operator "GreaterThan" -Threshold 1000) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Network Usage Alert
$networkUsageAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "HighNetworkUsageAlert" -Description "Alert for high network usage" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Network In Total" -TimeAggregation "Average" -Operator "GreaterThan" -Threshold 500000000) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Agent Health Alert
$agentHealthAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "AgentHealthAlert" -Description "Alert for Azure Arc agent health" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Heartbeat" -TimeAggregation "Count" -Operator "Equals" -Threshold 0) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Custom Log Search Alert
$customLogSearchAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "CustomLogSearchAlert" -Description "Custom log search alert" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "Custom Log" -TimeAggregation "Average" -Operator "GreaterThan" -Threshold 0) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

# Create Security Events Alert
$securityEventsAlertRule = New-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -Name "SecurityEventsAlert" -Description "Alert for security events" -Severity 2 -Enabled `
    -Scope $scope -Condition (New-AzMetricAlertRuleV2Criteria -MetricName "SecurityEvents" -TimeAggregation "Count" -Operator "GreaterThan" -Threshold 0) `
    -WindowSize (New-TimeSpan -Minutes 5) -Frequency (New-TimeSpan -Minutes 1) -ActionGroupId $actionGroupId

Write-Host "Alert rules have been created successfully."
