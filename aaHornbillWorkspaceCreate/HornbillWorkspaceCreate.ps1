
<#PSScriptInfo

.VERSION 1.1.0

.GUID 155d130e-ad61-4a77-a9e1-c867ea4bc221

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to createa a workspace on a Hornbill instance.

#>

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

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