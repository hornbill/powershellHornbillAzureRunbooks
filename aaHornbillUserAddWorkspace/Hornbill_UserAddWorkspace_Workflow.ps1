##############################
#.SYNOPSIS
#Azure Powershell Workflow runbook to add a user to a workspace within a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow runbook to add a user to a workspace within a Hornbill Instance
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER userId
#MANDATORY: The ID of the user
#
#.PARAMETER workspaceName
#MANDATORY: The name of the workspace
#
#.PARAMETER description
#A description of the users role within the workspace
#
#.PARAMETER announceMembership
#Boolean true/false - should the user being added to the workspace be announced on the workspace
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
# - HornbillHelpers
##############################
workflow Hornbill_UserAddWorkspace_Workflow
{
    # Define Output Stream Type
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
        [string] $userId,
        [Parameter (Mandatory= $true)]
        [string] $workspaceName,
        [string] $description,
        [boolean] $announceMembership
    )
    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build URN for user
    $newMemberRef = "urn:sys:user:"
    $newMemberRef += $userId

    # Get Activity Stream ID for Workspace
    $workspaceObject = Get-HB-WorkspaceID $workspaceName

    $announce = "false"
    if($announceMembership -eq $true){
        $announce = "true"
    }

    # Build XMLMC Call
    Add-HB-Param "activityStreamID" $workspaceObject.ActivityStreamID $false
    Add-HB-Param "newMemberRef" $newMemberRef $false
    Add-HB-Param "description" $description $false
    Add-HB-Param "announceMembership" $announce $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "activity" "workspaceAddMember"
    
    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        if($xmlmcOutput.params.announcementActivityID){
            $activityId = $xmlmcOutput.params.announcementActivityID
        }
    }
    
    # Build resultObject to write to output 
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        AnnouncementActivityID = $activityId
    }
    
	if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
		Write-Output $resultObject
    }
}