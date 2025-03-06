
# HelloID-Conn-Prov-Target-KPN-BART

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

> [!IMPORTANT]
> This connector is updated to a powershell v2 connector without a test environment, therefore the code is not tested and should be treated as such.

> All scripts
- Error response and how we handle that in the scripts.
- Function responses from the API and how they are received and processed during various actions in the connector.

> Update script
- Check if the compare of all the properties works properly. (the compare of the flat object and the separate compare of the manager, persona etc.)

> Delete script
- Check if the _Get-KPNBartUserIsActive_ function returns an object or a boolean. If it contains a boolean the code should be changed accordingly.

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-KPN-BART](#helloid-conn-prov-target-KPN-BART)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
    - [Functionality](#Functionality)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
      - [PSModule](#ps-module)
        - [Available functions](#available-functions)
        - [Module help](#module-help)
      - [DLL](#dll)
      - [The create process constist of 3 phases](#the-create-process-constist-of-3-phases)
      - [ExtensionData](#extensionData)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

The *HID-Conn-Prov-Target-KPN-Bart* needs to be **executed on-premises**. Make sure you have **Windows PowerShell 5.1** installed on the server where the **HelloID agent and provisioning** agent are running, and that the *Execute on-premises* switch is toggled on the connector system tab within HelloID.

### Functionality
- creates, modifies, enables, disables, and deletes accounts in bart
- updates account attributes, user passwords, primary email and aliases.
- set user types or persona types when creating or modifing accounts
- grant/revoke memberschip of groups and functiongroups.


The following lifecycle actions are available:

| Action                 | Description                                      |
| ---------------------- | ------------------------------------------------ |
| create.ps1             | PowerShell _create_ lifecycle action             |
| delete.ps1             | PowerShell _delete_ lifecycle action             |
| disable.ps1            | PowerShell _disable_ lifecycle action            |
| enable.ps1             | PowerShell _enable_ lifecycle action             |
| update.ps1             | PowerShell _update_ lifecycle action             |
| permissions/groups/grantPermission.ps1    | PowerShell _grant_ lifecycle action              |
| permissions/groups/revokePermission.ps1   | PowerShell _revoke_ lifecycle action             |
| permissions/groups/permissions.ps1        | PowerShell _permissions_ lifecycle action        |
| permissions/groups/dynamicPermissions.ps1        | PowerShell _AllInOne_ lifecycle action        |
| permissions/functionGroups/grantPermission.ps1    | PowerShell _grant_ lifecycle action              |
| permissions/functionGroups/revokePermission.ps1   | PowerShell _revoke_ lifecycle action             |
| permissions/groups/permissions.ps1        | PowerShell _permissions_ lifecycle action        |
| permissions/groups/dynamicPermissions.ps1        | PowerShell _AllInOne_ lifecycle action        |
| configuration.json     | Default _configuration.json_ |
| fieldMapping.json      | Default _fieldMapping.json_   |

## Getting started

### Provisioning PowerShell V2 connector

#### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _KPN-BART_ to a person in _HelloID_.

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

    | Setting                   | Value                             |
    | ------------------------- | --------------------------------- |
    | Enable correlation        | `True`                            |
    | Person correlation field  | `PersonContext.Person.ExternalId` |
    | Account correlation field | ``                                |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings

| Setting                         | Description                                                  | Example                                                      |
| ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Bart service URL                | Example:The url to the bart service endpoint to connect to   | https://<companyabbreviation>.bartws.local                   |
| Username                        | The user name of the account with wich the HelloID provisioning agent connects to bart to perform all operations. | APP\Tools4eve_PE   (See remark)                          |
| Password                        | Password of the above connection account                     |                                                              |
| Full path to KPN-Bart Powershel | The full path to the module *.psd1 file                      | D:\data\HelloID-Conn-Prov-Target-KPN-Bart\KPNBart\KPNBart.psd1 |
| Default AD Domain               | The default domain in which to create new bart accounts.     | Mydomain.local                                             |

Remark: The username should be in the DOMAIN\samaccountname format. (For example: APP\Tools4eve_PE). If the password is incorrect, you will recieve the error message:  ""The HTTP request is unauthorized with client authentication scheme 'Negotiate'. The authentication header received from the server was 'Negotiate,NTLM'.""

### Prerequisites

- [ ] KPN Bart PowerShell module

  The KPN Bart PowerShell module must be installed locally. The module can be downloaded directly from the Github repository. Make sure you unblock the DLL in Windows.

- [ ] Windows PowerShell 5.1

  Windows PowerShell 5.1 must be installed on the server where the 'HelloID agent and provisioning agent' are running.

  > The connector is not compatible with older versions of Windows PowerShell or PowerShell Core.

## Remarks
> In the create.ps1 there are two get calls to retrieve the correct user. The first one is to collect all the users and then check if there are one or multiple users found where the correlation value matches. If there are multiple found the script returns an error. If there is only one user found whe will execute the second get call to retrieve only the correct user with the necessary attributes.

### PSModule

The connector uses a PowerShell module that must be installed locally. Make sure the entire 'KPNBart' folder, that contains the module, is copied to a directory accessible by the helloid agent.

In the configuration parameters of the target system in HelloId, you must specify the full path to the module definition file (KPNBart.psd1), so the HelloId agent can load the module.

#### Available functions

To get a list of all available functions within the module: 'Get-Command -Module KPNBart'.

#### Module help

All functions in the PSKPNBart module have comment based help. To get help for a specific function: 'Get-Help -Command New-KpNBartUser'.

### DLL

The KPN Bart PSModule uses an additional *.DLL (KPNbart/bin/KPNBartConnectedServices.dll) that includes the WSDL. Reason for this is that certain methods (to connect to KPN Bart using specific HTTP bindings) were not available when the WSDL's were loaded directly into PowerShell using the: <New-WebServiceProxy> cmdlet. The C# connector uses these HTTP bindings. Since this is a copy of the C# connector, those bindings are copied.

*Note* make sure to check that this file is not "blocked" by windows when copying from the internet and "unblock" this file in windows if this is the case.

The easiest way to do this is by using PowerShell from the directory in which the files are downloaded.

```powershell
  Get-ChildItem | Unblock-File
```

### The create process consist of 2 phases

#### First phase
> The first fase happens in the create.ps1 file where the "base" account is created with the following fields: FirstName,LastName,Initials,Password,UserPrincipalName,DisplayName,MiddleName, SamAccountName

#### Second phase
> the second phase happens in the update.ps1 file after the first create lifecycle executes successfully. In this phase the account will be extended with direct AD attributes and more complex properties like mail addresses, password reset on next logon, etc.

> When a user UPN is already used, the base user is correlated, instead of created, the enrichment of the account in phase 2 proceeds as normal. So the fields listed in phase 1 are not updated for existing users on a create.

> When a user is created, but the supplied SamAccountName does violate a Bart naming convention, the create action will fail with an exception, but Bart may still create the base account, with an automatically generated SamAccountName. In such case, retrying the create in HelloId will successfully create the account, but with the automated SamAccountName

> The grant and revoke permissions scripts work for any type of resource. Therefore there are no different files for different types resources. The grant/revoke files for the groups can be used directly for other resources also.

### ExtensionData
> The field mapping contains multiple properties that start with _extensionData._. These properties are added to extensionData because they are not needed for comparison during the update process. Using _extensionData._ helps make the removal process during the update cleaner.

## Setup the connector

> _How to setup the connector in HelloID._ Are special settings required. Like the _primary manager_ settings for a source connector.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

