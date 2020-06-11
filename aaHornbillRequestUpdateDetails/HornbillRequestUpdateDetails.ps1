
<#PSScriptInfo

.VERSION 1.1.0

.GUID 27e65a65-60b4-4196-86ef-9e0db3f49026

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to update the details of a Request within Service Manager on a Hornbill instance.

#>

#Requires -Module @{ModuleVersion = '1.1.0'; ModuleName = 'HornbillAPI'}
#Requires -Module @{ModuleVersion = '1.1.1'; ModuleName = 'HornbillHelpers'}

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