##############################
#.SYNOPSIS
#Azure Powershell Runbook to add a post to a workspace on a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Runbook to add a post to a workspace on a Hornbill Instance
#This runbook should only be fired using a properly configured Azure Webhook
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER WebhookData
#MANDATORY: A properly formatted JSON string containing the request parameters. 
#See the Hornbill_WorkspacePost_Workflow runbook for the available parameters.
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
# - HornbillHelpers
##############################
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
