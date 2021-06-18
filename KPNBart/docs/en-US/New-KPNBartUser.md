---
external help file: KPNBart-help.xml
Module Name: KPNBart
online version:
schema: 2.0.0
---

# New-KPNBartUser

## SYNOPSIS
Creates a new KPN Bart user

## SYNTAX

```
New-KPNBartUser [-FirstName] <String> [-LastName] <String> [-Password] <SecureString>
 [-UserPrincipalName] <String> [-DisplayName] <String> [-MiddleName] <String> [-SamAccountName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
Creates a new user in KPN Bart

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -FirstName
The FirstName for the user you want to create

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastName
The LastName for the user you want to create

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
The Password for the user you want to create

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserPrincipalName
The UserPrincipalName for the user you want to create.
This is the same as the UserPrincipalName in Active Directory

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
The DisplayName for the user you want to create.
This is the same as the DisplayName in Active Directory

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MiddleName
The MiddleName for the user you want to create

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SamAccountName
The SamAccountName for the user you want to create.
This is the same as the SamAccountName in Active Directory

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
