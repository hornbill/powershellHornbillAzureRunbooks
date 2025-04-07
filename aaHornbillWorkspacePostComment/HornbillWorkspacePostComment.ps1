
<#PSScriptInfo

.VERSION 1.1.0

.GUID f3c65edc-e04f-4fd2-93f4-82a935ba5398

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to add a comment to a post on a workspace on a Hornbill instance.

#>

#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.

#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.

#.PARAMETER activityId
#MANDATORY: The activity ID of the Post you are commenting on

#.PARAMETER commentContent
#MANDATORY: The content of the comment

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

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
        $commentID = $xmlmcOutput.params.comment.id
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
