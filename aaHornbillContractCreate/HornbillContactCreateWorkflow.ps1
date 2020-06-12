
<#PSScriptInfo

.VERSION 1.1.1

.GUID 2eb1e8f8-9628-4a3e-92ce-4c1e17133ea9

.AUTHOR steve.goldthorpe@hornbill.com

.COMPANYNAME Hornbill

.TAGS hornbill powershell azure automation workflow runbook

.LICENSEURI https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)

.PROJECTURI https://github.com/hornbill/powershellHornbillAzureRunbooks

.ICONURI https://wiki.hornbill.com/skins/common/images/HBLOGO.png

.RELEASENOTES
Included parameter descriptions

.DESCRIPTION
 Azure Automation Runbook to create a contact record on a Hornbill instance.

#>

#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.

#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.

#.PARAMETER h_firstname
#MANDATORY: Contact firstname

#.PARAMETER h_lastname
#MANDATORY: Contact surname

#.PARAMETER organisationName
#Name of the organisation that this contact belongs to. The organisation must aready exist in your Hornbill instance

#.PARAMETER h_jobtitle
#Contact job title

#.PARAMETER h_tel_1
#Contact primary phone number

#.PARAMETER h_tel_2
#Contact secondary phone number

#.PARAMETER h_email_1
#Contact primary email

#.PARAMETER h_email_2
#Contact secondary email

#.PARAMETER h_description
#Contact description

#.PARAMETER h_country
#Contact country code

#.PARAMETER h_language
#Contact language code

#.PARAMETER h_owner
#MANDATORY: Contact owner account ID

#.PARAMETER h_notes
#Contact notes

#.PARAMETER h_private
#Contact mark as private (true or false)

#.PARAMETER h_custom_1
#Contact custom field

#.PARAMETER h_custom_2
#Contact custom field

#.PARAMETER h_custom_3
#Contact custom field

#.PARAMETER h_custom_4
#Contact custom field

#.PARAMETER h_custom_5
#Contact custom field

#.PARAMETER h_custom_6
#Contact custom field

#Requires -Module @{ModuleVersion = '1.1.0'; ModuleName = 'HornbillAPI'}
#Requires -Module @{ModuleVersion = '1.1.1'; ModuleName = 'HornbillHelpers'}

workflow Hornbill_ContactCreate_Workflow
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
        [string] $h_firstname,
        [Parameter (Mandatory= $true)]
        [string] $h_lastname,
        [Parameter (Mandatory= $true)]
        [string] $h_owner,
        [string] $organisationName,
        [string] $h_jobtitle,
        [string] $h_tel_1,
        [string] $h_tel_2,
        [string] $h_email_1,
        [string] $h_email_2,
        [string] $h_description,
        [string] $h_country,
        [string] $h_language,
        [string] $h_notes,
        [string] $h_private,
        [string] $h_custom_1,
        [string] $h_custom_2,
        [string] $h_custom_3,
        [string] $h_custom_4,
        [string] $h_custom_5,
        [string] $h_custom_6
    )

    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    # Build XMLMC call
    Add-HB-Param "h_firstname"		$h_firstname	$false
    Add-HB-Param "h_lastname"		$h_lastname		$false
    Add-HB-Param "h_jobtitle"		$h_jobtitle		$false
    Add-HB-Param "h_tel_1"			$h_tel_1		$false
    Add-HB-Param "h_tel_2"			$h_tel_2		$false
    Add-HB-Param "h_email_1"		$h_email_1		$false
    Add-HB-Param "h_email_2"		$h_email_2		$false
    Add-HB-Param "h_description"	$h_description	$false
    Add-HB-Param "h_country" 		$h_country		$false
    Add-HB-Param "h_language" 		$h_language		$false
    Add-HB-Param "h_owner" 			$h_owner		$false
    Add-HB-Param "h_notes" 			$h_notes		$false
    Add-HB-Param "h_private" 		$h_private		$false
    Add-HB-Param "h_custom_1" 		$h_custom_1		$false
    Add-HB-Param "h_custom_2" 		$h_custom_2		$false
    Add-HB-Param "h_custom_3" 		$h_custom_3		$false
    Add-HB-Param "h_custom_4" 		$h_custom_4		$false
    Add-HB-Param "h_custom_5" 		$h_custom_5		$false
    Add-HB-Param "h_custom_6" 		$h_custom_6		$false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "apps/com.hornbill.core/Contact" "addContactNew"

    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        $NewContactID = $xmlmcOutput.params.h_pk_id
    }

    # Build resultObject to write to output
    $resultObject = New-Object PSObject -Property @{
        Status = $xmlmcOutput.status
        Error = $xmlmcOutput.error
        ContactID = $NewContactID
    }

    if($NewContactID -and $NewContactID -ne "" -and $organisationName -and $organisationName -ne "") {
        $OrgObj = Get-HB-OrganisationID $organisationName
        if($OrgObj -and $OrgObj.OrganisationID -and $OrgObj.OrganisationID -ne ""){
            Add-HB-Param "contactId" $NewContactID
            Add-HB-Param "orgId" $OrgObj.OrganisationID
            $xmlmcOutputAddOrg = Invoke-HB-XMLMC "apps/com.hornbill.core/Contact" "changeOrg"
            if($xmlmcOutputAddOrg.status -ne "ok"){
                # Build resultObject to write to output
                $resultObject = New-Object PSObject -Property @{
                    Status = $xmlmcOutput.status
                    Error = $xmlmcOutput.error
                    ContactID = $NewContactID
                    Warnings = "Contact added but unable to associate to Organisation: "+$xmlmcOutputAddOrg.error
                }
            }
        }
    }

    if($resultObject.Status -ne "ok"){
        Write-Error $resultObject
    } else {
        Write-Output $resultObject
    }
}