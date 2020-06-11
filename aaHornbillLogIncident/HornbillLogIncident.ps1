
<#PSScriptInfo

.VERSION 1.1.0

.GUID 0d4a0fb1-5429-4a69-8e13-db2d8d330a7c

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION 
 Azure Automation Runbook to log a new Incident within Service Manager on a Hornbill instance. 

#>

#Requires -Module @{ModuleVersion = '1.1.0'; ModuleName = 'HornbillAPI'}
#Requires -Module @{ModuleVersion = '1.1.1'; ModuleName = 'HornbillHelpers'}

workflow Hornbill_RequestLogIncident_Workflow
{
    # Define output stream type
    [OutputType([object])]

    # Define runbook input params
    Param
    (
        # Instance Connection Params
        [Parameter (Mandatory= $true)]
        [string] $instanceName,
        [Parameter (Mandatory= $true)]
        [string] $instanceKey,

        # API Params
        [string] $assetIds, 
        [string] $bpmName, 
        [string] $catalogName, 
        [string] $categoryId, 
        [string] $categoryName, 
        [string] $customerId, 
        [string] $customerType, 
        [string] $description, 
        [string] $ownerId, 
        [string] $priorityName, 
        [string] $resolutionDetails, 
        [string] $serviceName, 
        [string] $siteName, 
        [string] $sourceId, 
        [string] $sourceType, 
        [string] $status, 
        [string] $summary, 
        [string] $teamId
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Get service ID from Name
    $serviceId = ""
    if($serviceName -and $serviceName -ne ""){
        $serviceObj = Get-HB-ServiceID $serviceName
        if($serviceObj.ServiceID -gt 0) {
            $serviceId = $serviceObj.ServiceID
        }
    }

    # Get Priority ID from Name
    $priorityId = ""
    if($priorityName -and $priorityName -ne ""){
        $priorityObj = Get-HB-PriorityID $priorityName
        if($priorityObj.PriorityID -gt 0) {
            $priorityId = $priorityObj.PriorityID
        }
    }

    # Get Catalog ItemID from Name
    $catItemId = ""
    if($catalogName -and $catalogName -ne ""){
        $catalogObj = Get-HB-CatalogID $catalogName $serviceName "Incident"
        if($catalogObj.CatalogID -gt 0) {
            $catItemId = $catalogObj.CatalogID
        }
    }

    # Get SiteID from Name
    $siteId = ""
    if($siteName -and $siteName -ne "") {
        $siteObj = Get-HB-SiteID $siteName
        $siteId = $siteObj.SiteID
    }

    # Populate status if null
    if(-not $status -or $status -eq "") {
        $status = "status.open"
    }

    Add-HB-Param "summary" $summary $false
    Add-HB-Param "description" $description $false
    Add-HB-Param "customerId" $customerId $false
    Add-HB-Param "customerType" $customerType $false
    Add-HB-Param "ownerId" $ownerId $false
    Add-HB-Param "teamId" $teamId $false
    Add-HB-Param "status" $status $false
    Add-HB-Param "priorityId" $priorityId $false
    Add-HB-Param "categoryId" $categoryId $false
    Add-HB-Param "categoryName" $categoryName $false
    Add-HB-Param "sourceType" $sourceType $false
    Add-HB-Param "sourceId" $sourceId $false

    # Process Assets
    if($assetIds){
        $arrAssets = $assetIds.replace(' ','').split(',')
        foreach ($asset in $arrAssets) {
            Add-HB-Param "assetId" $asset $false
        }
    }
    
    Add-HB-Param "serviceId" $serviceId $false
    Add-HB-Param "resolutionDetails" $resolutionDetails $false
    Add-HB-Param "siteId" $siteId $false
    Add-HB-Param "siteName" $siteName $false
    Add-HB-Param "catalogId" $catItemId $false
    Add-HB-Param "catalogName" $catalogName $false
    Add-HB-Param "bpmName" $bpmName $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.servicemanager/Incidents" "logIncident"

    $exceptionName = ""
    $exceptionSummary = ""
    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        if($xmlmcOutput.params.requestId -and $xmlmcOutput.params.requestId -ne ""){
            $requestRef = $xmlmcOutput.params.requestId
            $requestWarnings = $xmlmcOutput.params.warnings
        }
        if($xmlmcOutput.params.exceptionName -and $xmlmcOutput.params.exceptionName -ne ""){
            $exceptionName = $xmlmcOutput.params.exceptionName
            $exceptionSummary = $xmlmcOutput.params.exceptionDescription
        }
    }
    # Build resultObject to write to output 
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        RequestRef = $requestRef
        Warnings = $requestWarnings
        ExceptionName = $exceptionName
        ExceptionSummary = $exceptionSummary
    }
    
    if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
        if($exceptionName -ne ""){
            Write-Warning $resultObject
        } else {
            Write-Output $resultObject
        }
    }
}