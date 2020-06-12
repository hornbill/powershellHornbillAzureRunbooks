
<#PSScriptInfo

.VERSION 1.1.0

.GUID e38e533f-80d4-4103-a384-868791829d49

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation webhook runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to create a post on a workspace on a Hornbill instance. For use with Automation Webhooks.

#>

#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.

#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.

#.PARAMETER WebhookData
# MANDATORY: A properly formatted JSON string containing the following properties:
#   workspaceName
#   MANDATORY: The name of the workspace to post to
#   postContent
#   MANDATORY: The post content 
#   visibility
#   The post visibility, default is public
#   imageUrl
#   The URL of an image to attach to the post

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

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
        $searchResultsValue = ConvertTo-Json $requestObject.SearchResults.value
    }

    # Get Activity Stream ID for Workspace
    $activityStreamObj = Get-HB-WorkspaceID $requestObject.workspaceName
    $activityStreamID = $activityStreamObj.ActivityStreamID
    $content = $requestObject.postContent
    $content += $searchResultsValue

    Add-HB-Param "activityStreamId" $activityStreamID $false
    Add-HB-Param "content" $content $false
    Add-HB-Param "visibility" $requestObject.visibility $false
    Add-HB-Param "imageUrl" $requestObject.imageUrl $false
    Add-HB-Param "filterType" "update" $false
    Add-HB-Param "activityType" "post" $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.core" "updateActivityStream"

    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        $activityID = $xmlmcOutput.params.activityId
    }

    # Build resultObject to write to output
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        ActivityId = $activityID
    }

	if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
		Write-Output $resultObject
    }
} else {
    Write-Error "This Runbook is designed to only be started from a Webhook"
}
