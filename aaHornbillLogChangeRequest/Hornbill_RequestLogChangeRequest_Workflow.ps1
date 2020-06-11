##############################
#.SYNOPSIS
#Azure Powershell Workflow Runbook to log a new Change Request within Service Manager on a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow Runbook to log a new Change Request within Service Manager on a Hornbill Instance
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER assetIds
#A comma-seperated string of asset IDs to attach to the new request, for example: 1,12,36
#
#.PARAMETER bpmName
#The name of a BPM to override the Service BPM or Default BPM.
#
#.PARAMETER catalogName
#The title of the catalog to raise thew request against
#
#.PARAMETER categoryId
#The ID of the request category
#
#.PARAMETER categoryName
#The fullname of the request category
#
#.PARAMETER changeType
#The Change Type (Standard, Emergency for example)
#
#.PARAMETER customerId
#The ID of the request customer
#
#.PARAMETER customerType
#The Type of the request customer (0 for Users, 1 for contacts)
#
#.PARAMETER description
#The request description
#
#.PARAMETER ownerId
#The ID of the request owner
#
#.PARAMETER priorityName
#The name of the request Priority
#
#.PARAMETER resolutionDetails
#The resolution description
#
#.PARAMETER serviceName
#The name of the service to raise the request against
#
#.PARAMETER siteName
#The name of the request site
#
#.PARAMETER sourceId
#The ID of the request source
#
#.PARAMETER sourceType
#The Type of request source
#
#.PARAMETER status
#The status of the new request (defaults to status.open)
#
#.PARAMETER summary
#The request summary
#
#.PARAMETER teamId
#The ID of the team that the request should be assigned to
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
# - HornbillHelpers
###############################
workflow Hornbill_RequestLogChangeRequest_Workflow
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
        [string] $changeType, 
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
        $catalogObj = Get-HB-CatalogID $catalogName $serviceName "Change Request"
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
    Add-HB-Param "changeType" $changeType $false
    Add-HB-Param "siteId" $siteId $false
    Add-HB-Param "siteName" $siteName $false
    Add-HB-Param "catalogId" $catItemId $false
    Add-HB-Param "catalogName" $catalogName $false
    Add-HB-Param "bpmName" $bpmName $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.servicemanager/ChangeRequests" "logChangeRequest"

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