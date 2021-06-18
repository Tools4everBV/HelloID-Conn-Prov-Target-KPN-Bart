# HelloID-Conn-Prov-Target-KPN-Bart

## Status of this connector
  This readme is still a work in progress, The connector itself is intended as the 1.0 release version of the connector template

The *HID-Conn-Prov-Target-KPN-Bart* needs to be **executed on-premises**. Make sure you have **Windows PowerShell 5.1** installed on the server where the **HelloID agent and provisioning** agent are running, and that the *Execute on-premises* switch is toggled on the connector system tab within HelloID.

## Table of contents
- [functional description](#Functional-description)
- [PSModule](#PSModule)
- [Prerequisites](#Prerequisites)
- [Connection settings](#Connection-settings)
- [Contents](#contents)
- [Remarks](#remarks)

## Functional description
- creates, modifies, enables, disables, and deletes accounts in bart
- updates account attributes, user passwords, primary email and aliases. 
- set user types or persona types when creating or modifing accounts
- grant/revoke memberschip of groups and functiongroups.

## PSModule

The connector uses a PowerShell module that must be installed locally. Make sure the entire 'KPNBart' folder, that contains the module, is copied to a directory accessible by the helloid agent.

In the configuration parameters of the target system in helloid, you must specify the full path to the module definition file (KPNBart.psd1), so the HelloId agent can load the module.

### Available functions

To get a list of all available functions within the module: 'Get-Command -Module KPNBart'.

### DLL

The KPN Bart PSModule uses an additional *.DLL (KPNbart/bin/KPNBartConnectedServices.dll) that includes the WSDL. Reason for this is that certain methods (to connector to KPN Bart using specific HTTP bindings) were not available when the WSDL's were loaded directly into PowerShell using the: <New-WebServiceProxy> cmdlet. The C# connector uses these HTTP bindings. Since this is a copy of the C# connector, those bindings are copied.

*Note* make sure to check that this file is not "blocked" by windows when copying from the internet and "unblock" this file in windows if this is the case.

### Module help

All functions in the PSKPNBart module have comment based help. To get help for a specific function: 'Get-Help -Command New-KpNBartUser'.

## Prerequisites

- [ ] KPN Bart PowerShell module

  The KPN Bart PowerShell module must be installed locally. The module can be downloaded directly from the Github repository.

- [ ] Windows PowerShell 5.1

  Windows PowerShell 5.1 must be installed on the server where the 'HelloID agent and provisioning agent' are running.

  > The connector is not compatible with older versions of Windows PowerShell or PowerShell Core.

## configuration settings
  
  The following settings are required to connect to the Api

 - Bart service URL
      Example: "https://<company abbreviation >.bartws.asp.local"
      The url to the bart service endpoint to connect to
  User name
      Example: bart.web.service@<company>.nl
         The user name of the account with wich the HelloID provisioning agent connects to bart to perform all operations. 
  Password
      Password of the above connection account
  Full path to KPN-Bart Powershell 
      Example: "D:\data\HelloID-Conn-Prov-Target-KPN-Bart\KPNBart\KPNBart.psd1"
      The full path to the module definition file  
  Default AD Domain
      Example: <Mydomain>.nl
      The default domain in which to create new bart accounts.

## contents
- Subdirectory kpnBart.
    This contains the Powershell module used by the other files.
- create.ps1
    Creates a new user in bart, inclusive attributes, passwords, persona, and email etc.
    It uses the UPN as target account identifier. When a user does already exist, it correlates the person with the account and, and updates the account.
- update.ps1:
    updates an existing account.
- enable.ps1:
    enables an existing account.
- disable.ps1: 
    disables an existing account.
- delete.ps1: 
    deletes an existing account.
- entitlementsGroups.ps1:
    collects a list of groups
    can be used for entitlements in a "retrieve permissions" script.
- entitlementsFunctionGroups:
    Collects a list of function groups.
    Can be user for entitlements in a "retrieve permissions" script.   
- grandPermissionsGroup:
    Grants a permission to a user for a resource
    can be used in a grand permission script, for any type of resource.  
- revokePermissionsGroup: 
    Revokes a permission from a user for a resource
    can be user in a revoke permissing script, for any type of resource.

## Remarks

- The create process constist of 3 phases
  1) creation of a "base" account consting of the fields
    "FirstName,LastName,Initials,Password,UserPrincipalName,DisplayName,MiddleName, SamAccountName"
  2) The extention of the account with direct AD attributes
  3) special calls to update more complex properties (like mail addresses, password reset on next logon, etc).  
  When a user UPN is already used, the  base user is correlated, instead of created, but the enrichment of the account in phase 2 and 3 proceeds as normal. So the fields listed in phase 1 are not updated for existing users on a create.

 - When a user is created, but the supplied SamAccountName does violate a Bart naming convention, the create action will fail with an exception, but Bart may still create the base account, with an automatically generated SamAccountName. In such case, retrying the create in helloid will successfully create the account, but with the automated SamAccountName

 - The grant and revoke permissions scripts work for any type of resource. Therefore there are no different files for different types resources. The grant/revoke files for the groups can be used directly for other resources also.




