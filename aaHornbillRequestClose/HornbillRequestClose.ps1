
<#PSScriptInfo

.VERSION 1.1.1

.GUID c31618d5-5afb-4913-a4a3-191650c326fb

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Corrected metadata
Included parameter descriptions

.DESCRIPTION
 Azure Automation Runbook to close a Request within Service Manager on a Hornbill instance.

#>

#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.

#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.

#.PARAMETER requestReference
#MANDATORY: The request reference ID

#.PARAMETER closureText
#MANDATORY: The closure text string

#.PARAMETER updateVisibility
#The visibility of the closure timeline update. Defaults to "trustedGuest"

#.PARAMETER closureCategoryId
#The closure category code

#.PARAMETER closureCategoryName
#The closure category full name

#Requires -Module @{ModuleVersion = '1.1.0'; ModuleName = 'HornbillAPI'}
#Requires -Module @{ModuleVersion = '1.1.1'; ModuleName = 'HornbillHelpers'}

workflow Hornbill_RequestClose_Workflow
{
    #Define Output Type
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
        [string] $requestReference,
        [Parameter (Mandatory= $true)]
        [string] $closureText,
        [string] $updateVisibility = "trustedGuest",
        [string] $closureCategoryId,
        [string] $closureCategoryName
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build timeline update JSON
    $timelineUpdate = '{"requestId":"'+$requestReference+'",'
    if($null -eq $closureCategoryName -or $closureCategoryName -eq ''){
        $timelineUpdate += '"updateText":"Request has been closed:\n\n'+ $closureText+'",'
    } else {
        $timelineUpdate += '"updateText":"Request has been closed with the category: '+$closureCategoryName+'\n\n'+ $resolutionText+'",'
    }
    $timelineUpdate += '"activityType":"Resolve",'
    $timelineUpdate += '"source":"webclient",'
    $timelineUpdate += '"postType":"Resolve",'
    $timelineUpdate += '"visiblity":"'+$updateVisibility+'"}'

    # Add XMLMC params
    Add-HB-Param "requestId" $requestReference $false
    Add-HB-Param "closeText" $closureText $false
    Add-HB-Param "closureCategoryId" $closureCategoryId $false
    Add-HB-Param "closureCategoryName" $closureCategoryName $false
    Add-HB-Param "updateTimelineInputs" $timelineUpdate $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.servicemanager/Requests" "closeRequest"

    $exceptionName = ""
    $exceptionSummary = ""
    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        if($xmlmcOutput.params.activityId -and $xmlmcOutput.params.activityId -ne ""){
            $activityId = $xmlmcOutput.params.activityId
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
        ActivityId = $activityId
        ExceptionName = $exceptionName
        ExceptionSummary = $exceptionSummary
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
}