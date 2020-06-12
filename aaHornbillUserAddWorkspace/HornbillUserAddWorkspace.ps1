
<#PSScriptInfo

.VERSION 1.1.0

.GUID 95fd86ba-3fc6-4de6-939f-270c510bc8bc

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to add a user to a workspace on a Hornbill instance.

#>

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

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