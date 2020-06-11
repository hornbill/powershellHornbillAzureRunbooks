##############################
#.SYNOPSIS
#Azure Powershell Workflow Runbook to create a new user account on a Hornbill Instance
#
#.DESCRIPTION
#Azure Powershell Workflow Runbook to create a new user account on a Hornbill Instance
#
#.PARAMETER instanceName
#MANDATORY: The name of the Instance to connect to.
#
#.PARAMETER instanceKey
#MANDATORY: An API key with permission on the Instance to carry out the required API calls.
#
#.PARAMETER userId
#MANDATORY: The user ID
#
#.PARAMETER name
#MANDATORY: The users fullname (handle)
#
#.PARAMETER password
#MANDATORY: The users password
#
#.PARAMETER userType
#The type of user (basic or user)
#
#.PARAMETER firstName
#The users firstname
#
#.PARAMETER lastName
#The users surname
#
#.PARAMETER jobTitle
#The users job title
#
#.PARAMETER siteName
#The users site name
#
#.PARAMETER phone
#The users phone number
#
#.PARAMETER email
#The users email address
#
#.PARAMETER mobile
#The users mobile or secondary phone number
#
#.PARAMETER availabilityStatus
#The users availability status
#
#.PARAMETER absenceMessage
#The users current absence message
#
#.PARAMETER timeZone
#The users timezone (taken from the instance default if not specified)
#
#.PARAMETER language
#The users language (taken from the instance default if not specified)
#
#.PARAMETER dateTimeFormat
#The users preferred datetime format (taken from the instance default if not specified)
#
#.PARAMETER dateFormat
#The users preferred date format (taken from the instance default if not specified)
#
#.PARAMETER timeFormat
#The users preferred time format (taken from the instance default if not specified)
#
#.PARAMETER currencySymbol
#The users local currency symbol (taken from the instance default if not specified)
#
#.PARAMETER countryCode
#The users country code (taken from the instance default if not specified)
#
#.NOTES
#Modules required to be installed on the Automation Account this runbook is called from:
# - HornbillAPI
# - HornbillHelpers
##############################
workflow Hornbill_UserCreate_Workflow
{
    #Define Output Stream Type
    [OutputType([object])]
    
    # Define runbook input params
    Param
    (
        # Instance connection params
        [Parameter (Mandatory= $true)]
        [string] $instanceName,
        [Parameter (Mandatory= $true)]
        [string] $instanceKey,

        # API Params
        [Parameter (Mandatory= $true)]
        [string] $userId,
        [Parameter (Mandatory= $true)]
        [string] $name,
        [Parameter (Mandatory= $true)]
        [string] $password,
        [string] $userType,
        [string] $firstName,
        [string] $lastName,
        [string] $jobTitle,
        [string] $siteName,
        [string] $phone,
        [string] $email,
        [string] $mobile,
        [string] $availabilityStatus,
        [string] $absenceMessage,
        [string] $timeZone,
        [string] $language,
        [string] $dateTimeFormat,
        [string] $dateFormat,
        [string] $timeFormat,
        [string] $currencySymbol,
        [string] $countryCode
    )
    
    # Define instance details
    Set-HB-Instance -Instance $instanceName -Key $instanceKey

    #  Base64 encode password string
    $pwdb64 = ConvertTo-HB-B64Encode $password

    # Get SiteID from Name
    $siteId = ""
    if($siteName -and $siteName -ne "") {
        $siteObj = Get-HB-SiteID $siteName
        $siteId = $siteObj.SiteID
    }

    Add-HB-Param "userId" $userId $false
    Add-HB-Param "name" $name $false
    Add-HB-Param "password" $pwdb64 $false
    Add-HB-Param "userType" $userType $false
    Add-HB-Param "firstName" $firstName $false
    Add-HB-Param "lastName" $lastName $false
    Add-HB-Param "jobTitle" $jobTitle $false
    Add-HB-Param "site" $siteId $false
    Add-HB-Param "phone" $phone $false
    Add-HB-Param "email" $email $false
    Add-HB-Param "mobile" $mobile $false
    Add-HB-Param "availabilityStatus" $availabilityStatus $false
    Add-HB-Param "absenceMessage" $absenceMessage $false
    Add-HB-Param "timeZone" $timeZone $false
    Add-HB-Param "language" $language $false
    Add-HB-Param "dateTimeFormat" $dateTimeFormat $false
    Add-HB-Param "dateFormat" $dateFormat $false
    Add-HB-Param "timeFormat" $timeFormat $false
    Add-HB-Param "currencySymbol" $currencySymbol $false
    Add-HB-Param "countryCode" $countryCode $false

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-HB-XMLMC "admin" "userCreate"
    
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