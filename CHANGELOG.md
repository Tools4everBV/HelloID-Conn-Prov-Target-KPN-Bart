# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [1.1.0] - 04-10-2026

### Added

- `import.ps1`: account import (V2). Returns `ObjectGUID` as account reference (`Id`, `AccountCreated = $false`), determines enabled state via `userAccountControl` with fallback to `Get-KPNBartUserIsActive`.
- `permissions/groups/importPermissions.ps1` and `permissions/FunctionGroups/importPermissions.ps1`: permission membership import for Groups and FunctionGroups, using `ResourceAuthorizationQuery` (Access) per resource. The permission reference matches `permissions.ps1`.
- `KPNBart/public/resourceActions/Get-KPNBartResourceAuthorization.ps1`: module function to retrieve users authorized for a resource (also inlined in the import scripts).
- `update.ps1`: optional debug logging (`$debugBartFields`) of BART attribute names/values and persona lookup.
- `update.ps1`: validation of `Department` against the BART department list; unknown departments are skipped with an audit message to create them in BART first.
- `update.ps1`: create-only fields `SamAccountName`, `UserPrincipalName` and `ExtensionData.Mail` are re-added to account data so they remain visible after an update.

### Changed

- `create.ps1`: newly created accounts are disabled directly after creation. Enabling is only done by `enable.ps1`. Correlated (existing) accounts keep their current state.
- `update.ps1`: persona is only set when the account does not have it yet. The persona name is matched against the BART persona list after trimming whitespace; BART persona names are case-sensitive.
- `enable.ps1`, `disable.ps1`, `delete.ps1`: validate `References.Account.Id`, log the account Id instead of the full reference object, skip enable/disable when the account already has the desired state, treat "not found" on disable/delete as success, set `Success` during dry run and report action-specific error messages including inner exceptions.

### Fixed

- `update.ps1`: attribute updates used the wrong type (`CommandService.ObjectIdentity`) instead of `BulkCommandService.ModifyADAttributeCommand`, causing all attribute updates (e.g. `EmployeeId`) to fail.
- `update.ps1`: error messages within actions were empty because an undefined variable was used.

### Removed

- `update.ps1`: non-functional `DisableAccount` trigger; account state is managed by `create.ps1`, `enable.ps1` and `disable.ps1`.
- Temporary `# TEMP code` warnings in `enable.ps1`, `disable.ps1` and `delete.ps1`.

## [1.0.0] - 24-04-2024

This is the first official release of _HelloID-Conn-Prov-Target-KPN-BART_. This release is based on template version _1.2.0_.

### Added

### Changed

### Deprecated

### Removed