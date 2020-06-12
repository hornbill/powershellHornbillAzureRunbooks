
<#PSScriptInfo

.VERSION 1.1.0

.GUID f0d886e9-d349-4a28-aa33-d5773088949d

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to add a user to a group on a Hornbill instance.

#>

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

workflow Hornbill_UserAddGroup_Workflow
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
        [string] $groupId,
        [Parameter (Mandatory= $true)]
        [string] $memberRole,
        [boolean] $tasksView,
        [boolean] $tasksAction
    )
    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build XMLMC Call
    Add-HB-Param "userId" $userId $false
    Add-HB-Param "groupId" $groupId $false
    Add-HB-Param "memberRole" $memberRole $false
    if($tasksView -eq $true -or $tasksAction -eq $true){
        Open-HB-Element "options"
        if($tasksView -eq $true){
            Add-HB-Param "tasksView" "true"
        }
        if($tasksAction -eq $true){
            Add-HB-Param "tasksAction" "true"
        }
        Close-HB-Element "options"
    }

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "admin" "userAddGroup"

    # Build resultObject to write to output
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
    }

	if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
		Write-Output $resultObject
    }
}