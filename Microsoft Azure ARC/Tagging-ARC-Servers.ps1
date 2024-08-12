# Define tags for Azure Arc-enabled servers
$ResourceName = "azarc-dfc"
$ResourceGroup = "rsg-arc-pilot"
$Tags = @{
    Environment = "Production"
}

# Tagging Azure Arc-enabled servers
Set-AzTag -ResourceId (Get-AzResource -ResourceName $ResourceName -ResourceGroupName $ResourceGroup).ResourceId -Tag $Tags -Operation Merge
