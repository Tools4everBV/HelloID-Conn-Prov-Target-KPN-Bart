---
external help file: KPNBart-help.xml
Module Name: KPNBart
online version:
schema: 2.0.0
---

# Get-BartUserByIdentityType

## SYNOPSIS
Retrieves a BART account by identity type and value.

## SYNTAX

```powershell
Get-BartUserByIdentityType -attribute <String> -value <String> [<CommonParameters>]
```

## DESCRIPTION
Builds a query-service `ObjectIdentity` and calls `Get-KPNBartUser` with the identity attribute and `objectGuid` as the requested fields. This helper supports the existing create script's `attribute` and `value` splat.

## EXAMPLES

```powershell
$splat = @{
    attribute = 'UserPrincipalName'
    value = 'test@example.invalid'
}
$account = Get-BartUserByIdentityType @splat
```

## PARAMETERS

### -attribute
Required identity type. Supported values: `DistinguishedName`, `Guid`, `SamAccountName`, `Sid`, `UserPrincipalName`, and `MailAddress`.

### -value
Required, nonempty identity value used to locate the account.

## OUTPUTS
Returns the result of `Get-KPNBartUser`. Returns `$false` when the exception message contains `Identity <value> could not be found.` Other failures produce a terminating error without the lookup value or the original service error text.

## NOTES
- Install `Get-BartUserByIdentityType.ps1` in the module's `public/userActions` directory. The module loader discovers and exports it automatically. This Markdown file is documentation only.
- Import the KPNBart module and initialize its query service before calling the helper. No additional module dependencies are required.
- Verbose messages do not include the identity value. The value is still sent to BART as required for the lookup.
- Account-not-found detection depends on the exact BART error message. A null or incomplete successful response is passed through; the helper does not validate `ObjectGUID`.
- Verify lookup behavior against the deployed BART service before production use. Local mock checks do not establish live-service compatibility.

## RELATED LINKS
[Get-KPNBartUser](Get-KPNBartUser.md)