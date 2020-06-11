##############################
#.SYNOPSIS
#Azure Powershell Workflow Runbook to create a new workspace on a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow Runbook to create a new workspace on a Hornbill Instance
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER displayName
#MANDATORY: The workspaces display name/title.
#
#.PARAMETER title
#MANDATORY: Set the title/short description of this workspace
#
#.PARAMETER visibility
#Limits the visibility to the specified visibility group: public, closed or private (default)
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
##############################
workflow Hornbill_WorkspaceCreate_Workflow
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
        [string] $displayName, 
        [Parameter (Mandatory= $true)]
        [string] $title, 
        [string] $visibility
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    Add-HB-Param "displayName" $displayName $false
    Add-HB-Param "title" $title $false
    Add-HB-Param "visibility" $visibility $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "activity" "workspaceCreate"

    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        $activityStreamID = $xmlmcOutput.params.activityStreamID
    }

    # Build resultObject to write to output 
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        ActivityStreamID = $activityStreamID
    }
    
	if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
		Write-Output $resultObject
    }
}