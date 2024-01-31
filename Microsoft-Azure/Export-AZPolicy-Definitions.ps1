$objResults = @()
$arrResults = @()

$GetPSDs = Get-AzPolicySetDefinition

foreach ($GetPSD in $GetPSDs) {
	$GetPDIDs = $GetPSD.Properties.PolicyDefinitions.PolicyDefinitionId
	foreach ($GetPDID in $GetPDIDs) {
		$GetPD = Get-AzPolicyDefinition | ?{$_.PolicyDefinitionId -eq $GetPDID}
		
		$objResults = New-Object PSObject -Property @{
			PolicySetMetadata				= $GetPSD.Properties.Metadata;
			PolicySetDisplayName			= $GetPSD.Properties.DisplayName;
			PolicySetDescription			= $GetPSD.Properties.Description;
			PolicySetType					= $GetPSD.Properties.PolicyType;
			PolicySetDefinitionID			= $GetPSD.PolicySetDefinitionId;
			
			PolicyMetadata					= $GetPD.Properties.Metadata;
			PolicyDisplayName				= $GetPD.Properties.DisplayName;
			PolicyDescription				= $GetPD.Properties.Description;
			PolicyType						= $GetPD.Properties.PolicyType;
			PolicyDefinitionID				= $GetPD.PolicyDefinitionId;
			AvailableEffects				= [string]$GetPD.Properties.Parameters.effect.allowedValues;
		}
		$arrResults = $arrResults + $objResults
	}	
}

$arrResults | Export-Csv -Path "C:\Softlib\Github\Thatlazyadmin\DeathStarScriptHub\Defender-for-Cloud\PSD_PD_Output.csv" -NoType