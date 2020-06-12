
<#PSScriptInfo

.VERSION 1.1.0

.GUID 80ca86d1-d36f-4e2b-ac9a-679e3c78605c

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to post on a workspace on a Hornbill instance.

#>

#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.

#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.

#.PARAMETER workspaceName
#MANDATORY: The name of the workspace to post to

#.PARAMETER postContent
#MANDATORY: The post content

#.PARAMETER visibility
#The post visibility, default is public

#.PARAMETER imageUrl
#The URL of an image to attach to the post

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

workflow Hornbill_WorkspacePost_Workflow
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
        [string] $workspaceName,
        [Parameter (Mandatory= $true)]
        [string] $postContent,
        [string] $visibility,
        [string] $imageUrl
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Get Activity Stream ID for Workspace
    $activityStreamObj = Get-HB-WorkspaceID $workspaceName
    $activityStreamID = $activityStreamObj.ActivityStreamID

    Add-HB-Param "activityStreamId" $activityStreamID $false
    Add-HB-Param "content" $postContent $false
    Add-HB-Param "visibility" $visibility $false
    Add-HB-Param "imageUrl" $imageUrl $false
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
}