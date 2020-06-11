##############################
#.SYNOPSIS
#Azure Powershell Workflow runbook to add one or more roles to a user within a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow runbook to add one or more roles to a user within a Hornbill Instance
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
#.PARAMETER roles
#MANDATORY: A pipe-seperated list of role names, for example: Collaboration Role|Service Desk Admin|Change Manager
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
##############################
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