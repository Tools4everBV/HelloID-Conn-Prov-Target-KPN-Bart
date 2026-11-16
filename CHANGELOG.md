# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [1.1.0] - 2026-10-04

### Added

- `import.ps1`: account import (V2). Returns `ObjectGUID` as account reference (`Id`, `AccountCreated = $false`), determines enabled state via `userAccountControl` with fallback to `Get-KPNBartUserIsActive`.
- `permissions/groups/importPermissions.ps1` and `permissions/FunctionGroups/importPermissions.ps1`: permission membership import for Groups and FunctionGroups, using `ResourceAuthorizationQuery` (Access) per resource. The permission reference matches `permissions.ps1`.
- `KPNBart/public/resourceActions/Get-KPNBartResourceAuthorization.ps1`: module function to retrieve users authorized for a resource (also inlined in the import scripts).
- `update.ps1`: optional debug logging (`$debugBartFields`) of BART attribute names/values and persona lookup.
- `update.ps1`: validation of `Department` against the BART department list; unknown departments are skipped with an audit message to create them in BART first.
- `update.ps1`: create-only fields `SamAccountName`, `UserPrincipalName` and `ExtensionData.Mail` are re-added to account data so they remain visible after an update.
- `uniquenessCheck.ps1`: uniqueness check for `SamAccountName`, `UserPrincipalName`, `CommonName` and `Mail` against the existing BART accounts.
- `KPNBart/public/userActions/Get-BartUserByIdentityType.ps1` (with documentation): helper used by `create.ps1` to retrieve an account by identity type and value.
- `update.ps1`: optional `ExtensionData.Werkplekprofiel`; when mapped, the desktop list of the account is set with `SetDesktopsCommand`. It is not part of the default `fieldMapping.json`.
- `fieldMapping.json`: `GivenName` and `SN` (Update), `Mail` (Create) and `Pager` (Create, Enable).
- `.github/workflows/createRelease.yaml` and `.github/workflows/verifyChangelog.yaml`: standard workflow callers.

### Changed

- `create.ps1`: newly created accounts are disabled directly after creation. Enabling is only done by `enable.ps1`. Correlated (existing) accounts keep their current state.
- `update.ps1`: persona is only set when the account does not have it yet. The persona name is matched against the BART persona list after trimming whitespace; BART persona names are case-sensitive.
- `enable.ps1`, `disable.ps1`, `delete.ps1`: validate `References.Account.Id`, log the account Id instead of the full reference object, skip enable/disable when the account already has the desired state, treat "not found" on disable/delete as success, set `Success` during dry run and report action-specific error messages including inner exceptions.
- `create.ps1`: stricter correlation. The action stops on an invalid correlation configuration, an unexpected or ambiguous response from BART, or an account without a valid `ObjectGUID`, and the account data that is returned excludes `Password` and `ExtensionData`.
- `update.ps1`: the manager reference is read from `References.ManagerAccount.Id` (a plain value is still accepted) and must be a valid GUID; `References.ManagerAccount` is no longer written to the output references.
- `fieldMapping.json`: reworked. `FirstName` and `LastName` are mapped for Create only; `UserPrincipalName`, `SamAccountName`, `Mail` and `ExtensionData.Mail` are Create-only and stored in the account data (`Update` mapping `None`); `ExtensionData.ExchangeWhenSettingMailAttribute` is Create-only; `DisplayName` and `EmployeeId` are stored in the account data; `MiddleName` uses a complex mapping. Review and re-import the mapping before upgrading an existing implementation.
- `permissions/FunctionGroups/grantPermission.ps1` and `permissions/FunctionGroups/revokePermission.ps1`: the resource id is read from `References.Permission.Reference.Reference` (validated as a GUID) and the account from `References.Account.Id`; the account lookup and the "not found" branch were removed.
- `KPNBart/public/emailActions/Get-KPNBartEmailAlias.ps1`: **breaking for callers of this module function** - `-Identity` is now a query-service `ObjectIdentity` instead of a string. The connector scripts do not call this function.

### Fixed

- `update.ps1`: attribute updates used the wrong type (`CommandService.ObjectIdentity`) instead of `BulkCommandService.ModifyADAttributeCommand`, causing all attribute updates (e.g. `EmployeeId`) to fail.
- `update.ps1`: error messages within actions were empty because an undefined variable was used.
- `create.ps1`: the correlation filter compared with an undefined variable (`$attribute`), so correlation never matched, and the script called `Get-BartUserByIdentityType`, which did not exist in the module.
- `KPNBart/public/userActions/New-KPNBartUser.ps1`: `DisplayName` was not sent to BART.

### Removed

- `update.ps1`: non-functional `DisableAccount` trigger; account state is managed by `create.ps1`, `enable.ps1` and `disable.ps1`.
- Temporary `# TEMP code` warnings in `enable.ps1`, `disable.ps1` and `delete.ps1`.
- `permissions/groups/subPermission copy.ps1` and `permissions/FunctionGroups/subPermission copy.ps1`: leftover copies.
- `fieldMapping.json`: `ExtensionData.UserType` and `ExtensionAttribute2`.

## [1.0.0] - 24-04-2024

This is the first official release of _HelloID-Conn-Prov-Target-KPN-BART_. This release is based on template version _1.2.0_.

### Added

### Changed

### Deprecated

### Removed