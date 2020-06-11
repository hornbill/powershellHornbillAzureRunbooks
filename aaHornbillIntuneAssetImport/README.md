# Hornbill Intune Mobile Asset Import - Azure Automation Powershell Runbook

## Description

This is an Azure Automation Powershell Runbook which will retrieve mobile assets from Intune, and import them into your Hornbill instance CMDB.

## Requirements

Requires the HornbillAPI (v1.1.0 or above), HornbillHelpers (v1.1.1 or above), AzureAD and PSIntuneAuth modules to be installed against your Azure Automation Account. These can be installed via the PowershellGallery:

<https://www.powershellgallery.com/packages/HornbillAPI/>

<https://www.powershellgallery.com/packages/HornbillHelpers/>

The script requires you to create an Azure AD App Registration for accessing the Microsoft Intune Graph API, instructions can be found: <https://www.scconfigmgr.com/2017/08/03/create-an-azure-ad-app-registration-for-accessing-microsoft-intune-graph-api-with-powershell/>

You will also need to create an Automation Credential to contain account details to generate an access token, and Automation Variables to hold:

- The Client ID for the Azure AD App Registration
- Your Hornbill Instance ID
- An API key for a user on your Hornbill instance

Once these have been created, you can then populate the AutomationCred, AutomationVar, APIKey and InstanceID variables with the names of these credentials/variables.

## Documentation

<https://wiki.hornbill.com/index.php/Microsoft_Azure_And_OMS_Integration>

## License

<https://wiki.hornbill.com/index.php/The_Hornbill_Community_License_(HCL)>
