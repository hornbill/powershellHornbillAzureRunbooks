##############################
#.SYNOPSIS
#Azure Powershell Workflow Runbook to update the details of a request within Service Manager on a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow Runbook to update the details of a request within Service Manager on a Hornbill Instance
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER requestReference
#MANDATORY: The request reference ID
#
#.PARAMETER summary
#Request Summary
#
#.PARAMETER description
#Request Description
#
#.PARAMETER categoryCode
#Request Category Code
#
#.PARAMETER siteName
#Request Site Name
#
#.PARAMETER externalReference
#External reference number
#
#.PARAMETER customFields
#A JSON representation of the custom fields for a request
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
# - HornbillHelpers
###############################
workflow Hornbill_RequestUpdateDetails_Workflow
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
        [Parameter (Mandatory= $true)]
        [string] $requestId,
        [string] $summary,
        [string] $description,
        [string] $categoryCode,
        [string] $siteName,
        [string] $externalReference,
        [string] $customFields
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Get Site ID from Name
    $siteId = ""
    if($siteName -and $siteName -ne ""){
        $siteObj = Get-HB-SiteID $siteName
        if($siteObj -and $siteObj.SiteID -and $siteObj.SiteID -ne ""){
            $siteId = $siteObj.SiteID
        }
    } 

    # Get Category ID and Fullname from Code
    $categoryId = ""
    $categoryName = ""
    if($categoryCode -and $categoryCode -ne "") {
        # Go get the category name and ID
        Add-HB-Param "codeGroup" "Request"
        Add-HB-Param "code" $categoryCode
        $xmlmcCodeOutput = Invoke-HB-XMLMC "data" "profileCodeLookup"
        if($xmlmcCodeOutput.status -eq "ok" -and $xmlmcCodeOutput.params){
            $categoryId = $xmlmcCodeOutput.params.id
            $categoryName = $xmlmcCodeOutput.params.fullname
        }
    }

    # Empty JSON string for Custom Fields required as a minimum
    $customFieldsJSON = "{}"
    if($customFields -and $customFields -ne ""){
        $customFieldsJSON = $customFields
    }

    # Build XMLMC call
    Add-HB-Param "requestId" $requestId $false
    Add-HB-Param "h_summary" $summary $false
    Add-HB-Param "h_description" $description $false
    Add-HB-Param "h_category" $categoryName $false
    Add-HB-Param "h_category_id" $categoryId $false
    Add-HB-Param "h_site" $siteName $false
    Add-HB-Param "h_site_id" $siteId $false
    Add-HB-Param "h_external_ref_number" $externalReference $false
    Add-HB-Param "customFields" $customFieldsJSON $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.servicemanager/Requests" "update"

    $exceptionName = ""
    $exceptionSummary = ""
    # Read output status
    if($xmlmcOutput.status -eq "ok" -and $xmlmcOutput.params -and $xmlmcOutput.params.exceptionName -and $xmlmcOutput.params.exceptionName -ne "") {
        $exceptionName = $xmlmcOutput.params.exceptionName
        $exceptionSummary = $xmlmcOutput.params.exceptionDescription
    }

    # Build resultObject to write to output 
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        ExceptionName = $exceptionName
        ExceptionSummary = $exceptionSummary
    }
    
    if($resultObject.Status -ne "ok" -or $exceptionName -ne ""){
        Write-Error $resultObject
    } else {
        Write-Output $resultObject
    }
}