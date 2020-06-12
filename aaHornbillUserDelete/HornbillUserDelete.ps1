
<#PSScriptInfo

.VERSION 1.1.0

.GUID 5b0dd3da-ab0d-437c-8933-04ef00d1f547

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Removed requirement to provide instanceZone param

.DESCRIPTION
 Azure Automation Runbook to delete a user from a Hornbill instance.

#>

#Requires -Module @{ModuleName = 'HornbillAPI'; ModuleVersion = '1.1.0'}
#Requires -Module @{ModuleName = 'HornbillHelpers'; ModuleVersion = '1.1.1'}

workflow Hornbill_UserDelete_Workflow
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
        [string] $userId
    )
    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build XMLMC Call
    Add-HB-Param "userId" $userId $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "admin" "userDelete"

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