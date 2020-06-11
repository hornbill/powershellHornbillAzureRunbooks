##############################
#.SYNOPSIS
#Azure Powershell Workflow Runbook to add a comment to a post in an activity stream on a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow Runbook to add a comment to a post in an activity stream on a Hornbill Instance
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER activityId
#MANDATORY: The activity ID of the Post you are commenting on
#
#.PARAMETER commentContent
#MANDATORY: The content of the comment
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
# - HornbillHelpers
##############################
workflow Hornbill_WorkspacePostComment_Workflow
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
        [string] $activityId, 
        [Parameter (Mandatory= $true)]
        [string] $commentContent
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    Add-HB-Param "activityId" $activityId $false
    Add-HB-Param "comment" $commentContent $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "activity" "activityPostComment"

    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        $commentID = $xmlmcOutput.params.commentID
    }

    # Build resultObject to write to output 
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        CommentID = $commentID
    }
    
	if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
		Write-Output $resultObject
    }
}