
<#PSScriptInfo

.VERSION 1.1.0

.GUID b7d13e96-b287-46bf-b12f-ba6a5f5e1cb6

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to add roles to a user on a Hornbill instance.

#>

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

workflow Hornbill_UserAddRoles_Workflow
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
        [string] $roles
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build array of roles
    $arrRoles = $roles.split('|')

    # Build XMLMC Call
    Add-HB-Param "userId" $userId $false
    foreach ($role in $arrRoles){
        Add-HB-Param "role" $role $false
    }

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "admin" "userAddRole"

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