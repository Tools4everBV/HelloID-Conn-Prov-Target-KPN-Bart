
# HelloID-Conn-Prov-Target-KPN-BART

> [!IMPORTANT]
> This repository contains connector code and configuration only. Obtain the BART endpoint, service account, credentials, required permissions, and any supplier agreements before implementation. Coordinate these requirements with the client's application manager.

> [!IMPORTANT]
> Validate the SOAP service responses and lifecycle behavior in the target BART environment before production use. Dry-run results do not verify that BART accepts the requested changes.

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
      - [The create process consists of 2 phases](#the-create-process-consists-of-2-phases)
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
| permissions/functionGroups/grantPermission.ps1    | PowerShell _grant_ lifecycle action              |
| permissions/functionGroups/revokePermission.ps1   | PowerShell _revoke_ lifecycle action             |
| permissions/FunctionGroups/permissions.ps1        | PowerShell _permissions_ lifecycle action        |
| permissions/groups/importPermissions.ps1 | PowerShell _import_ permissions lifecycle action |
| permissions/FunctionGroups/importPermissions.ps1 | PowerShell _import_ permissions lifecycle action |
| import.ps1             | PowerShell _account import_ lifecycle action     |
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
    | Account correlation field | `EmployeeId`                      |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings

| Setting | Description | Example |
| --- | --- | --- |
| Bart service base URL (`baseUrl`) | BART SOAP service endpoint | `https://<company-abbreviation>.bartws.asp.local` |
| User name (`username`) | Service account used by the HelloID provisioning agent | `APP\Tools4eve_PE` |
| Password (`password`) | Password for the service account | Set in HelloID; do not store in this repository |
| Full path to KPN-Bart PowerShell module (`moduleLocation`) | Path to the module manifest on the agent server | `D:\data\HelloID-Conn-Prov-Target-KPN-Bart\KPNBart\KPNBart.psd1` |
| Default AD Domain (`defaultADDomain`) | Domain used for new BART accounts | `mydomain.local` |
| Default email address suffix (`emailAddressSuffix`) | Suffix used by email-related actions | `customer.nl` |

The service account name must use `DOMAIN\samaccountname` format. An authentication error mentioning `Negotiate` or `NTLM` usually indicates invalid credentials or an account that cannot authenticate to the BART service.

### Prerequisites

- [ ] KPN Bart PowerShell module

  Copy the complete `KPNBart` module folder to a location accessible by the HelloID agent. Configure the full path to `KPNBart.psd1` in `moduleLocation`. Unblock the module DLL after downloading it.

- [ ] Windows PowerShell 5.1

  Windows PowerShell 5.1 must be installed on the server where the HelloID agent and provisioning agent are running. The agent must be able to reach the BART endpoint and load the module under its own runtime identity.

  > The connector is not compatible with older versions of Windows PowerShell or PowerShell Core.

## Remarks
The create action first queries BART for the configured correlation value. No match creates a base account; one match correlates the existing account; multiple matches stop the action to avoid ambiguity. A valid `ObjectGUID` is required. If the create request succeeds but the follow-up lookup fails, BART may already contain the account; verify it in BART before retrying because the connector does not roll back remote changes.

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

### The create process consists of 2 phases

#### First phase
`create.ps1` creates the base account with `FirstName`, `LastName`, `Initials`, `Password`, `UserPrincipalName`, `DisplayName`, `MiddleName`, and `SamAccountName`. `UserPrincipalName` is required for the post-create lookup. Newly created accounts are disabled; the separate `enable.ps1` lifecycle action enables them when HelloID determines they should be active. A correlated existing account is not disabled by create.

#### Second phase
`update.ps1` enriches the account after create, including direct AD attributes, manager, persona or user type, mail, and other mapped values. `EmployeeId` is written in this phase and is the recommended BART account correlation field for `PersonContext.Person.ExternalId`. A base account left behind before this phase completes may therefore not yet be correlated by EmployeeId; find and complete or correct it in BART before retrying create.

Map only one of `ExtensionData.Persona` or `ExtensionData.UserType` when specifying the account type. If Persona is mapped, the UserType conversion is skipped. Persona names must match the name configured in BART. Verify the values in BART before enabling provisioning.

`Department` must already exist in BART. If a mapped department is unknown, the update action skips that attribute and writes an audit message; create the department in BART and run the update again.

Writes already accepted by BART are not rolled back if a later update action fails. Review the HelloID audit log and the BART account before retrying. The connector uses `AccountCreated` in the account reference to distinguish newly created accounts; verify that HelloID retains the returned account reference during implementation.

Account import returns BART accounts with `ObjectGUID` as the account reference. The enabled state is read from `userAccountControl`; if that attribute is unavailable, the import action falls back to `Get-KPNBartUserIsActive`. Confirm this fallback response against the BART service version in use.

Permission import is available for both Groups and FunctionGroups. It queries BART authorization for each resource, so the service account needs permission to read those resource memberships as well as perform account lifecycle actions.

> When a user UPN is already used, the account can be returned as an existing account by BART. The create action correlates by the configured correlation field; it does not update the base fields during create. Verify the actual duplicate-UPN behavior with the target BART service before production.

> If a supplied `SamAccountName` violates a BART naming convention, BART may create the base account with an automatically generated name even when the action reports an error. Check BART for a partially created account before retrying.

> Grant and revoke scripts are provided separately for Groups and FunctionGroups. Use the matching permission scripts and reference format when configuring each resource type.

### ExtensionData
> The field mapping contains multiple properties that start with _extensionData._. These properties are added to extensionData because they are not needed for comparison during the update process. Using _extensionData._ helps make the removal process during the update cleaner.

## Setup the connector

1. Install the complete `KPNBart` module on the HelloID agent server, unblock `KPNBart/bin/KPNBartConnectedServices.dll`, and configure `moduleLocation` to the `.psd1` file.
2. Configure the BART service URL and a service account in `DOMAIN\samaccountname` format. Confirm that the account can authenticate to the endpoint and has the required account, department, persona, and resource authorization permissions.
3. Import `fieldMapping.json` and review every mapping against the customer's BART setup. Configure correlation from `PersonContext.Person.ExternalId` to BART `EmployeeId`.
4. Configure the target system to execute on-premises. Run dry runs first, then validate create, update, enable/disable, delete, account import, and both permission imports with a non-production account and representative resources.
5. Confirm the create/update two-phase behavior, primary email handling, manager and persona lookups, and the active-state fallback with the actual BART service. Inspect the BART account and HelloID account reference after each test before enabling production enforcement.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

