##############################
#.SYNOPSIS
#Azure Powershell Runbook to archive a contact on a Hornbill Instance.
#
#.DESCRIPTION
#Azure Powershell Runbook to archive a contact on a Hornbill Instance.
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER contactId
#MANDATORY: The ID (primary key) of the contact you wish to archive
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
###############################
workflow Hornbill_ContactArchive_Workflow
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
        [string] $contactId
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build XMLMC call
    Add-HB-Param "h_pk_id" $contactId $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.core/Contact" "archiveContact"

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