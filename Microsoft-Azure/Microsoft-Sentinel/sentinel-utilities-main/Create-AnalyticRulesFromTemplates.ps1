<#
.SYNOPSIS
The cmdlet Create-AnalyticRulesFromTemplates automates the creation of Analytic Rules in Microsoft Sentinel starting from existing Templates.

.DESCRIPTION
   Version: 0.0.3
   Release Date: 2024-02-05
The cmdlet Create-AnalyticRulesFromTemplates creates the Analytic Rules (aka Rules) based on the Analytic Rules Templates (aka Templates) available 
in the Content Hub Solutions (aka Packages) already installed in the Sentinel workspace. 
Before using this cmdlet, ensure to have the desired Solutions installed and the related Connectors active.
The Sentinel out-of-the-box Templates that are not part of any already installed Solutions are not considered by the cmdlet.
The Templates that have already one or more active Rule associated to them are skipped: no additional Rule is created.
It is possible to further filter-out the Templates to be considered by Severities and/or by DisplayNames (specified in an input CSV file).
The script can be launched also to extract the existing Templates in a CSV file, so that you can edit this file manually to remove the undesired rules and 
then use it as input file for filtering-out the Templates to be considered during the rule creation.
The execution can be simulated, so that the cmdlet only logs what it would do but without doing any real change to Sentinel.
The log file is created in the same local directory from where the script is launched. 
The creation of some Rules may terminate with an error because of missing content in Sentinel (e.g. missing tables). These errors are simply logged and the execution continues.

.PARAMETER SubscriptionId
    (Mandatory, string) ID of the Azure Subscription containing the Sentinel workspace.

.PARAMETER ResourceGroup
    (Mandatory, string) Name of the Azure Resource Group containing the Sentinel workspace.

.PARAMETER Workspace
    (Mandatory, string) Name of the Azure Sentinel workspace.

.PARAMETER Region
    (Mandatory, string) Azure region where the Sentinel workspace is located. E.g.: westeurope

.PARAMETER SaveExistingAnalyticRuleTemplatesToCsvFile
    (Optional, bool) Flag to save existing Analytic Rule Templates to a CSV file. Default is false.
    When it is specified and set to true, OutputAnalyticRuleTemplatesCsvFile must be specified and
    no Analytic Rule will be created (not even in a simulated loop). 
    The value of the paramters 'SimulateOnly', 'LimitToMaxNumberOfRules', 'InputCsvFile' and 
    'SeveritiesToInclude' will then be ignored.

.PARAMETER OutputAnalyticRuleTemplatesCsvFile
    (Optional, string) Path to the CSV file where the cmdlet writes the information of the Analytic 
    Rule Templates existing in the Sentinel workspace (all and only the Templates existing in the 
    ContentHub solutions installed in the workspace).
    The CSV will contain the following colums: 
    "DisplayName","Severity","AtLeastOneRuleAlreadyExists","Package"

.PARAMETER CsvSeparatorChar
    (Optional, char) Character used as a separator in the CSV file.

.PARAMETER SimulateOnly
    (Optional, bool) Flag to simulate the operation without making any changes in Sentinel. Default is true.

.PARAMETER LimitToMaxNumberOfRules
    (Optional, int) Limit the maximum number of Rules that will be created. Default is 0 (no limit).

.PARAMETER InputCsvFile
    (Optional, string) Path to the CSV file containing the DisplayName of the Templates to be considered.

.PARAMETER SeveritiesToInclude
    (Optional, string array) Array of severities to include in the operation. Default is all severities ("Informational", "Low", "Medium", "High").


.EXAMPLE
################
# Exports the existing Templates in a CSV file where you can remove the lines of the undesired rules to be created. 
# No change is made to Sentinel
################
$SubscriptionId = "<...>"
$ResourceGroup = "<...>"
$Workspace = "<...>"
$Region = "<...>" #e.g. westeurope
$SaveExistingAnalyticRuleTemplatesToCsvFile = $true
$OutputAnalyticRuleTemplatesCsvFile = "<path>\art.csv"
$CsvSeparatorChar = ';'

Create-AnalyticRulesFromTemplates -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -Workspace $Workspace -Region $Region  `
    -SaveExistingAnalyticRuleTemplatesToCsvFile $SaveExistingAnalyticRuleTemplatesToCsvFile -OutputAnalyticRuleTemplatesCsvFile $OutputAnalyticRuleTemplatesCsvFile   `
    -CsvSeparatorChar $CsvSeparatorChar #-verbose

.EXAMPLE
################
# Creates the Rules from the Templates existing in the Solutions installed in Sentinel. Among these, the only Templates considered are those 
# with the 'DisplayName' specified in the input CSV file and with 'Severity' High or Medium.
################
$SubscriptionId = "<...>"
$ResourceGroup = "<...>"
$Workspace = "<...>"
$Region = "<...>" #e.g. westeurope
$CsvSeparatorChar = ';'
$SimulateOnly = $false
$InputCsvFile = "<path>\<filename>.csv"
$SeveritiesToInclude = @("High","Medium")

Create-AnalyticRulesFromTemplates -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -Workspace $Workspace -Region $Region  `
    -CsvSeparatorChar $CsvSeparatorChar -InputCsvFile $InputCsvFile  `
    -SeveritiesToInclude $SeveritiesToInclude -Simulate $SimulateOnly #-verbose

.EXAMPLE
################
# Simulates the creation of the Rules from the Templates existing in the Solutions installed in Sentinel. Among these, the only Templates 
# considered are those with the 'DisplayName' specified in the input CSV file and with 'Severity' High or Medium or Informational.
################
$SubscriptionId = "<...>"
$ResourceGroup = "<...>"
$Workspace = "<...>"
$Region = "<...>" #e.g. westeurope
$CsvSeparatorChar = ';'
$SimulateOnly = $true
$InputCsvFile = "<path>\<filename>.csv"
$SeveritiesToInclude = @("High","Medium","Informational")

Create-AnalyticRulesFromTemplates -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -Workspace $Workspace -Region $Region  `
    -CsvSeparatorChar $CsvSeparatorChar -InputCsvFile $InputCsvFile `
    -SeveritiesToInclude $SeveritiesToInclude -Simulate $SimulateOnly #-verbose

.EXAMPLE
################
# Simulates the creation of the Rules from the Templates existing in the Solutions installed in Sentinel. Among these, the only Templates 
# considered are those with 'Severity' High.
# The execution is stopped after the first 10 Rules virtually added.
################
$SubscriptionId = "<...>"
$ResourceGroup = "<...>"
$Workspace = "<...>"
$Region = "<...>" #e.g. westeurope
$SimulateOnly = $true
$LimitToMaxNumberOfRules = 10
$SeveritiesToInclude = @("High")

Create-AnalyticRulesFromTemplates -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -Workspace $Workspace -Region $Region  `
    -SeveritiesToInclude $SeveritiesToInclude -Simulate $SimulateOnly -LimitToMaxNumberOfRules $LimitToMaxNumberOfRules #-verbose

.NOTES
The script requires PowerShell 7. 
* Check the version of your powershell by using: $PSVersionTable.PSVersion
* Install it by launching: winget search Microsoft.PowerShell
(https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4)

.AUTHOR
Stefano Pescosolido (https://www.linkedin.com/in/stefanopescosolido/)
Part of the code is taken from https://github.com/Azure/Azure-Sentinel/tree/master/Tools/Sentinel-All-In-One

#>

function CreateAuthenticationHeader {
    param (
        [Parameter(Mandatory = $true)][string]$TenantId,
        [Parameter(Mandatory = $false)][string]$PrefixInDisplayName
    )
    $instanceProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($instanceProfile)
    $token = $profileClient.AcquireAccessToken($TenantId)
    $authNHeader = @{
        'Content-Type'  = 'application/json' 
        'Authorization' = 'Bearer ' + $token.AccessToken 
    }

    return $authNHeader
}

function CreateAnalyticRule {
    param (
        [Parameter(Mandatory = $true)][string]$BaseUri,
        [Parameter(Mandatory = $true)][object]$Template,
        [Parameter(Mandatory = $false)][bool]$SimulateOnly = $true
    )
    
    $alertUri = "$BaseUri/providers/Microsoft.SecurityInsights/alertRules/"
    $BaseAlertUri = $BaseUri + "/providers/Microsoft.SecurityInsights/alertRules/"
    
    $kind = $Template.properties.mainTemplate.resources.kind
    $displayName = $Template.properties.mainTemplate.resources.properties[0].displayName
    $eventGroupingSettings = $Template.properties.mainTemplate.resources.properties[0].eventGroupingSettings
    if ($null -eq $eventGroupingSettings) {
        $eventGroupingSettings = [ordered]@{aggregationKind = "SingleAlert" }
    }
    $body = ""
    $properties = $Template.properties.mainTemplate.resources[0].properties
    $properties.enabled = $true
    #Add the field to link this rule with the rule template so that the rule template will show up as used
    #We had to use the "Add-Member" command since this field does not exist in the rule template that we are copying from.
    $properties | Add-Member -NotePropertyName "alertRuleTemplateName" -NotePropertyValue $Template.properties.mainTemplate.resources[0].name
    $properties | Add-Member -NotePropertyName "templateVersion" -NotePropertyValue $Template.properties.mainTemplate.resources[1].properties.version


    #Depending on the type of alert we are creating, the body has different parameters
    switch ($kind) {
        "MicrosoftSecurityIncidentCreation" {  
            $body = @{
                "kind"       = "MicrosoftSecurityIncidentCreation"
                "properties" = $properties
            }
        }
        "NRT" {
            $body = @{
                "kind"       = "NRT"
                "properties" = $properties
            }
        }
        "Scheduled" {
            $body = @{
                "kind"       = "Scheduled"
                "properties" = $properties
            }
            
        }
        Default { }
    }
    #If we have created the body...
    if ("" -ne $body) {
        #Create the GUId for the alert and create it.
        $guid = (New-Guid).Guid
        #Create the URI we need to create the alert.
        $alertUri = $BaseAlertUri + $guid + "?api-version=2022-12-01-preview"
        try {
            Write-Verbose -Message "Template: $displayName - Creating the rule...."
            
            if(-not($SimulateOnly)){
                $rule = Invoke-RestMethod -Uri $alertUri -Method Put -Headers $authHeader -Body ($body | ConvertTo-Json -EnumsAsStrings -Depth 50)
                Write-Host -Message "Template: $displayName - Creating the rule - Succeeded" -ForegroundColor Green  
                #This pauses for 1 second so that we don't overload the workspace.
                Start-Sleep -Seconds 1
            }
            else {
                Write-Host -Message "Template: $displayName - Creating the rule - Succeeded (SIMULATED)" -ForegroundColor Green  
            }
            
        }
        catch {
            Write-Verbose "Template: $displayName - ERROR while creating the rule:"
            Write-Verbose $_
            #Write-Host -Message "Template: $displayName - ERROR while creating the rule: $(($_).Exception.Message)" -ForegroundColor Red
            Write-Host -Message "Template: $displayName - ERROR while creating the rule" -ForegroundColor Red
            throw   
        }
    }

    return $rule
}

function LinkAnalyticRuleToSolution {
    param (
        [Parameter(Mandatory = $true)][string]$BaseUri,
        [Parameter(Mandatory = $true)][object]$Rule,
        [Parameter(Mandatory = $true)][object]$Template,
        [Parameter(Mandatory = $true)][object]$Solution,
        [Parameter(Mandatory = $false)][bool]$SimulateOnly = $true
    )

    $baseMetaURI = $BaseUri + "/providers/Microsoft.SecurityInsights/metadata/analyticsrule-"

    $metabody = @{
        "apiVersion" = "2022-01-01-preview"
        "name"       = "analyticsrule-" + $Rule.name
        "type"       = "Microsoft.OperationalInsights/workspaces/providers/metadata"
        "id"         = $null
        "properties" = @{
            "contentId" = $Template.properties.mainTemplate.resources[0].name
            "parentId"  = $Rule.id
            "kind"      = "AnalyticsRule"
            "version"   = $Template.properties.mainTemplate.resources.properties[1].version
            "source"    = $Solution.source
            "author"    = $Solution.author
            "support"   = $Solution.support
        }
    }
    Write-Verbose -Message "Rule: $(($Rule).displayName) - Updating metadata...."
    $metaURI = $baseMetaURI + $Rule.name + "?api-version=2022-01-01-preview"
    try {
        if(-not($SimulateOnly)){
            $metaVerdict = Invoke-RestMethod -Uri $metaURI -Method Put -Headers $authHeader -Body ($metabody | ConvertTo-Json -EnumsAsStrings -Depth 5)
            Write-Host -Message "Rule: $(($Rule).properties.displayName) - Updating metadata - Succeeded" -ForegroundColor Green 
            #This pauses for 1 second so that we don't overload the workspace.
            Start-Sleep -Seconds 1 
        } else {            
            Write-Host -Message "Rule: $(($Rule).properties.displayName) - Updating metadata - Succeeded (SIMULATED)" -ForegroundColor Green  
        }
              
    }
    catch {
        Write-Verbose "Rule: $(($Rule).displayName) - ERROR while updating metadata:"
        Write-Verbose $_
        #Write-Host -Message "Rule: $(($Rule).displayName) - ERROR while updating metadata: $(($_).Exception.Message)" -ForegroundColor Red
        Write-Host -Message "Rule: $(($Rule).displayName) - ERROR while updating metadata" -ForegroundColor Red
        throw
    }
    return $metaVerdict

}

function CheckIfAnAnalyticRuleAssociatedToTemplateExist {
    param (
        [Parameter(Mandatory = $true)][string]$BaseUri,
        [Parameter(Mandatory = $true)][object]$Template
    )

    $uri = $BaseUri + "/providers/Microsoft.SecurityInsights/alertRules?api-version=2022-01-01-preview"
    
    $allRules = (Invoke-RestMethod -Uri $uri -Method Get -Headers $authHeader).value
    
    $found = $false
    foreach($rule in $allRules){
        if($rule.properties.alertRuleTemplateName -eq $Template.properties.mainTemplate.resources[0].name){
            $found = $true
            break
        }
    }
    
    return $found

}

function Create-AnalyticRulesFromTemplates {
    param(
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string]$Region,
        [Parameter(Mandatory = $false)][bool]$SaveExistingAnalyticRuleTemplatesToCsvFile = $false,
        [Parameter(Mandatory = $false)][string]$OutputAnalyticRuleTemplatesCsvFile,
        [Parameter(Mandatory = $false)][char]$CsvSeparatorChar,
        [Parameter(Mandatory = $false)][bool]$SimulateOnly = $true,
        [Parameter(Mandatory = $false)][int]$LimitToMaxNumberOfRules = 0,
        [Parameter(Mandatory = $false)][string]$InputCsvFile,
        [Parameter(Mandatory = $false)][string[]]$SeveritiesToInclude = @("Informational", "Low", "Medium", "High")
    )

    # Check installed PowerShell version 
    if($PSVersionTable.PSVersion.Major -lt 7){
        Write-Host "This cmdlet requires PowerShell 7. Exiting..." -ForegroundColor Red
        exit
    }
    
    #Check if Az.Accounts is installed
    $module = Get-Module -ListAvailable -Name Az.Accounts
    if($null -eq $module){
        Write-Host "The module 'Az.Accounts' is required and is not installed." -ForegroundColor Red
        Write-Host "To install it, open PowerShell as and Administrator and execute the following command: " -ForegroundColor Red
        Write-Host "Install-Module -Name Az.Accounts" -ForegroundColor Red
        Write-Host "Exiting..." -ForegroundColor Red
        exit
    }
    
    # Set default values for some parameters
    if($null -eq $CsvSeparatorChar){
        $CsvSeparatorChar = ';'
    } 
    
    if((-not($SaveExistingAnalyticRuleTemplatesToCsvFile))-and([string]::IsNullOrEmpty($SeveritiesToInclude))){
        $SeveritiesToInclude = @("Informational", "Low", "Medium", "High")
    } 

    # Check the coherence of the input parameters
    $askForConfirmation = $false
    if(($SaveExistingAnalyticRuleTemplatesToCsvFile) -and ([string]::IsNullOrEmpty($OutputAnalyticRuleTemplatesCsvFile))){
        Write-Host "When the input parameter 'SaveExistingAnalyticRuleTemplatesToCsvFile' is set to 'true' it is necessary to specify a value also for the input parameter 'OutputAnalyticRuleTemplatesCsvFile'. Exiting..." -ForegroundColor Red
        exit
    }

    if($SaveExistingAnalyticRuleTemplatesToCsvFile){
        Write-Host "NOTE: when the input parameter 'SaveExistingAnalyticRuleTemplatesToCsvFile' is set to 'true', no Analytic Rule will be created (not even in a simulated loop). The value of the paramters 'SimulateOnly', 'LimitToMaxNumberOfRules', 'InputCsvFile' and 'SeveritiesToInclude' will then be ignored." -ForegroundColor Blue -BackgroundColor Yellow
        $askForConfirmation = $true
    }

    if(($SaveExistingAnalyticRuleTemplatesToCsvFile) -and (-not([string]::IsNullOrEmpty($OutputAnalyticRuleTemplatesCsvFile)))){
        if(Test-Path($OutputAnalyticRuleTemplatesCsvFile)){
            Write-Host "NOTE: The file '$OutputAnalyticRuleTemplatesCsvFile' already exists and will be overwritten." -ForegroundColor Blue -BackgroundColor Yellow
            $askForConfirmation = $true
        }
        $folder = Split-Path -Parent $OutputAnalyticRuleTemplatesCsvFile
        if(-not(Test-Path($folder))){
            Write-Host "The folder '$folder' specified in the input parameter 'OutputAnalyticRuleTemplatesCsvFile' does not exist. Exiting..." -ForegroundColor Red
            exit
        }
    }

    if((-not($SaveExistingAnalyticRuleTemplatesToCsvFile))-and($SimulateOnly)){
        Write-Host "NOTE: when the input parameter 'SimulateOnly' is set to 'true', no Analytic Rule will be created but you can see - in the output messages and in the log file - what rule would be created" -ForegroundColor Blue  -BackgroundColor Yellow
        $askForConfirmation = $true        
    }

    $inCsvContent = $null
    $filterByTemplateDisplayName = $null
    if(-not([string]::IsNullOrEmpty($InputCsvFile))){
        if(-not(Test-Path($InputCsvFile))){
            Write-Host "The input file specified in the input parameter 'InputCsvFile' does not exist. Exiting..." -ForegroundColor Red
            exit
        } else {
            try {
                $inCsvContent = Import-Csv $InputCsvFile -Delimiter $CsvSeparatorChar
                if($inCsvContent | Get-Member -Name "DisplayName" -MemberType Properties){
                    $filterByTemplateDisplayName = $inCsvContent | Select-Object -ExpandProperty "DisplayName"
                } else {
                    Write-Host "Cannot find the column 'DisplayName' in the CSV content of the file '$InputCsvFile' with separator '$CsvSeparatorChar'" -ForegroundColor Red
                    exit
                }                
            }
            catch {
                Write-Host "Cannot read the CSV content of the file '$InputCsvFile' with separator '$CsvSeparatorChar' - ERROR: " $_.Exception.Message -ForegroundColor Red
                Write-Debug $_
                exit
            }            
        }
    }

    if($askForConfirmation){
        Write-Host " "
        if((Read-Host "Type 'y' if you want to continue...") -ne 'y'){
            Write-Host "Exiting..."
            exit
        }
        Write-Host " "
    }
        
    Write-Verbose "---------------------- START OF EXECUTION - $(Get-Date)" 
    Write-Verbose "SubscriptionId: $SubscriptionId"
    Write-Verbose "ResourceGroup: $ResourceGroup"
    Write-Verbose "Workspace: $Workspace"
    Write-Verbose "Region: $Region"
    Write-Verbose "SaveExistingAnalyticRuleTemplatesToCsvFile: $SaveExistingAnalyticRuleTemplatesToCsvFile"
    Write-Verbose "OutputAnalyticRuleTemplatesCsvFile: $OutputAnalyticRuleTemplatesCsvFile"    
    Write-Verbose "CsvSeparatorChar: $CsvSeparatorChar"
    Write-Verbose "Simulate: $SimulateOnly"
    Write-Verbose "LimitToMaxNumberOfRules: $LimitToMaxNumberOfRules"
    Write-Verbose "InputCsvFile: $InputCsvFile"
    Write-Verbose "SeveritiesToInclude: $SeveritiesToInclude"
    
    # Initialize log file
    $LogStartTime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss"
    $oLogFile = "log_$LogStartTime.log"
    "EXECUTION STARTED - $LogStartTime" | Out-File $oLogFile 
    
    # Authenticate to Azure
    Connect-AzAccount -DeviceCode | out-null
    Write-Verbose "Connected to Azure"
    Write-Host "Execution started. Please wait..."

    # Set the current subscription
    $context = Set-AzContext -SubscriptionId $subscriptionId 
    Write-Verbose "Azure Context set successfully"
    #Write-Debug "context: $context"

    # Get the Authentication Header for calling the REST APIs
    $authHeader = CreateAuthenticationHeader($context.Subscription.TenantId)
    Write-Verbose "Authentication header created successfully"
    #Write-Debug "authHeader: $authHeader"

    # List all Solutions in Content Hub
    $baseUri = "https://management.azure.com/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${Workspace}"
    $packagesUrl = $baseUri + "/providers/Microsoft.SecurityInsights/contentProductPackages?api-version=2023-04-01-preview"
    #Write-Debug "packagesUrl: $packagesUrl"
    $allSolutions = (Invoke-RestMethod -Method "Get" -Uri $packagesUrl -Headers $authHeader ).value
    Write-Verbose -Message "Number of Solutions found: $(($allSolutions).Count)"; "Number of Solutions found: $(($allSolutions).Count)" | Out-File $oLogFile -Append
    
    # List all Analytic Rule Templates which are part of the installed solutions
    $templatesUrl = $baseUri + "/providers/Microsoft.SecurityInsights/contentTemplates?api-version=2023-05-01-preview&%24filter=(properties%2FcontentKind%20eq%20'AnalyticsRule')"
    #Write-Debug "templatesUrl: $templatesUrl"
    $allTemplates = (Invoke-RestMethod -Uri $templatesUrl -Method Get -Headers $authHeader).value
    if($SaveExistingAnalyticRuleTemplatesToCsvFile){
        #Initialize CSV file                    
        "DisplayName","Severity","AtLeastOneRuleAlreadyExists","Package" -join $CsvSeparatorChar | Out-File $OutputAnalyticRuleTemplatesCsvFile 
    }
    Write-Verbose -Message "Number of Templates found: $(($allTemplates).Count)"; "Number of Templates found: $(($allTemplates).Count)" | Out-File $oLogFile -Append
    
    # Iterate through all the Analytic Rule Templates
    $NumberOfConsideredTemplates = 0
    $NumberOfSkippedTemplates = 0
    $NumberOfCreatedRules = 0
    $NumberOfErrors = 0
    $loopIndex = 0
    foreach ($template in $allTemplates ) {
        $loopIndex++ | Out-Null
        Write-Host "Processing template ($loopIndex)/$(($allTemplates).Count)..."
        $NumberOfConsideredTemplates++ | out-null

        # If the Template should be filtered by display name, do it now 
        if((-not($null -eq $filterByTemplateDisplayName)) -and (-not($filterByTemplateDisplayName.Contains($(($template).properties.displayName))))){
            Write-Verbose "Template skipped (display name not in the input CSV file): '$(($template).properties.displayName)'" 
            "Template skipped (display name not in the input CSV file): '$(($template).properties.displayName)'" | Out-File $oLogFile -Append
            $NumberOfSkippedTemplates++ | out-null
            continue
        }

        # Make sure that the Template's severity is one we want to include
        $severity = $template.properties.mainTemplate.resources.properties[0].severity
        if ( ($SeveritiesToInclude.Contains($severity)) -or ($SaveExistingAnalyticRuleTemplatesToCsvFile) ) {
            try {
                #Check if at least an Analytic Rule associated at this templates already exists
                Write-Verbose "Template: '$(($template).properties.displayName)' - Searching for existing rules..." 
                $found = CheckIfAnAnalyticRuleAssociatedToTemplateExist -BaseUri $baseUri -Template $template
                if(($found) -and (-not($SaveExistingAnalyticRuleTemplatesToCsvFile))){
                    Write-Verbose "Template '$(($template).properties.displayName)' - A rule already exists based on this template"                 
                    "Template '$(($template).properties.displayName)' - A rule already exists based on this template"  | Out-File $oLogFile -Append
                    $NumberOfSkippedTemplates++ | out-null
                    continue #goto next Template in the foreach loop
                }

                # Search for the solution containing the Template
                Write-Verbose "Template: '$(($template).properties.displayName)' - Searching for containing solution..." 
                $solution = $allSolutions.properties | Where-Object -Property "contentId" -Contains $template.properties.packageId
                #Write-Debug "solution: $solution"
                if(($null -eq $solution) -and (-not($SaveExistingAnalyticRuleTemplatesToCsvFile))){
                    Write-Verbose "Template '$(($template).properties.displayName)' - UNEXPECTED: solution not found"        
                    "Template '$(($template).properties.displayName)' - UNEXPECTED: solution not found" | Out-File $oLogFile -Append
                
                    $NumberOfErrors++ | out-null
                    continue #goto next Template in the foreach loop
                }

                if($SaveExistingAnalyticRuleTemplatesToCsvFile){                 
                    # Write Template info in CSV file   
                    $(($template).properties.displayName),$severity,$found,$(($solution).displayName) -join $CsvSeparatorChar | Out-File $OutputAnalyticRuleTemplatesCsvFile -Append
                    continue #goto next Template in the foreach loop
                }        

                # Create the Analytic Rule from the Template - NOTE: at this point it will have "Source name" = "Gallery Content"
                Write-Verbose "Template '$(($template).properties.displayName)' - About to create rule"
                $analyticRule = CreateAnalyticRule -BaseUri $baseUri -Template $template -SimulateOnly $SimulateOnly
                #Write-Debug "analyticRule: $analyticRule"
                "Template '$(($template).properties.displayName)' - Rule created sucessfully"  | Out-File $oLogFile -Append
                
                if($SimulateOnly){
                    # Simulate the result of the above command (it is needed in order to simulate the following command)
                    Write-Verbose "Template '$(($template).properties.displayName)' - SIMULATED - Creating a fake rule"
                    $analyticRule = New-Object -TypeName PSObject -Property @{
                        name = ""
                        id = ""
                        displayName = $template.properties.mainTemplate.resources.properties[0].displayName
                    }                    
                }

                # Modify the metadata of the Analytic Rule so that it is linked as "In use" in the Solution - NOTE: at this point it will have "Source name" = <Name of the solution>
                Write-Verbose "Template '$(($template).properties.displayName)' - About to modify metadata"
                $metadataChangeResult = LinkAnalyticRuleToSolution -BaseUri $baseUri -Rule $analyticRule -Template $template -Solution $solution -SimulateOnly $SimulateOnly
                #Write-Debug "metadataChangeResult: $metadataChangeResult"
                "Template '$(($template).properties.displayName)' - Metadata modified successfully"  | Out-File $oLogFile -Append

                $NumberOfCreatedRules++ | out-null
            }
            catch {
                "Template '$(($template).properties.displayName)' - ERROR while creating the rule"  | Out-File $oLogFile -Append
                "-------------"  | Out-File $oLogFile -Append
                $_  | Out-File $oLogFile -Append
                "-------------"  | Out-File $oLogFile -Append
                $NumberOfErrors++ | out-null
            }
            
            if(($LimitToMaxNumberOfRules -gt 0) -and ($NumberOfCreatedRules -ge $LimitToMaxNumberOfRules)){
                break
            }
        } else {
            Write-Verbose "Template skipped (severity: '$severity'): '$(($template).properties.displayName)'" 
            "Template skipped (severity: '$severity'): '$(($template).properties.displayName)'" | Out-File $oLogFile -Append
            $NumberOfSkippedTemplates++ | out-null
        }
    }

    
    Write-Verbose "---------------------- END OF EXECUTION - $(Get-Date)"

    Write-Host (" ") ; " " | Out-File $oLogFile -Append
    Write-Host ("### Summary:") -ForegroundColor Blue; "### Summary:"  | Out-File $oLogFile -Append
    Write-Host ("") -ForegroundColor Blue
    Write-Host ("  # of template processed: $NumberOfConsideredTemplates")  -ForegroundColor Blue; "  # of template processed: $NumberOfConsideredTemplates" | Out-File $oLogFile -Append
    if($SaveExistingAnalyticRuleTemplatesToCsvFile){
        Write-Host ("  # of template processed with errors: $NumberOfErrors")  -ForegroundColor Red; "  # of rules processed with errors: $NumberOfErrors" | Out-File $oLogFile -Append        
    } else { 
        if(-not($SimulateOnly)){
            Write-Host ("  # of rules created: $NumberOfCreatedRules")  -ForegroundColor Green; "  # of rules created: $NumberOfCreatedRules" | Out-File $oLogFile -Append
        } else {        
            Write-Host ("  # of rules created (SIMULATED): $NumberOfCreatedRules")  -ForegroundColor Green; "  # of rules created (SIMULATED): $NumberOfCreatedRules" | Out-File $oLogFile -Append
        }
        Write-Host ("  # of rules not created because of errors: $NumberOfErrors")  -ForegroundColor Red; "  # of rules not created because of errors: $NumberOfErrors" | Out-File $oLogFile -Append
        Write-Host ("  # of templates skipped: $NumberOfSkippedTemplates")  -ForegroundColor Gray; "  # of template skipped: $NumberOfSkippedTemplates" | Out-File $oLogFile -Append
    }
    Write-Host ("") -ForegroundColor Blue
    

    "EXECUTION ENDED - $LogStartTime" | Out-File $oLogFile -Append
    Write-Host "Please check the log file for details: '.\$oLogFile'" -ForegroundColor Blue 

}

<#
###############################################################################
# Launching section - UNCOMMENT AS NEEDED

# Set the environment variables
$SubscriptionId = "<your-subscription-id>"
$ResourceGroup = "<your-sentinel-resource-group-name>"
$Workspace = "<your-sentinel-workspace-name>"
$Region = "<your-region>" #(e.g, westeurope)
$SaveExistingAnalyticRuleTemplatesToCsvFile = $false
$OutputAnalyticRuleTemplatesCsvFile = "<folder-path>\<file-name>.csv"
$CsvSeparatorChar = ';'
$SimulateOnly = $false
$LimitToMaxNumberOfRules = 10
$InputCsvFile = "<folder-path>\<file-name>.csv"
$SeveritiesToInclude = @("High")

Create-AnalyticRulesFromTemplates -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -Workspace $Workspace -Region $Region  `
    -SaveExistingAnalyticRuleTemplatesToCsvFile $SaveExistingAnalyticRuleTemplatesToCsvFile -OutputAnalyticRuleTemplatesCsvFile $OutputAnalyticRuleTemplatesCsvFile   `
    -CsvSeparatorChar $CsvSeparatorChar -InputCsvFile $InputCsvFile `
    -SeveritiesToInclude $SeveritiesToInclude -Simulate $SimulateOnly  -LimitToMaxNumberOfRules $LimitToMaxNumberOfRules #-verbose

#>
