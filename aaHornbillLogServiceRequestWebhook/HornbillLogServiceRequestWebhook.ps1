
<#PSScriptInfo

.VERSION 1.1.0

.GUID 17e53ab0-c181-4edf-b34d-70b622951174

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation webhook runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION 
 Azure Automation Runbook to log a new Service Request within Service Manager on a Hornbill instance. For use with Automation Webhooks.  

#>

#Requires -Module @{ModuleVersion = '1.1.0'; ModuleName = 'HornbillAPI'}
#Requires -Module @{ModuleVersion = '1.1.1'; ModuleName = 'HornbillHelpers'}

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

    # Webhook Param
    [object] $WebhookData
)

if ($null -ne $WebhookData) {
    
    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    $WebhookBody = $WebhookData.RequestBody
    $requestObject = ConvertFrom-Json $WebhookBody
    
    $searchResultsValue = ""
    if($requestObject.SearchResults) {
        $SearchResultsValue = ConvertTo-Json $requestObject.SearchResults.value
    }

    $requestDescription = $requestObject.description
    if($SearchResultsValue -ne ""){
        $requestDescription += "'''Alert Results Value JSON:''' "+$SearchResultsValue 
    }

    # Get service ID from Name
    $serviceId = ""
    if($requestObject.serviceName -and $requestObject.serviceName -ne ""){
        $serviceObj = Get-HB-ServiceID $requestObject.serviceName
        if($serviceObj.ServiceID -gt 0) {
            $serviceId = $serviceObj.ServiceID
        }
    }

    # Get Priority ID from Name
    $priorityId = ""
    if($requestObject.priorityName -and $requestObject.priorityName -ne ""){
        $priorityObj = Get-HB-PriorityID $requestObject.priorityName
        if($priorityObj.PriorityID -gt 0) {
            $priorityId = $priorityObj.PriorityID
        }
    }

    # Get Catalog ItemID from Name
    $catItemId = ""
    if($requestObject.catalogName -and $requestObject.catalogName -ne ""){
        $catalogObj = Get-HB-CatalogID $requestObject.catalogName $requestObject.serviceName "Service Request"
        if($catalogObj.CatalogID -gt 0) {
            $catItemId = $catalogObj.CatalogID
        }
    }

    # Get SiteID from Name
    $siteId = ""
    if($requestObject.siteName -and $requestObject.siteName -ne "") {
        $siteObj = Get-HB-SiteID $requestObject.siteName
        $siteId = $siteObj.SiteID
    }

    # Populate status if null
    $requestStatus = "status.open"
    if($requestObject.status -and $requestObject.status -ne "") {
        $requestStatus = $requestObject.status
    }

    Add-HB-Param "summary" $requestObject.summary $false
    Add-HB-Param "description" $requestDescription $false
    Add-HB-Param "customerId" $requestObject.customerId $false
    Add-HB-Param "customerType" $requestObject.customerType $false
    Add-HB-Param "ownerId" $requestObject.ownerId $false
    Add-HB-Param "teamId" $requestObject.teamId $false
    Add-HB-Param "status" $requestStatus $false
    Add-HB-Param "priorityId" $priorityId $false
    Add-HB-Param "categoryId" $requestObject.categoryId $false
    Add-HB-Param "categoryName" $requestObject.categoryName $false
    Add-HB-Param "sourceType" $requestObject.sourceType $false
    Add-HB-Param "sourceId" $requestObject.sourceId $false

    # Process Assets
    $arrAssets = $requestObject.assetIds.replace(' ','').split(',')
    foreach ($asset in $arrAssets) {
        Add-HB-Param "assetId" $asset $false
    }
    Add-HB-Param "serviceId" $serviceId $false
    Add-HB-Param "resolutionDetails" $requestObject.resolutionDetails $false
    Add-HB-Param "siteId" $siteId $false
    Add-HB-Param "siteName" $requestObject.siteName $false
    Add-HB-Param "catalogId" $catItemId $false
    Add-HB-Param "catalogName" $requestObject.catalogName $false
    Add-HB-Param "bpmName" $requestObject.bpmName $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.servicemanager/ServiceRequests" "logServiceRequest"

    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        RequestRef = ""
        Warnings = ""
        ExceptionName = ""
        ExceptionSummary = ""
    }

    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        if($xmlmcOutput.params.requestId -and $xmlmcOutput.params.requestId -ne ""){
            $resultObject.RequestRef = $xmlmcOutput.params.requestId
            $resultObject.Warnings = $xmlmcOutput.params.warnings
        }
        if($xmlmcOutput.params.exceptionName -and $xmlmcOutput.params.exceptionName -ne ""){
            $resultObject.ExceptionName = $xmlmcOutput.params.exceptionName
            $resultObject.ExceptionSummary = $xmlmcOutput.params.exceptionDescription
        }
    }
    
    if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
        if($resultOutput.ExceptionName -ne ""){
            Write-Warning $resultObject
        } else {
            Write-Output $resultObject
        }
    }

} else {
    Write-Error "This Runbook is designed to only be started from a Webhook"
}