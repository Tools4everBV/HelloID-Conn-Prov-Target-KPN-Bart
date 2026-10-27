---
external help file: KPNBart-help.xml
Module Name: KPNBart
online version:
schema: 2.0.0
---

# Get-KPNBartEmailAlias

## SYNOPSIS
Retrieves the email address aliases

## SYNTAX

```
Get-KPNBartEmailAlias [[-Identity] <ObjectIdentity>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a list of email address aliases for the specified user

## EXAMPLES

### Example 1
```powershell
$identity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
$identity.IdentityType = 'Guid'
$identity.Value = '11111111-1111-1111-1111-111111111111'
Get-KPNBartEmailAlias -Identity $identity
```

Retrieves aliases for an account using a query-service identity object.

## PARAMETERS

### -Identity
The Identity of the user.
This is the Identity in Active Directory

```yaml
Type: KPNBartConnectedServices.QueryService.ObjectIdentity
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

The WSDL requires a query-service `ObjectIdentity`, not a plain string. Existing callers that supply a string must construct an identity object before calling this function.

## RELATED LINKS
